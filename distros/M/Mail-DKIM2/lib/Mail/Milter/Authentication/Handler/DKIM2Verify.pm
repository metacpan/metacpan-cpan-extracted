package Mail::Milter::Authentication::Handler::DKIM2Verify;
use 5.20.0;
use strict;
use warnings;
use Mail::Milter::Authentication::Pragmas;
# ABSTRACT: Handler class for DKIM2 signature verification
our $VERSION = '0.18';
use base 'Mail::Milter::Authentication::Handler';

use Mail::DKIM2::Common qw(extract_mi_version parse_dkim_pubkey fold_header parse_mime);
use Mail::DKIM2::Verifier;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::MessageStore;
use Email::MIME;

sub default_config {
    return {
        'hide_none'            => 0,
        'extra_properties'     => 0,
        'dns_overrides'        => undef,  # path to dns.json for testing
        'add_message_instance' => 1,      # compute and add MI header on inbound
        'snapshot_directory'   => undef,  # store message snapshots for egress diffing
        'ignore_header_prefixes' => [],   # our own fields, hashed by neither end (IgnorePrefixes)
    };
}

# The handler's configuration with default_config() filled in for every
# option left out (or undef); an explicit 0 still wins. The framework does
# not merge default_config() at runtime -- it only uses it to generate a
# sample config -- so without this add_message_instance, documented as on
# by default, was off unless set.
sub _config {
    my ($self) = @_;
    my $given    = $self->handler_config() || {};
    my $defaults = default_config();
    return { %$given, map { $_ => $given->{$_} // $defaults->{$_} } keys %$defaults };
}

sub register_metrics {
    return {
        'dkim2_verify_total' => 'The number of emails processed for DKIM2 verification',
    };
}

sub envfrom_callback {
    my ( $self, $env_from ) = @_;
    $self->{'failmode'}    = 0;
    $self->{'headers'}     = [];
    $self->{'body'}        = [];
    $self->{'has_dkim2'}   = 0;
    $self->{'carry'}       = q{};
    $self->{'env_from'}    = $env_from;
    $self->destroy_object('dkim2_verifier');
}

sub header_callback {
    my ( $self, $header, $value, $original ) = @_;
    return if $self->{'failmode'};
    my $EOL = "\015\012";
    my $chunk = $original . $EOL;
    $chunk =~ s/\015?\012/$EOL/g;
    push @{$self->{'headers'}}, $chunk;

    if ( lc($header) eq 'dkim2-signature' ) {
        $self->{'has_dkim2'} = 1;
    }
}

sub eoh_callback {
    my ($self) = @_;
    return if $self->{'failmode'};
    my $config = $self->_config();

    unless ( $self->{'has_dkim2'} ) {
        $self->metric_count( 'dkim2_verify_total', { 'result' => 'none' } );
        $self->dbgout( 'DKIM2Result', 'No DKIM2-Signature headers', LOG_DEBUG );
        unless ( $config->{'hide_none'} ) {
            my $header = Mail::AuthenticationResults::Header::Entry->new()->set_key( 'dkim2' )->safe_set_value( 'none' );
            $header->add_child( Mail::AuthenticationResults::Header::Comment->new()->safe_set_value( 'no signatures found' ) );
            $self->add_auth_header( $header );
        }
        delete $self->{'headers'};
        return;
    }

    my $verifier;
    eval {
        $verifier = Mail::DKIM2::Verifier->new(
            IgnorePrefixes => $self->_config()->{'ignore_header_prefixes'},
        );
        $self->_setup_pubkey_callback($verifier);
        $self->set_object('dkim2_verifier', $verifier, 1);
    };
    if ( my $error = $@ ) {
        $self->handle_exception( $error );
        $self->log_error( 'DKIM2 Setup Error ' . $error );
        $self->{'failmode'} = 1;
        $self->_check_error( $error );
        $self->metric_count( 'dkim2_verify_total', { 'result' => 'error' } );
        delete $self->{'headers'};
        return;
    }

    eval {
        $verifier->PRINT( join q{},
            @{ $self->{'headers'} },
            "\015\012",
        );
    };
    if ( my $error = $@ ) {
        $self->handle_exception( $error );
        $self->log_error( 'DKIM2 Headers Error ' . $error );
        $self->{'failmode'} = 1;
        $self->_check_error( $error );
        $self->metric_count( 'dkim2_verify_total', { 'result' => 'error' } );
    }

    $self->{'carry'} = q{};
}

sub body_callback {
    my ( $self, $body_chunk ) = @_;
    return if $self->{'failmode'};
    return unless $self->{'has_dkim2'};
    # The verifier may already have its result from the headers.
    my $verifier = $self->get_object('dkim2_verifier');
    return if $verifier->stopped;
    my $EOL = "\015\012";

    my $chunk;
    if ( $self->{'carry'} ne q{} ) {
        $chunk = $self->{'carry'} . $body_chunk;
        $self->{'carry'} = q{};
    }
    else {
        $chunk = $body_chunk;
    }

    if ( substr( $chunk, -1 ) eq "\015" ) {
        $self->{'carry'} = "\015";
        $chunk = substr( $chunk, 0, -1 );
    }

    $chunk =~ s/\015?\012/$EOL/g;

    push @{$self->{'body'}}, $chunk;

    eval {
        $verifier->PRINT( $chunk );
    };
    if ( my $error = $@ ) {
        $self->handle_exception( $error );
        $self->log_error( 'DKIM2 Body Error ' . $error );
        $self->{'failmode'} = 1;
        $self->_check_error( $error );
        $self->metric_count( 'dkim2_verify_total', { 'result' => 'error' } );
    }
}

sub eom_callback {
    my ($self) = @_;

    return unless $self->{'has_dkim2'};
    return if $self->{'failmode'};

    my $config = $self->_config();
    my $verifier = $self->get_object('dkim2_verifier');

    eval {
        $verifier->PRINT( $self->{'carry'} );
        $verifier->CLOSE();
        $self->check_timeout();

        my $result = $verifier->result;
        my $detail = $verifier->result_detail;

        $self->metric_count( 'dkim2_verify_total', { 'result' => $result } );
        $self->dbgout( 'DKIM2Result', $detail, LOG_DEBUG );

        my $header = Mail::AuthenticationResults::Header::Entry->new()->set_key( 'dkim2' )->safe_set_value( $result );
        if ( my $details = $verifier->details ) {
            $header->add_child( Mail::AuthenticationResults::Header::Comment->new()->safe_set_value( $details ) );
        }

        # Add domain info from the highest-i signature
        if ( my $sig = $verifier->top_signature ) {
            $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'header.d' )->safe_set_value( $sig->domain || '' ) );
            $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'header.i' )->safe_set_value( $sig->sequence ) );
        }

        $self->add_auth_header( $header );

        # Compute and add Message-Instance header, then store snapshot
        if ( $result eq 'pass' && $config->{'add_message_instance'} ) {
            $self->_add_mi_and_store();
        }
    };
    if ( my $error = $@ ) {
        $self->handle_exception( $error );
        $self->log_error( 'DKIM2 EOM Error ' . $error );
        $self->{'failmode'} = 1;
        $self->_check_error( $error );
        $self->metric_count( 'dkim2_verify_total', { 'result' => 'error' } );
    }
}

sub _add_mi_and_store {
    my ($self) = @_;
    my $config = $self->_config();

    eval {
        my $EOL = "\015\012";
        my $message_data = join(q{}, @{$self->{'headers'}})
                         . $EOL
                         . join(q{}, @{$self->{'body'}});

        my $msg = parse_mime($message_data);
        my @mi_headers = $msg->header_raw('Message-Instance');
        my $mi_value;
        my $snapshot;

        if ( @mi_headers ) {
            # Case 2: Message has existing MI header(s).
            # The topmost MI must match current content (already verified
            # by the DKIM2 chain check).  Use it as the snapshot key.
            # Only the snapshot needs it: with no snapshot_directory there
            # is nothing to store, so skip the verify entirely.
            return unless $config->{'snapshot_directory'};
            my $mi_ver = Mail::DKIM2::MessageInstance->verify($msg,
                IgnorePrefixes => $config->{'ignore_header_prefixes'});
            unless ( $mi_ver ) {
                # This shouldn't happen after successful DKIM2 verification
                $self->log_error( 'DKIM2MI: MI headers present but none match current content' );
                return;
            }
            my %mi_by_v = map { (extract_mi_version($_) || 0) => $_ } @mi_headers;
            $mi_value = $mi_by_v{$mi_ver};
            $snapshot = $message_data;
            $self->dbgout( 'DKIM2MI', "Existing MI m=$mi_ver matches, using as snapshot key", LOG_DEBUG );
        }
        else {
            # Case 1: No MI headers — first entry into DKIM2 ecosystem.
            # Compute MI m=1 and prepend it.
            my $mi = Mail::DKIM2::MessageInstance->calculate($msg, undef,
                IgnorePrefixes => $config->{'ignore_header_prefixes'});
            $mi_value = $self->_format_mi($mi);
            $self->prepend_header( 'Message-Instance', $mi_value );
            $snapshot = "Message-Instance: $mi_value$EOL" . $message_data;
            $self->dbgout( 'DKIM2MI', "Added Message-Instance m=" . ($mi->get_tag('m') || '?'), LOG_DEBUG );
        }

        # Store snapshot keyed by the MI value so the outbound signer can
        # compute diff Recipes if the message is modified during local processing
        if ( $config->{'snapshot_directory'} && $mi_value ) {
            my $store = Mail::DKIM2::MessageStore->new(
                directory => $config->{'snapshot_directory'},
            );
            $store->store($mi_value, $snapshot);
            $self->dbgout( 'DKIM2Snapshot', "Stored snapshot", LOG_DEBUG );
        }
    };
    if ( my $error = $@ ) {
        $self->handle_exception( $error );
        $self->log_error( 'DKIM2 MI/Snapshot Error ' . $error );
    }
}

# Format MI header value with folding for insertion into message
sub _format_mi {
    my ( $self, $mi ) = @_;
    my $folded = fold_header("Message-Instance: " . $mi->as_string());
    $folded =~ s/^Message-Instance: //;
    return $folded;
}

sub close_callback {
    my ( $self ) = @_;
    delete $self->{'failmode'};
    delete $self->{'headers'};
    delete $self->{'body'};
    delete $self->{'carry'};
    delete $self->{'has_dkim2'};
    delete $self->{'env_from'};
    $self->destroy_object('dkim2_verifier');
}

sub _setup_pubkey_callback {
    my ( $self, $verifier ) = @_;
    my $config = $self->_config();

    # If dns_overrides is set (testing), load keys from that JSON file
    if ( $config->{'dns_overrides'} ) {
        my $dns_data = JSON::decode_json( File::Slurp::read_file($config->{'dns_overrides'}) );
        $verifier->set_pubkey_callback(sub {
            my ($signature, $idx) = @_;
            $idx //= 0;
            my $sel = $signature->selector($idx);
            my $dom = $signature->domain;
            my $key_txt = $dns_data->{$dom}{"$sel._domainkey"}[0][1];
            return parse_dkim_pubkey($key_txt);
        });
    }
    else {
        # Real DNS through the milter's own resolver (so its timeouts and
        # caching apply). The library classifies the answer: no record is
        # permerror, anything transient is temperror.
        $verifier->resolver( $self->get_object('resolver') );
    }
}

sub _check_error {
    my ( $self, $error ) = @_;
    if ( $error =~ /^DNS error: query timed out/
            or $error =~ /^DNS query timeout/
    ){
        $self->log_error( 'Temp DKIM2 Error - ' . $error );
        my $header = Mail::AuthenticationResults::Header::Entry->new()->set_key( 'dkim2' )->safe_set_value( 'temperror' );
        $header->add_child( Mail::AuthenticationResults::Header::Comment->new()->safe_set_value( 'dns timeout' ) );
        $self->add_auth_header( $header );
    }
    elsif ( $error =~ /^DNS error: SERVFAIL/ ){
        $self->log_error( 'Temp DKIM2 Error - ' . $error );
        my $header = Mail::AuthenticationResults::Header::Entry->new()->set_key( 'dkim2' )->safe_set_value( 'temperror' );
        $header->add_child( Mail::AuthenticationResults::Header::Comment->new()->safe_set_value( 'dns servfail' ) );
        $self->add_auth_header( $header );
    }
    else {
        $self->log_error( 'DKIM2 Error - ' . $error );
        my $header = Mail::AuthenticationResults::Header::Entry->new()->set_key( 'dkim2' )->safe_set_value( 'temperror' );
        $self->add_auth_header( $header );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::Milter::Authentication::Handler::DKIM2Verify - Handler class for DKIM2 signature verification

=head1 DESCRIPTION

Verifies DKIM2 signatures and Chain of Custody on inbound email, adding
Authentication-Results headers with the verification outcome.

This module implements draft-ietf-dkim-dkim2-spec-06; see L<Mail::DKIM2/STATUS>
for what that means for the wire format and the API, and
L<Mail::DKIM2/CONVENTIONS> for the option, input and error conventions every
module here follows.

=head1 CONFIGURATION

    "DKIM2Verify" : {
        "hide_none"            : 0,      | Hide auth line if result is 'none'
        "extra_properties"     : 0,      | Add extra properties to auth results
        "dns_overrides"        : null,   | Path to dns.json for testing
        "add_message_instance" : 1,      | Compute and add MI header on inbound
        "snapshot_directory"   : null     | Store message snapshots for egress diffing
    }

When C<add_message_instance> is enabled, the handler computes a Message-Instance
header after successful DKIM2 verification and prepends it to the message.

When C<snapshot_directory> is also set, the full message (with the new MI header)
is stored to disk.  The DKIM2Sign handler can later retrieve this snapshot to
compute a diff-based MI when the message leaves the system, capturing any
modifications made during local processing.

=head1 CALLBACKS

=head2 default_config()

Returns the default configuration hash for this handler. The handler
applies these itself to any option the configuration leaves out (the
authentication_milter framework does not), so C<add_message_instance> is
on unless set to 0.

=head2 register_metrics()

Returns the metrics hash for this handler (C<dkim2_verify_total>).

=head2 envfrom_callback($env_from)

Resets per-message state and records the envelope sender.

=head2 header_callback($header, $value, $original)

Collects each header line and notes whether any DKIM2-Signature headers
are present.

=head2 eoh_callback()

Called at end of headers.  If DKIM2-Signature headers were seen, creates a
L<Mail::DKIM2::Verifier>, sets up the public key callback, and feeds the
collected headers.  If no signatures were found, adds a C<dkim2=none>
Authentication-Results header.

=head2 body_callback($body_chunk)

Feeds body data to the verifier, normalizing line endings to CRLF.

=head2 eom_callback()

Finalizes verification.  Calls C<CLOSE()> on the verifier, adds an
Authentication-Results header with the outcome, and (if verification passed
and configured) computes a Message-Instance header and stores a message
snapshot.

=head2 close_callback()

Cleans up per-message state and destroys the verifier object.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
