package Mail::Milter::Authentication::Handler::DKIM2Sign;
use 5.20.0;
use strict;
use warnings;
use Mail::Milter::Authentication::Pragmas;
# ABSTRACT: Handler class for DKIM2 signing
our $VERSION = '0.17';
use base 'Mail::Milter::Authentication::Handler';

use Mail::DKIM2::Common qw(extract_mi_version strip_mi_versions load_private_key fold_header parse_mime
    parse_dkim_pubkey chain_number_error mi_version_tag DKIM2_DRAFT DKIM2_REPO DKIM2_DATE);
use Mail::DKIM2::Gate;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::MessageStore;
use Mail::DKIM2::Signer;
use Email::MIME;
use MIME::Base64 qw(decode_base64);
use constant DKIM2_SOFTWARE => 'authentication_milter-DKIM2Sign';

sub default_config {
    return {
        # Static domain config: domain => { selector, keyfile }
        'domains'              => {},
        # HTTP endpoint for dynamic key lookup: GET {url}?domain=X
        # Expected response: {"selector":"sel1","key":"base64_pem_data"}
        # or: {"selector":"sel1","keyfile":"/path/to/key.pem"}
        'key_endpoint'         => undef,
        'key_endpoint_timeout' => 5,
        # Only sign for authenticated/local senders
        'sign_authenticated'   => 1,
        'sign_local'           => 1,
        # Add Message-Instance headers
        'add_message_instance' => 1,
        # SMTP params to record in the signature
        'record_smtp_params'   => 1,
        # Directory for message snapshots (shared with DKIM2Verify)
        'snapshot_directory'   => undef,
        'ignore_header_prefixes' => [],   # our own fields, hashed by neither end (IgnorePrefixes)
        # Sign over an UNSIGNED Message-Instance (above every upstream
        # signature's m=) with a null body Recipe; see Mail::DKIM2::Gate
        'allow_null_body_recipe' => 0,
        # Testing only: verify the upstream chain with keys from this dns.json
        # instead of DNS, and without the t=/expiry check
        'dns_overrides'        => undef,
        'skip_timestamp_check' => 0,
    };
}

# The handler's configuration with default_config() filled in for every
# option the operator left out (or set to null). authentication_milter does
# not merge default_config() at runtime -- it only uses it to generate a
# sample config -- so without this a left-out option is undef: sign_local,
# sign_authenticated, add_message_instance and record_smtp_params would all
# silently be off.
sub _config {
    my ($self) = @_;
    my $given    = $self->handler_config() || {};
    my $defaults = default_config();
    return { %$given, map { $_ => $given->{$_} // $defaults->{$_} } keys %$defaults };
}

sub register_metrics {
    return {
        'dkim2_sign_total' => 'The number of emails signed with DKIM2',
    };
}

sub envfrom_callback {
    my ( $self, $env_from ) = @_;
    $self->{'failmode'}   = 0;
    $self->{'headers'}    = [];
    $self->{'body'}       = [];
    $self->{'carry'}      = q{};
    $self->{'env_from'}   = $env_from;
    $self->{'env_rcpt'}   = [];
    $self->{'sign_domain'} = undef;
}

sub envrcpt_callback {
    my ( $self, $env_to ) = @_;
    push @{$self->{'env_rcpt'}}, $env_to;
}

sub header_callback {
    my ( $self, $header, $value, $original ) = @_;
    return if $self->{'failmode'};
    my $EOL = "\015\012";
    my $chunk = $original . $EOL;
    $chunk =~ s/\015?\012/$EOL/g;
    push @{$self->{'headers'}}, $chunk;
}

sub eoh_callback {
    my ($self) = @_;
    $self->{'carry'} = q{};
}

sub body_callback {
    my ( $self, $body_chunk ) = @_;
    return if $self->{'failmode'};
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
}

sub eom_callback {
    my ($self) = @_;
    push @{$self->{'body'}}, $self->{'carry'} if $self->{'carry'};
    # Signing happens in addheader_callback
}

sub _fmtheader {
    my $header = shift;
    my $value = $header->{value};
    $value =~ s/\015?\012/\015\012/gs;
    return "$header->{field}: $value\015\012";
}

sub addheader_callback {
    my $self = shift;
    my $handler = shift;
    return if $self->{'failmode'};

    my $config = $self->_config();

    # Determine if we should sign this message
    my $should_sign = 0;
    if ( $config->{'sign_authenticated'} && $self->is_authenticated() ) {
        $should_sign = 1;
    }
    if ( $config->{'sign_local'} && $self->is_local_ip_address() ) {
        $should_sign = 1;
    }
    return unless $should_sign;

    # Determine the signing domain from the envelope sender.
    my $env_from = $self->{'env_from'} || '';
    $env_from =~ s/^<//;
    $env_from =~ s/>$//;
    my $sign_domain;
    if ( $env_from =~ /\@(.+)$/ ) {
        $sign_domain = lc $1;
    }
    # Null sender (MAIL FROM <>) — e.g. a Postfix-generated bounce/DSN. There is
    # no envelope domain to sign for, so fall back to the From: header domain
    # (typically MAILER-DAEMON@<host>). We only sign if it resolves to a key,
    # i.e. it is genuinely one of our own bounces.
    if ( !$sign_domain && $env_from eq '' ) {
        $sign_domain = $self->_from_header_domain();
    }
    return unless $sign_domain;

    # Look up signing config for this domain
    my $sign_config = $self->_get_sign_config($sign_domain);
    unless ($sign_config) {
        $self->dbgout( 'DKIM2Sign', "No signing config for $sign_domain", LOG_DEBUG );
        return;
    }

    eval {
        my $selector = $sign_config->{selector};
        my $key;
        if ( $sign_config->{key} ) {
            # Inline PEM key data (may be base64-encoded)
            my $pem = $sign_config->{key};
            $pem = decode_base64($pem) unless $pem =~ /^-----/;
            require Crypt::PK::RSA;
            $key = Crypt::PK::RSA->new(\$pem);
        }
        elsif ( $sign_config->{keyfile} ) {
            $key = load_private_key($sign_config->{keyfile});
        }
        else {
            die "No key or keyfile in signing config for $sign_domain";
        }

        # Build the full message (pre_headers + original headers + add_headers + body)
        my $EOL = "\015\012";
        my $message_data = '';

        # pre_headers from handler (reversed as they prepend in reverse)
        foreach my $h (reverse @{$handler->{pre_headers} || []}) {
            $message_data .= _fmtheader($h);
        }

        # Original headers
        foreach my $chunk (@{$self->{'headers'} || []}) {
            $message_data .= $chunk;
        }

        # post-headers from handler
        foreach my $h (@{$handler->{add_headers} || []}) {
            $message_data .= _fmtheader($h);
        }

        # End of headers + body
        $message_data .= $EOL;
        foreach my $chunk (@{$self->{'body'}}) {
            $message_data .= $chunk;
        }

        # Compute Message-Instance if configured.  Nothing reaches the wire
        # until the gate below has passed and the signer has signed: a
        # refused message goes out as it came in (apart from X-DKIM2-Info),
        # as with bin/dkim2-milter.
        my @mi_removals;
        my $mi_value;
        if ( $config->{'add_message_instance'} ) {
            delete $self->{'_stripped_mi_versions'};
            delete $self->{'_clean_message_data'};
            my $mi = $self->_compute_message_instance($message_data, $config);
            if ( $self->{'_stripped_mi_versions'} ) {
                # Broken intermediate MIs were stripped; use the cleaned message data
                $message_data = $self->{'_clean_message_data'} // $message_data;
                # Record the stripped versions so the wire message can be
                # cleaned up once we have signed
                @mi_removals = @{$self->{'_stripped_mi_versions'}};
                delete $self->{'_stripped_mi_versions'};
                delete $self->{'_clean_message_data'};
            }
            if ($mi) {
                $mi_value = $self->_format_mi($mi);
                # Prepend MI header (will be included when we re-feed the signer)
                $message_data = "Message-Instance: $mi_value$EOL" . $message_data;
            }
        }

        # Build SMTP params
        my %signer_args = (
            Domain   => $sign_domain,
            Selector => $selector,
            Key      => $key,
        );

        # Pin t= when configured.  Only the test suite sets this, so that the
        # fixtures it writes to tests/expected/ are byte-reproducible instead
        # of changing on every run; in production it is absent and the signer
        # uses the current time.
        if ( $config->{'signature_timestamp'} ) {
            $signer_args{Timestamp} = $config->{'signature_timestamp'};
        }

        if ( $config->{'record_smtp_params'} ) {
            $signer_args{MailFrom} = ( $env_from ne '' ) ? $env_from : '<>';
            if ( @{$self->{'env_rcpt'} || []} ) {
                my @cleaned = map { my $r = $_; $r =~ s/^<//; $r =~ s/>$//; $r } @{$self->{'env_rcpt'}};
                $signer_args{RcptTo} = \@cleaned;
            }
        }

        # The signing decision, shared with bin/dkim2-milter and bin/dkim2sign
        # (Mail::DKIM2::Gate), made on the message exactly as we would sign it
        # (so including our own new Message-Instance, if any): the upstream
        # DKIM2-Signatures must verify (an unsigned Message-Instance above the
        # top signature -- ours, or a list manager's on this host -- is
        # allowed); the Message-Instance chain must match the content and undo
        # cleanly (an upstream that emitted a non-reversible Recipe would give
        # a signature that fails at every recipient); a top signature with nd=
        # may be extended only by the domain it names; and an UNSIGNED
        # instance with a null body Recipe -- the top, or one under our own
        # new instance -- is refused unless allow_null_body_recipe.  A null
        # that arrived signed is extended.  A message with no upstream chain
        # is signed as before.
        my $gate = Mail::DKIM2::Gate->check($message_data,
            SigningDomain       => $sign_domain,
            AllowNullBodyRecipe => $config->{'allow_null_body_recipe'} ? 1 : 0,
            SkipTimestampCheck  => $config->{'skip_timestamp_check'} ? 1 : 0,
            IgnorePrefixes      => $config->{'ignore_header_prefixes'},
            $self->_gate_key_source($config));
        $self->check_timeout();
        unless ( $gate->{ok} ) {
            my $reason = $gate->{reason} // 'refused';
            $gate->{message} =~ s/AllowNullBodyRecipe not set/allow_null_body_recipe not set/
                if defined $gate->{message};
            $self->metric_count( 'dkim2_sign_total', { 'result' => $reason } );
            $self->dbgout( 'DKIM2Sign',
                "Not signing for $sign_domain: $gate->{message}", LOG_INFO );
            # As bin/dkim2-milter: a broken upstream chain is already reported
            # by the verifier's Authentication-Results; the two refusals that
            # are this hop's own business are flagged on the message.
            if ( $reason ne 'upstream-chain' ) {
                push @{$handler->{pre_headers}}, {
                    'field' => 'X-DKIM2-Info',
                    'value' => _dkim2_info("not-signed=$reason"),
                };
            }
            return;
        }

        # Create the signer and feed the message
        my $signer = Mail::DKIM2::Signer->new(%signer_args);
        $signer->PRINT($message_data);
        $signer->CLOSE();
        $self->check_timeout();

        my $sig_result = $signer->result // 'none';
        $self->dbgout( 'DKIM2SignResult', $signer->result_detail // 'none', LOG_DEBUG );

        if ( $sig_result eq 'signed' ) {
            $self->_delete_mi_versions(@mi_removals);
            if ( defined $mi_value ) {
                push @{$handler->{pre_headers}}, {
                    'field' => 'Message-Instance',
                    'value' => $mi_value,
                };
            }

            # Extract the DKIM2-Signature header
            my $sig_header = $signer->as_string();
            # Strip the "DKIM2-Signature: " prefix
            $sig_header =~ s/^DKIM2-Signature:\s*//;

            push @{$handler->{pre_headers}}, {
                'field' => 'DKIM2-Signature',
                'value' => $sig_header,
            };

            # Informational, as bin/dkim2-milter: we signed over a null body
            # Recipe -- a null top, whether it arrived signed (no option
            # needed) or is this hop's own, or an unsigned null under the top
            # (allow_null_body_recipe).
            my $over_null = $gate->{top_null} || $gate->{unsigned_null};
            if ( $over_null ) {
                push @{$handler->{pre_headers}}, {
                    'field' => 'X-DKIM2-Info',
                    'value' => _dkim2_info('null-body-recipe'),
                };
            }

            $self->metric_count( 'dkim2_sign_total', { 'result' => 'signed' } );
            $self->dbgout( 'DKIM2Sign', "Signed for $sign_domain ($selector)"
                . ( $over_null ? ' over a null body Recipe' : '' ), LOG_INFO );
        }
        else {
            # The Signer refuses (result fail) rather than dying, e.g. over a
            # DKIM2-Signature it cannot key -- which the gate has already
            # refused.  Either way nothing is added to the message.
            $self->metric_count( 'dkim2_sign_total', { 'result' => 'error' } );
            $self->log_error( "DKIM2 signing failed: " . ($signer->result_detail // 'no result') );
        }
    };
    if ( my $error = $@ ) {
        $self->handle_exception( $error );
        $self->log_error( 'DKIM2 Sign Error ' . $error );
        $self->metric_count( 'dkim2_sign_total', { 'result' => 'error' } );
    }
}

# Delete the Message-Instance fields with these m= values from the message as
# it goes out, through the framework's change_header() (SMFIR_CHGHEADER with
# an empty value). The index is the field's position among the message's own
# Message-Instance fields, 1-based; deleting from the last one up keeps the
# earlier indexes valid. A version not among the received fields (another
# handler's) is not ours to delete.
sub _delete_mi_versions {
    my ( $self, @versions ) = @_;
    return unless @versions;
    my %want = map { $_ => 1 } @versions;
    my ( $n, @delete ) = ( 0 );
    for my $chunk ( @{ $self->{'headers'} || [] } ) {
        next unless $chunk =~ /\AMessage-Instance[ \t]*:(.*)\z/is;
        $n++;
        ( my $val = $1 ) =~ s/\A\s+//;
        my $v = extract_mi_version($val);
        push @delete, [ $n, $v ] if defined $v && $want{$v};
    }
    for my $d ( reverse @delete ) {
        $self->change_header( 'Message-Instance', $d->[0], q{} );
        $self->dbgout( 'DKIM2MI',
            "Deleted broken Message-Instance m=$d->[1] (field $d->[0]) from the message",
            LOG_INFO );
    }
}

sub close_callback {
    my ( $self ) = @_;
    delete $self->{'failmode'};
    delete $self->{'headers'};
    delete $self->{'body'};
    delete $self->{'carry'};
    delete $self->{'env_from'};
    delete $self->{'env_rcpt'};
    delete $self->{'sign_domain'};
}

# Compute Message-Instance header for the message.
#
# 1. If the topmost MI already matches, return undef (no new MI needed).
# 2. If a snapshot directory is configured, search all MI headers
#    (highest version first) for one that has a stored snapshot.
#    If found, compute a diff MI between the snapshot and current message.
# 3. Otherwise, fall back to a hash-only MI (no Recipes).
sub _compute_message_instance {
    my ( $self, $message_data, $config ) = @_;

    my $mi = eval {
        my $msg = parse_mime($message_data);

        # Skip if the topmost MI already matches current content
        my @ignore = ( IgnorePrefixes => $config->{'ignore_header_prefixes'} );
        if ( Mail::DKIM2::MessageInstance->verify($msg, @ignore) ) {
            $self->dbgout( 'DKIM2MI', 'Message unchanged, skipping MI', LOG_DEBUG );
            return undef;
        }

        my @mi_headers = $msg->header_raw('Message-Instance');
        # An m= above MAX_CHAIN_LENGTH is never a loop bound below (the gate
        # refuses the message on it).
        return undef if grep { chain_number_error('Message-Instance', 'm', mi_version_tag($_)) }
                        @mi_headers;
        my %mi_by_v = map { (extract_mi_version($_) || 0) => $_ } @mi_headers;
        my $max_v = @mi_headers ? (sort { $b <=> $a } keys %mi_by_v)[0] : 0;

        # Try to find a stored snapshot for any MI header
        if ( $config->{'snapshot_directory'} ) {
            my $store = Mail::DKIM2::MessageStore->new(
                directory => $config->{'snapshot_directory'},
            );
            for my $v (sort { $b <=> $a } keys %mi_by_v) {
                my $snapshot_data = $store->fetch($mi_by_v{$v});
                if ( $snapshot_data ) {
                    $self->dbgout( 'DKIM2MI', "Found snapshot for MI m=$v, computing diff", LOG_DEBUG );
                    my $snapshot_msg = parse_mime($snapshot_data);
                    my @snap_mi = $snapshot_msg->header_raw('Message-Instance');

                    # If the current message has more MI headers than the snapshot,
                    # upstream added intermediate MIs.  Since verify() already told us
                    # the top MI is wrong, strip those invalid intermediate headers and
                    # recompute a clean diff from the snapshot instead of propagating
                    # a broken chain.
                    my ($work_data, $work_msg) = ($message_data, $msg);
                    if ( @mi_headers > @snap_mi ) {
                        my %snap_by_v = map { (extract_mi_version($_) || 0) => $_ } @snap_mi;
                        my $snap_max_v = (sort { $b <=> $a } keys %snap_by_v)[0] // 0;
                        my @to_strip = ($snap_max_v + 1 .. $max_v);
                        $work_data = strip_mi_versions($message_data, @to_strip);
                        $work_msg  = parse_mime($work_data);
                        $self->{'_stripped_mi_versions'} = \@to_strip;
                        $self->dbgout( 'DKIM2MI',
                            'Stripped broken MI versions ' . join(',', @to_strip)
                            . " (snapshot at m=$snap_max_v) — broken chain detected",
                            LOG_INFO );
                    }

                    $self->{'_clean_message_data'} = $work_data;
                    return Mail::DKIM2::MessageInstance->calculate($work_msg, $snapshot_msg, @ignore);
                }
            }
        }

        # No snapshot available.
        if ( @mi_headers ) {
            # Message has been modified but we can't compute Recipes
            # without the previous state.  Log a warning.
            $self->dbgout( 'DKIM2MI', 'Message modified but no snapshot available, cannot compute MI', LOG_INFO );
            return undef;
        }

        # No existing MI headers — first-time signing, compute MI m=1
        Mail::DKIM2::MessageInstance->calculate($msg, undef, @ignore);
    };
    if ( my $error = $@ ) {
        $self->handle_exception( $error );
        $self->log_error( 'DKIM2 MI Error ' . $error );
        return;
    }

    return $mi;
}

# Format MI header value with folding for insertion into message
sub _format_mi {
    my ( $self, $mi ) = @_;
    my $folded = fold_header("Message-Instance: " . $mi->as_string());
    $folded =~ s/^Message-Instance: //;
    return $folded;
}

# X-DKIM2-Info value per draft-gondwana-dkim2-debug-header-01 (as
# bin/dkim2-milter): a tag-list, every tag (the last included) followed by
# ";", a ";" inside a value becoming ",".  Folded only after a ";" or a ",",
# never inside a token.  X-DKIM2-Info is excluded from the header hash by the
# x-* rule, so it can never affect a signature.
sub _dkim2_info {
    my ($action, %extra) = @_;
    my @tags = ("draft=" . DKIM2_DRAFT, "repo=" . DKIM2_REPO,
                "date=" . DKIM2_DATE, "sw=" . DKIM2_SOFTWARE, "action=$action");
    push @tags, "$_=$extra{$_}" for grep { defined $extra{$_} } sort keys %extra;
    my $val = join ' ', map { (my $t = $_) =~ s/;/,/g; "$t;" } @tags;
    (my $folded = fold_header("X-DKIM2-Info: $val", undef, delimiters_only => 1))
        =~ s/^X-DKIM2-Info:\s*//;
    $folded =~ s/\015?\012\z//;
    return $folded;
}

# Where the gate's Verifier gets upstream public keys: dns_overrides (a
# dns.json, for testing) when set, else the milter's own resolver (so its
# timeouts and caching apply), as DKIM2Verify does.
sub _gate_key_source {
    my ( $self, $config ) = @_;
    if ( my $file = $config->{'dns_overrides'} ) {
        require JSON;
        open my $fh, '<', $file or die "dns_overrides $file: $!\n";
        my $dns_data = JSON::decode_json( do { local $/; <$fh> } );
        return ( PubkeyCallback => sub {
            my ( $signature, $idx ) = @_;
            my $sel = $signature->selector( $idx // 0 );
            my $dom = $signature->domain;
            my $entry = ( $dom && $sel && $dns_data->{$dom} )
                ? $dns_data->{$dom}{"$sel._domainkey"} : undef;
            return unless $entry && $entry->[0];
            return parse_dkim_pubkey( $entry->[0][1] );
        } );
    }
    my $resolver = $self->get_object('resolver');
    return $resolver ? ( Resolver => $resolver ) : ();
}

# Domain of the From: header (lower-cased) from the stored raw header chunks,
# or undef. Used to pick a signing domain for null-sender bounces/DSNs.
sub _from_header_domain {
    my ($self) = @_;
    for my $h ( @{ $self->{'headers'} || [] } ) {
        next unless $h =~ /^From:/i;
        return lc $1 if $h =~ /\@([\w.-]+)/;
        last;
    }
    return;
}

# Look up signing config for a domain (static config, then HTTP endpoint)
sub _get_sign_config {
    my ( $self, $domain ) = @_;
    my $config = $self->_config();

    # Check static config first
    my $domains = $config->{'domains'} || {};
    if ( my $dc = $domains->{$domain} ) {
        return $dc;
    }

    # Try parent domains (e.g., sub.example.com -> example.com)
    my $try = $domain;
    while ( $try =~ s/^[^.]+\.// ) {
        if ( my $dc = $domains->{$try} ) {
            return $dc;
        }
    }

    # Try HTTP endpoint if configured
    if ( my $endpoint = $config->{'key_endpoint'} ) {
        return $self->_fetch_sign_config($endpoint, $domain);
    }

    return;
}

# Fetch signing config from HTTP endpoint
sub _fetch_sign_config {
    my ( $self, $endpoint, $domain ) = @_;
    my $config = $self->_config();
    my $timeout = $config->{'key_endpoint_timeout'} || 5;

    my $result = eval {
        require HTTP::Tiny;
        my $http = HTTP::Tiny->new( timeout => $timeout );
        my $url = "$endpoint?domain=$domain";
        $self->dbgout( 'DKIM2SignKeyLookup', $url, LOG_DEBUG );
        my $response = $http->get($url);

        if ( $response->{success} ) {
            my $data = JSON::decode_json( $response->{content} );
            if ( $data->{selector} && ( $data->{key} || $data->{keyfile} ) ) {
                $self->dbgout( 'DKIM2SignKeyLookup',
                    "Got config for $domain: selector=$data->{selector}", LOG_DEBUG );
                $data;
            }
            else { undef }
        }
        else {
            $self->dbgout( 'DKIM2SignKeyLookup',
                "Failed for $domain: $response->{status} $response->{reason}", LOG_DEBUG );
            undef;
        }
    };
    if ( my $error = $@ ) {
        $self->handle_exception( $error );
        $self->log_error( "DKIM2 key endpoint error for $domain: $error" );
    }

    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::Milter::Authentication::Handler::DKIM2Sign - Handler class for DKIM2 signing

=head1 DESCRIPTION

Signs outbound email with DKIM2-Signature headers and adds Message-Instance
headers for Chain of Custody tracking.  Runs in the addheader_callback phase
so the signature covers all headers including those added by other handlers.

Signing keys can be configured statically per domain, or looked up dynamically
via an HTTP REST endpoint.

Before it signs, the handler asks L<Mail::DKIM2::Gate> (the decision
C<bin/dkim2-milter> and C<bin/dkim2sign> make) about the message exactly as it
would sign it, its own new Message-Instance included: any upstream
DKIM2-Signatures must verify (a Message-Instance above the top signature, the
one being signed, is allowed), the Message-Instance chain must match the
content and undo cleanly, a top signature with C<nd=> must name the signing
domain, and an I<unsigned> Message-Instance with a null body Recipe (a null
this hop introduces, typically a list manager's) is signed only with
C<allow_null_body_recipe>.  A signature with C<m=k> covers instances 1 to
I<k>, so this applies to the top instance and equally to one under the
handler's own new instance.  A null that arrived signed is extended.  A
message with no upstream chain is signed as it always was.

When the handler recomputes its Message-Instance from a snapshot and drops
broken intermediate Message-Instances on the way, it deletes those fields from
the message once it has signed, through the framework's C<change_header()>
(an empty value: C<SMFIR_CHGHEADER> in milter mode).

On a refusal nothing is signed and no Message-Instance is added or removed;
the reason is logged (C<dbgout>, C<LOG_INFO>) and counted in
C<dkim2_sign_total> (C<result> C<upstream-chain>, C<broken-mi-chain> or
C<null-body-recipe>), and for the last two, as with C<dkim2-milter>, an
C<X-DKIM2-Info: ... action=not-signed=E<lt>reasonE<gt>;> field is prepended.
When it signs over a null body Recipe (a null top, or an unsigned null under
the top) it prepends C<X-DKIM2-Info: ... action=null-body-recipe;>.  If the Signer itself refuses
(result C<fail>, e.g. over a DKIM2-Signature it cannot key, which the gate has
already refused), nothing is added and the failure is logged as an error.

This module implements draft-ietf-dkim-dkim2-spec-06; see L<Mail::DKIM2/STATUS>
for what that means for the wire format and the API, and
L<Mail::DKIM2/CONVENTIONS> for the option, input and error conventions every
module here follows.

=head1 LIMITATIONS

=head2 Bcc recipients are recorded in a single rt= (Bcc leak)

The milter signs each message B<once>, recording B<all> of the SMTP
transaction's envelope recipients (every C<RCPT TO> seen in
C<envrcpt_callback>) in a single DKIM2-Signature C<rt=> tag.  It does B<not>
split the message into per-recipient instances.

This is fine for a forwarding hop, where the message has already been split at
origination and each copy carries a disclosed recipient set.  But at
B<origination / submission>, a message with undisclosed (Bcc) recipients —
envelope recipients that do not appear in the C<To:>/C<Cc:> headers — will have
those Bcc addresses recorded in C<rt=>, visible to every recipient.  That
B<leaks the Bcc>, contrary to draft-ietf-dkim-dkim2-spec-06, whose C<rt=>
description requires that Bcc recipients not be revealed to other recipients.

The milter cannot fix this itself: the Postfix milter protocol modifies a
single queued message at end-of-message and cannot fan one message out into
several separately-signed instances.  Bcc-safe origination must split the
message into one instance per recipient (or per disclosed group) B<before>
DKIM2 signing — in the submitting client/MSA, or via a Postfix content filter
that re-injects per-recipient copies through the signing milter.  See
C<deploy/SERVER.md> ("Bcc-safe origination: splitting recipients") for a
content-filter recipe.  A native MTA that emits per-recipient instances
directly does not have this problem; it is specific to the bolt-on-milter model.

=head1 CONFIGURATION

    "DKIM2Sign" : {
        "domains" : {                              | Static domain configs
            "example.com" : {                      |
                "selector" : "sel1",               |   DKIM2 selector
                "keyfile"  : "/path/to/key.pem"    |   Private key file path
            },                                     |
            "other.com" : {                        |
                "selector" : "default",            |
                "key"      : "base64_pem_data"     |   Or inline key data
            }                                      |
        },                                         |
        "key_endpoint"         : null,             | HTTP endpoint for dynamic key lookup
                                                   |   GET {url}?domain=X
                                                   |   Response: {"selector":"s1","keyfile":"/path"}
                                                   |         or: {"selector":"s1","key":"base64data"}
        "key_endpoint_timeout" : 5,                | HTTP timeout in seconds
        "sign_authenticated"   : 1,                | Sign for authenticated senders
        "sign_local"           : 1,                | Sign for local IP senders
        "add_message_instance" : 1,                | Add Message-Instance headers
        "record_smtp_params"   : 1,                | Record MAIL FROM/RCPT TO in signature
        "snapshot_directory"   : null,             | Snapshot dir (shared with DKIM2Verify)
        "ignore_header_prefixes" : [],             | Own fields hashed by neither end
        "allow_null_body_recipe" : 0,              | Sign over an unsigned
                                                   |   Message-Instance with a null
                                                   |   body Recipe (list hosts)
        "dns_overrides"        : null,             | Path to dns.json for testing
        "skip_timestamp_check" : 0                 | Testing: ignore upstream t=/expiry
    }

The values shown are the defaults.  authentication_milter does not fill in a
handler's defaults itself, so the handler does: an option left out of the
configuration (or set to C<null>) takes the value above, and an explicit
value, C<0> included, is used as given.

C<allow_null_body_recipe> is C<dkim2-milter>'s C<--allow-null-body-recipe>:
off by default, for a list host whose list manager rewrites bodies and adds an
unsigned Message-Instance with a null body Recipe for this handler to sign.  It
never excuses a broken chain.  C<dns_overrides> and C<skip_timestamp_check>
only affect the verification of the upstream chain, and are for tests.

When C<snapshot_directory> is set, the handler looks up a stored message
snapshot (written by DKIM2Verify on inbound) using the topmost Message-Instance
header value as the key.  If found, a diff-based MI is computed capturing
header and body changes made during local processing.  Without a snapshot,
a simple hash-only MI is computed.

=head1 HTTP KEY ENDPOINT

When C<key_endpoint> is configured, the handler will make a GET request to:

    {key_endpoint}?domain={domain}

The endpoint should return a JSON object with:

    {
        "selector": "sel1",
        "keyfile": "/path/to/private.pem"
    }

or:

    {
        "selector": "sel1",
        "key": "-----BEGIN RSA PRIVATE KEY-----\n..."
    }

Return HTTP 404 or an empty response to decline signing for that domain.

=head1 CALLBACKS

=head2 default_config()

Returns the default configuration hash for this handler.  The handler also
applies it at runtime to any option the configuration leaves out.

=head2 register_metrics()

Returns the metrics hash for this handler (C<dkim2_sign_total>).

=head2 envfrom_callback($env_from)

Resets per-message state and records the envelope sender.

=head2 envrcpt_callback($env_to)

Records each envelope recipient for the C<m=> SMTP params tag.

=head2 header_callback($header, $value, $original)

Collects each header line for message reconstruction.

=head2 eoh_callback()

Called at end of headers.  Resets the body carry buffer.

=head2 body_callback($body_chunk)

Collects body chunks, normalizing line endings to CRLF.

=head2 eom_callback()

Called at end of message.  Flushes any remaining body carry data.
Actual signing is deferred to C<addheader_callback()>.

=head2 addheader_callback($handler)

Performs the signing.  Determines the signing domain from the envelope
sender, looks up the key configuration, computes a Message-Instance header
if configured, applies L<Mail::DKIM2::Gate> (see L</DESCRIPTION>), creates the
DKIM2-Signature, and adds both as prepended headers via the milter handler
object.  Broken intermediate Message-Instances it stripped are deleted with
C<change_header()>.

=head2 close_callback()

Cleans up per-message state.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
