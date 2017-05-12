package Haineko::SMTPD::Relay::ESMTP;
use parent 'Haineko::SMTPD::Relay';
use strict;
use warnings;
use Net::SMTP;
use Module::Load;
use Haineko::SMTPD::Response;
use Haineko::SMTPD::Greeting;
use Email::MIME;
use Time::Piece;
use Encode;

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

    my $esmtpclass = $self->{'starttls'} ? 'Net::SMTPS' : 'Net::SMTP';
    my $headerlist = [];
    my $emencoding = uc( $self->{'attr'}->{'charset'} || 'UTF-8' );
    my $methodargv = {
        'body' => Encode::encode( $emencoding, ${ $self->{'body'} } ),
        'attributes' => $self->{'attr'},
    };
    utf8::decode $methodargv->{'body'} unless utf8::is_utf8 $methodargv->{'body'} ;

    for my $e ( @{ $self->{'head'}->{'Received'} } ) {
        # Convert email headers
        push @$headerlist, 'Received' => $e;
    }
    push @$headerlist, 'To' => $self->{'rcpt'};

    for my $e ( keys %{ $self->{'head'} } ) {
        # Make email headers except ``Received'' and ``MIME-Version''
        next if $e eq 'Received';
        next if $e eq 'MIME-Version';

        if( ref $self->{'head'}->{ $e } eq 'ARRAY' ) {

            for my $f ( @{ $self->{'head'}->{ $e } } ) {
                push @$headerlist, $e => $f;
            }
        }
        else { 
            push @$headerlist, $e => $self->{'head'}->{ $e };
        }
    }
    $methodargv->{'header'} = $headerlist;

    my $mimeobject = Email::MIME->create( %$methodargv );
    my $mailstring = $mimeobject->as_string;
    my $maillength = length $mailstring;

    my $smtpparams = {
        'Port'    => $self->{'port'},
        'Hello'   => $self->{'ehlo'},
        'Debug'   => $self->{'debug'} || 0,
        'Timeout' => $self->{'timeout'} || 30,
    };

    if( $self->{'starttls'} ) {
        # Sendmail using TLS(Net::SMTPS)
        Module::Load::load('Net::SMTPS');
        $smtpparams->{'doSSL'} = 'starttls';
        $smtpparams->{'SSL_verify_mode'} = 'SSL_VERIFY_NONE';
    }

    my $netsmtpobj = undef;
    my $authensasl = undef;
    my $nekogreets = undef;
    my $smtpstatus = 0;
    my $thecommand = q();
    my $pipelining = q();
    my $retryuntil = $self->{'retry'} || 0;

    my $sendmailto = sub {

        $thecommand = 'ehlo';
        return 0 unless $netsmtpobj = $esmtpclass->new( $self->{'host'}, %$smtpparams );
        $nekogreets = Haineko::SMTPD::Greeting->new( $netsmtpobj->message );

        if( $nekogreets->auth && $self->{'auth'} ) {
            # SMTP-AUTH
            require Authen::SASL;
            $authensasl = Authen::SASL->new( 
                'mechanism' => join( ' ', @{ $nekogreets->mechanism } ),
                'callback'  => { 
                    'user' => $self->{'username'}, 
                    'pass' => $self->{'password'},
                    'authname' => $self->{'username'}, 
                },
            );
            $thecommand = 'auth';
            return 0 unless $netsmtpobj->auth( $authensasl );
        }

        if( $nekogreets->pipelining ) {
            # 250-PIPELINING
            $thecommand  = 'data';
            $pipelining  = sprintf( "MAIL FROM: <%s>", $self->{'mail'} );
            $pipelining .= sprintf( ' RET=FULL' ) if $nekogreets->dsn;
            $pipelining .= sprintf( " SIZE=%d", $maillength ) if $nekogreets->size;
            $pipelining .= sprintf( "\r\n" );
            $pipelining .= sprintf( "RCPT TO: <%s>", $self->{'rcpt'} );
            $pipelining .= sprintf( ' NOTIFY=FAILURE,DELAY' ) if $nekogreets->dsn;
            $pipelining .= sprintf( "\r\n" );
            $pipelining .= sprintf( "DATA\r\n" );
            $pipelining .= sprintf( "%s", $mailstring );
            return 0 unless $netsmtpobj->datasend( $pipelining );
            return 0 unless $netsmtpobj->dataend();

        } else {
            # External SMTP Server does not support PIPELINING
            my $cmdargvs = [];
            my $cmdparam = {};

            $thecommand = 'mail';
            $cmdargvs = [ $self->{'mail'} ];
            $cmdparam->{'Return'} = 'FULL' if $nekogreets->dsn;
            $cmdparam->{'Size'} = $maillength if $nekogreets->size;
            push @$cmdargvs, %$cmdparam if keys %$cmdparam;
            return 0 unless $netsmtpobj->mail( @$cmdargvs );

            $thecommand = 'rcpt';
            $cmdargvs = [ $self->{'rcpt'} ];
            $cmdparam = {};
            $cmdparam->{'Notify'} = [ 'FAILURE', 'DELAY' ] if $nekogreets->dsn;
            push @$cmdargvs, %$cmdparam if keys %$cmdparam;
            return 0 unless $netsmtpobj->to( @$cmdargvs );

            $thecommand = 'data';
            return 0 unless $netsmtpobj->data();
            return 0 unless $netsmtpobj->datasend( $mailstring );
            return 0 unless $netsmtpobj->dataend();
        }

        $thecommand = 'QUIT';
        $netsmtpobj->quit;
        $smtpstatus = 1;
        return 1;
    };

    while(1) {
        last if $sendmailto->();
        last if $retryuntil == 0;

        $netsmtpobj->quit if defined $netsmtpobj;
        $retryuntil--;
        sleep $self->{'sleep'};
    }

    if( defined $netsmtpobj ) {
        # Check the response from SMTP server
        $smtpparams = { 
            'code'    => $netsmtpobj->code,
            'host'    => $self->{'host'},
            'port'    => $self->{'port'},
            'rcpt'    => $self->{'rcpt'},
            'mailer'  => 'ESMTP',
            'message' => [ $netsmtpobj->message ],
            'command' => $thecommand,
        };
        $self->response( Haineko::SMTPD::Response->p( %$smtpparams ) );
        $netsmtpobj->quit;

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

Haineko::SMTPD::Relay::ESMTP - ESMTP Connection class

=head1 DESCRIPTION

Send an email to external server using SMTP protocol.

=head1 SYNOPSIS

    use Haineko::SMTPD::Relay::ESMTP;
    my $h = { 'Subject' => 'Test', 'To' => 'neko@example.org' };
    my $v = { 
        'host' => '192.0.2.1', 
        'port' => 587, 
        'auth' => 1
        'username' => 'user',
        'password' => 'secret',
        'ehlo' => '[127.0.0.1]',
        'mail' => 'kijitora@example.jp',
        'rcpt' => 'neko@example.org',
        'head' => $h,
        'body' => 'Email message',
    };
    my $e = Haineko::SMTPD::Relay::ESMTP->new( %$v );
    my $s = $e->sendmail;

    print $s;                   # 0 = Failed to send, 1 = Successfully sent
    print $e->response->error;  # 0 = No error, 1 = Error
    print $e->response->dsn;    # returns D.S.N. value

    warn Data::Dumper::Dumper $e->response;
    $VAR1 = bless( {
             'dsn' => '2.1.0',
             'error' => 0,
             'code' => '250',
             'rcpt' => 'neko@example.org',
             'host' => '192.0.2.1',
             'port' => 587,
             'message' => [
                    '2.0.0 OK Authenticated',
                    '2.1.0 <kijitora@example.jp>... Sender ok'
                      ],
             'command' => 'QUIT'
            }, 'Haineko::SMTPD::Response' );

=head1 CLASS METHODS

=head2 C<B<new( I<%arguments> )>>

C<new()> is a constructor of Haineko::SMTPD::Relay::ESMTP

    my $e = Haineko::SMTPD::Relay::ESMTP->new( 
            'host' => '192.0.2.1',          # SMTP Server
            'port' => 587,                  # SMTP Port
            'auth' => 1,                    # Use SMTP-AUTH
            'username' => 'username',       # Username for SMTP-AUTH
            'password' => 'password',       # Password for the user
            'starttls' => 0,                # Use STARTTLS or not
            'timeout' => 59,                # Timeout for Net::SMTP
            'debug' => 0,                   # Debug for Net::SMTP
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

    my $e = Haineko::SMTPD::Relay::ESMTP->new( %argvs );
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
