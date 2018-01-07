package Mail::Milter::Authentication::Handler::SMIME;
use strict;
use warnings;
use base 'Mail::Milter::Authentication::Handler';
use version; our $VERSION = version->declare('v1.1.7');

use English qw{ -no_match_vars };
use Sys::Syslog qw{:standard :macros};

use Convert::X509;
use Crypt::SMIME;
use Email::MIME;

sub default_config {
    return {
        'hide_none' => 0,
        'pki_store' => '/etc/ssl/certs',
   };
}

sub grafana_rows {
    my ( $self ) = @_;
    my @rows;
    push @rows, $self->get_json( 'SMIME_metrics' );
    return \@rows;
}

sub register_metrics {
    return {
        'smime_total' => 'The number of emails processed for SMIME',
    };
}

sub envfrom_callback {
    my ($self) = @_;
    $self->{'data'}  = [];
    $self->{'found'} = 0;
    $self->{'added'} = 0;
    $self->{'metric_result'} = 'unknown';
    return;
}

sub header_callback {
    my ( $self, $header, $value ) = @_;
    push @{$self->{'data'}} , $header . ': ' . $value . "\n";
    return;
}

sub eoh_callback {
    my ( $self ) = @_;
    push @{$self->{'data'}} , "\n";
    return;
}

sub body_callback {
    my ( $self, $chunk ) = @_;
    push @{$self->{'data'}} , $chunk;
    return;
}

sub eom_callback {
    my ( $self ) = @_;

    my $config = $self->handler_config();

    my $data = join( q{}, @{ $self->{'data'} } );
    $data =~ s/\r//g;
#    my $EOL        = "\015\012";
#    $data =~ s/\015?\012/$EOL/g;

    eval {
        my $parsed = Email::MIME->new( $data );
        $self->_parse_mime( $parsed, q{} );

        if ( $self->{'found'} == 0 ) {
            if ( !( $config->{'hide_none'} ) ) {
                $self->add_auth_header(
                    $self->format_header_entry( 'smime', 'none' ),
                );
            }
            $self->{'metric_result'} = 'none';
        }
        elsif ( $self->{'added'} == 0 ) {
            $self->add_auth_header(
                $self->format_header_entry( 'smime', 'temperror' ),
            );
            $self->{'metric_result'} = 'error';
        }
    };
    if ( my $error = $@ ) {
        $self->log_error( 'SMIME Execution Error ' . $error );
        $self->add_auth_header(
            $self->format_header_entry( 'smime', 'temperror' ),
        );
        $self->{'metric_result'} = 'error';
    }

    $self->metric_count( 'smime_total', { 'result' => $self->{'metric_result'} } );

    return;
}


sub _parse_mime {
    my ( $self, $mime, $part_id ) = @_;

    $part_id =~ s/TEXT\.// ;

    my $content_type = $mime->content_type() || q{};
    #$self->{'thischild'}->loginfo( 'SMIME Parse Type ' . $content_type );

    my $protocol = q{};
    if ( $content_type . ';' =~ /protocol=.*;/ ) {
        ( $protocol ) = $content_type =~ /protocol=([^;]*);/;
        $protocol =~ s/"//g if $protocol;
    }

    my $smime_type = q{};
    if ( $content_type . ';' =~ /smime-type=.*;/ ) {
        ( $smime_type ) = $content_type =~ /smime-type=([^;]*);/;
        $smime_type =~ s/"//g if $smime_type;
    }

    $content_type =~ s/;.*//;

    if ( $content_type eq 'message/rfc822' ) {
        my $new_part = $part_id;
        if ( $new_part ne q{} ) {
            $new_part .= '.';
        }
        my $parsed = Email::MIME->new( $mime->body_raw() );
        $self->_parse_mime( $parsed, $new_part . 'TEXT' );
    }

    if ( $content_type eq 'multipart/signed' ) {
        $self->{'thischild'}->loginfo( 'SMIME found ' . $content_type );
        $self->{'thischild'}->loginfo( 'SMIME Protocol ' . $protocol );
        if ( $protocol eq 'application/pkcs7-signature' || $protocol eq 'application/x-pkcs7-signature' || $protocol eq q{} ) {
            my $header = $mime->{'header'}->as_string();
            my $body   = $mime->body_raw();
            $self->_check_mime( $header . "\r\n" . $body, $part_id );
        }
    }

    if ( $content_type eq 'application/pkcs7-mime' ) {
        $self->{'thischild'}->loginfo( 'SMIME found ' . $content_type );
        $self->{'thischild'}->loginfo( 'SMIME Type ' . $smime_type );
        if ( $smime_type eq 'signed-data' || $smime_type eq q{} ) {
            # See rfc5751 3.4
            my $header = $mime->{'header'}->as_string();
            my $body   = $mime->body_raw();
            $self->_check_mime( $header . "\r\n" . $body, $part_id );
        }
    }

    my @parts = $mime->subparts();
    #$self->{'thischild'}->loginfo( 'SMIME Has Subparts ' . scalar @parts );

    my $i = 1;
    my $new_part = $part_id;
    if ( $new_part ne q{} ) {
        $new_part .= '.';
    }
    foreach my $part ( @parts ) {
        $self->_parse_mime( $part, $new_part . $i++ );
    }

    return;
}

sub close_callback {
    my ( $self ) = @_;
    delete $self->{'metric_result'};
    delete $self->{'added'};
    delete $self->{'found'};
    delete $self->{'data'};
    return;
}

sub _check_mime {
    my ( $self, $data, $part_id ) = @_;

    if ( $part_id eq q{} ) {
        $part_id = 'TEXT';
    }

    $self->{'found'} = 1;

    my $smime = Crypt::SMIME->new();
    my $config = $self->handler_config();
    $smime->setPublicKeyStore( $config->{'pki_store'} );

    my $is_signed;
    $is_signed = eval{ $smime->isSigned( $data ); };
    if ( my $error = $@ ) {
        $self->log_error( 'SMIME isSigned Error ' . $error );
    }

    if ( $is_signed ) {

        my $source;
        eval {
            $source = $smime->check( $data );
        };
        if ( my $error = $@ ) {
            $self->log_error( 'SMIME check Error ' . $error );
            my $signatures = Crypt::SMIME::getSigners( $data );
            my $all_certs  = Crypt::SMIME::extractCertificates( $data );
            $self->_decode_certs( 'fail', $signatures, $all_certs, $part_id );
            ## ToDo extract the reason for failure and add as header comment
            if ( $self->{'added'} == 0 ) {
                $self->add_auth_header(
                    $self->format_header_entry( 'smime', 'fail' ),
                );
                $self->{'metric_result'} = 'fail';
                $self->{'added'} = 1;
            }
        }
        else {
            my $signatures = Crypt::SMIME::getSigners( $data );
            my $all_certs  = Crypt::SMIME::extractCertificates( $data );
            $self->_decode_certs( 'pass', $signatures, $all_certs, $part_id );
        }
    }

    return;
}

sub _decode_certs {
    my ( $self, $passfail, $signatures, $all_certs, $part_id ) = @_;

    my $seen = {};


    SIGNATURE:
    foreach my $cert ( @{$signatures} ) {


        my $cert_info = Convert::X509::Certificate->new( $cert );

        my $subject = $cert_info->subject();
        my $issuer  = $cert_info->issuer();
        my $from    = $cert_info->from();
        my $to      = $cert_info->to();
        my $eku     = $cert_info->eku();
        my $serial  = $cert_info->serial();
        my @aia     = $cert_info->aia();

        $from = 'TEST' if exists $self->handler_config()->{ 'TEST_DATE' };
        $to   = 'TEST' if exists $self->handler_config()->{ 'TEST_DATE' };

        next SIGNATURE if $seen->{ $serial };
        $seen->{ $serial } = 1;

        my @results;
        push @results, $self->format_header_entry( 'body.smime-identifier', $subject->{'E'}[0] )
            . '(' . $self->format_header_comment( $subject->{'CN'}[0] ) . ')';
        push @results, $self->format_header_entry( 'body.smime-part', $part_id );
        push @results, $self->format_header_entry( 'body.smime-serial', $serial );
        my $issuer_text = join( ',', map{ $_ . '=' . $issuer->{$_}[0] } sort keys (%{$issuer}) );
        $issuer_text =~ s/\"/ /g;
        push @results, 'body.smime-issuer="' . $self->format_ctext( $issuer_text ) . '"' ;
        push @results, 'x-smime-valid-from="' . $self->format_ctext( $from ) . '"';
        push @results, 'x-smime-valid-to="'   . $self->format_ctext( $to ) . '"';
        $self->add_auth_header(
            join( "\n        ",
                $self->format_header_entry( 'smime', $passfail ),
                @results,
            )
        );
        $self->{'metric_result'} = $passfail;
        $self->{'added'} = 1;
    }

    # Non standard
    CERT:
    foreach my $cert ( @{$all_certs} ) {

        my $cert_info = Convert::X509::Certificate->new( $cert );

        my $subject = $cert_info->subject();
        my $issuer  = $cert_info->issuer();
        my $from    = $cert_info->from();
        my $to      = $cert_info->to();
        my $eku     = $cert_info->eku();
        my $serial  = $cert_info->serial();
        my @aia     = $cert_info->aia();

        $from = 'TEST' if exists $self->handler_config()->{ 'TEST_DATE' };
        $to   = 'TEST' if exists $self->handler_config()->{ 'TEST_DATE' };

        next CERT if $seen->{ $serial };
        $seen->{ $serial } = 1;

        my @results;
        push @results, $self->format_header_entry( 'body.smime-part', $part_id );
        push @results, $self->format_header_entry( 'x-smime-chain-identifier', ( $subject->{'E'}[0] || 'null' ) )
            . ' (' . $self->format_header_comment( $subject->{'CN'}[0] ) . ')';
        push @results, $self->format_header_entry( 'x-smime-chain-serial', $serial );
        my $issuer_text = join( ',', map{ $_ . '=' . $issuer->{$_}[0] } sort keys (%{$issuer}) );
        $issuer_text =~ s/\"/ /g;
        push @results, 'x-smime-chain-issuer="' . $self->format_ctext( $issuer_text ) . '"' ;
        push @results, 'x-smime-chain-valid-from="' . $self->format_ctext( $from ) . '"';
        push @results, 'x-smime-chain-valid-to="'   . $self->format_ctext( $to ) . '"';
                $self->add_auth_header(
                    join( "\n        ",
                        $self->format_header_entry( 'x-smime-chain', 'info' ),
                        @results,
                    )
                );
                $self->{'added'} = 1;
    }

    return;
}

1;

__END__

=head1 NAME

  Authentication Milter - SMIME Module

=head1 DESCRIPTION

Check SMIME signed email for validity.

=head1 CONFIGURATION

        "SMIME" : {
            "hide_none" : 0,
            "pki_store" : "/etc/ssl/certs"
        },

=head1 SYNOPSIS

=head2 CONFIG

Add a block to the handlers section of your config as follows.

        "SMIME" : {
            "hide_none"         : 0,                    | Hide auth line if the result is 'none'
            "pki_store"         : "/etc/ssl/certs"      | The location of your trusted root certs
        },

=head1 AUTHORS

Marc Bradshaw E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT

Copyright 2017

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.



