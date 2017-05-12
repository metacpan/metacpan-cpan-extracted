package Haineko::SMTPD::Relay::Haineko;
use parent 'Haineko::SMTPD::Relay';
use strict;
use warnings;
use Furl;
use Try::Tiny;
use Time::Piece;
use Haineko::JSON;
use Haineko::SMTPD::Response;

sub new {
    my $class = shift;
    my $argvs = { @_ };

    $argvs->{'time'}    ||= Time::Piece->new;
    $argvs->{'sleep'}   ||= 5;
    $argvs->{'timeout'} ||= 30;
    return bless $argvs, __PACKAGE__;
}

sub sendmail {
    my $self = shift;

    my $hainekourl = sprintf( "http://%s:%d/submit", $self->{'host'}, $self->{'port'} );
    my $parameters = {
        'ehlo' => $self->{'ehlo'},
        'mail' => $self->{'mail'},
        'rcpt' => [ $self->{'rcpt'} ],
        'header' => {
            'from' => $self->{'head'}->{'From'},
            'subject' => $self->{'head'}->{'Subject'},
            'charset' => $self->{'attr'}->{'charset'},
        },
        'body' => $self->{'body'},
    };

    if( $self->{'head'}->{'Reply-To'} ) {
        $parameters->{'header'}->{'replyto'} = $self->{'head'}->{'Reply-To'};
    }

    my $jsonstring = Haineko::JSON->dumpjson( $parameters );
    my $httpheader = [];
    my $httpobject = undef;
    my $htresponse = undef;
    my $hainekores = undef;

    if( $self->{'username'} && $self->{'password'} ) {
        # Encode credentials for Basic-Authentication
        require MIME::Base64;
        my $v = MIME::Base64::encode_base64( $self->{'username'}.':'.$self->{'password'} );
        $httpheader = [ 'Authorization' => sprintf( "Basic %s", $v ) ];
    }

    $httpobject = Furl->new(
        'agent'    => __PACKAGE__,
        'timeout'  => 10,
        'headers'  => $httpheader,
        'ssl_opts' => { 'SSL_verify_mode' => 0 }
    );

    my $smtpstatus = 0;
    my $retryuntil = $self->{'retry'} || 0;

    my $sendmailto = sub {
        $htresponse = $httpobject->post( $hainekourl, $httpheader, $jsonstring );

        return 0 unless defined $htresponse;
        return 0 unless $htresponse->is_success;

        $smtpstatus = 1;
        return 1;
    };

    while(1) {
        last if $sendmailto->();
        last if $retryuntil == 0;

        $retryuntil--;
        sleep $self->{'sleep'};
    }

    if( defined $htresponse ) {
        # Check the response from another Haineko
        my $htcontents = undef;
        my $nekoparams = { 
            'code'    => $htresponse->code,
            'host'    => $self->{'host'},
            'port'    => $self->{'port'},
            'rcpt'    => $self->{'rcpt'},
            'error'   => $htresponse->is_success ? 0 : 1,
            'mailer'  => 'Haineko',
            'message' => [],
            'command' => 'POST',
        };

        if( $htresponse->body =~ m/Cannot connect to\s/ ) {
            # Cannot connect to 192.0.2.1:2794: timeout at 
            $self->response( Haineko::SMTPD::Response->r( 'conn', 'cannot-connect' ) );
            map { $self->response->{ $_ } = $self->{ $_ } } ( qw|host port rcpt| );

        } else {
            # Received as a JSON ?
            try {
                my $c = $htresponse->body || q();
                my $v = {};

                if( $c =~ m/(Failed to send HTTP request)/ ) {
                    # Failed to send HTTP request
                    # $htcontents = { 'response' => $1 };
                    $nekoparams->{'message'} = [ $1 ];
                } else {
                    # Response maybe JSON
                    $htcontents = Haineko::JSON->loadjson( $c ) || {};
                    $v = $htcontents->{'response'} || {};
                    $nekoparams->{'dsn'} ||= $v->{'dsn'};
                    push @{ $nekoparams->{'message'} }, ( $v->{'message'}->[-1] || q() );
                }

            } catch {

                $nekoparams->{'message'}->[0] = $_;
            };
            $self->response( Haineko::SMTPD::Response->new( %$nekoparams ) );
        }
    } else {
        $self->response( Haineko::SMTPD::Response->r( 'conn', 'cannot-connect' ) );
        map { $self->response->{ $_ } = $self->{ $_ } } ( qw|host port rcpt| );
    }

    return $smtpstatus;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::Relay::Haineko - Relays from Haineko to other Haineko

=head1 DESCRIPTION

Send an email from Haineko to other Haineko server using HTTP.

=head1 SYNOPSIS

    use Haineko::SMTPD::Relay::Haineko;
    my $h = { 'Subject' => 'Test', 'To' => 'neko@example.org' };
    my $v = { 
        'host' => '192.0.2.1', 
        'port' => 2794, 
        'auth' => 1
        'username' => 'user',
        'password' => 'secret',
        'ehlo' => '[127.0.0.1]',
        'mail' => 'kijitora@example.jp',
        'rcpt' => 'neko@example.org',
        'head' => $h,
        'body' => 'Email message',
    };
    my $e = Haineko::SMTPD::Relay::Haineko->new( %$v );
    my $s = $e->sendmail;

    print $s;                   # 0 = Failed to send, 1 = Successfully sent
    print $e->response->error;  # 0 = No error, 1 = Error
    print $e->response->dsn;    # returns D.S.N. value

    warn Data::Dumper::Dumper $e->response;
    $VAR1 = bless( {
             'dsn' => '2.1.0',
             'error' => 0,
             'code' => '200',
             'host' => '192.0.2.1',
             'port' => 2794,
             'rcpt' => 'neko@example.org',
             'message' => [
                    '2.1.0 <kijitora@example.jp>... Sender ok'
                      ],
             'command' => 'POST'
            }, 'Haineko::SMTPD::Response' );

=head1 CLASS METHODS

=head2 C<B<new( I<%arguments> )>>

C<new()> is a constructor of Haineko::SMTPD::Relay::Haineko

    my $e = Haineko::SMTPD::Relay::Haineko->new( 
            'host' => '192.0.2.1',          # Other Haineko server
            'port' => 2794,                 # HTTP Port for other Haineko
            'auth' => 1,                    # Use Basic-Authentication
            'username' => 'username',       # Username for Basic-Authentication
            'password' => 'password',       # Password for the user
            'starttls' => 0,                # Use STARTTLS or not
            'timeout' => 59,                # Timeout for Furl
            'attr' => {                     # Args for Email::MIME
                'content_type' => 'text/plain'
            },
            'head' => {                     # Email header
                'Subject' => 'Test',
                'To' => 'neko@example.org',
            },
            'body' => 'Email message',      # Email body
            'mail' => 'kijitora@example.jp',# Envelope sender
            'rcpt' => 'cat@example.org',    # Envelope recipient
    );

=head1 INSTANCE METHODS

=head2 C<B<sendmail>>

C<sendmail()> will send email to the specified recipient via specified host.

    my $e = Haineko::SMTPD::Relay::Haineko->new( %argvs );
    print $e->sendmail;         # 0 = Failed to send, 1 = Successfully sent
    print Dumper $e->response;  # Dumps Haineko::SMTPD::Response object

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
