package Haineko::SMTPD::Relay::Screen;
use parent 'Haineko::SMTPD::Relay';
use strict;
use warnings;
use Haineko::SMTPD::Response;
use Email::MIME;
use Time::Piece;
use Encode;

sub new {
    my $class = shift;
    my $argvs = { @_ };

    $argvs->{'host'}      = undef,
    $argvs->{'port'}      = undef,
    $argvs->{'time'}    ||= Time::Piece->new;
    $argvs->{'sleep'}     = 0;
    $argvs->{'retry'}     = 0;
    $argvs->{'timeout'}   = 0;
    $argvs->{'startls'}   = 0;
    return bless $argvs, __PACKAGE__;
}

sub sendmail {
    my $self = shift;

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
    my $smtpparams = { 
        'dsn'     => undef,
        'code'    => 200,
        'host'    => undef,
        'port'    => undef,
        'rcpt'    => $self->{'rcpt'},
        'error'   => 0,
        'mailer'  => 'Screen',
        'message' => [ 'OK' ],
        'command' => 'DATA',
    };
    $self->response( Haineko::SMTPD::Response->new( %$smtpparams ) );

    utf8::encode $mailstring if utf8::is_utf8 $mailstring;
    printf( STDERR "%s", $mailstring );

    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::Relay::Screen - Just print an email message

=head1 DESCRIPTION

Haineko::SMTPD::Relay::Screen is a dummy connection class for printing an email
message to Standard error device. This mailer is useful to debug.

=head1 SYNOPSIS

    use Haineko::SMTPD::Relay::Screen;
    my $h = { 'Subject' => 'Test', 'To' => 'neko@example.org' };
    my $v = { 
        'mail' => 'kijitora@example.jp',
        'rcpt' => 'neko@example.org',
        'head' => $h,
        'body' => 'Email message',
    };
    my $e = Haineko::SMTPD::Relay::Screen->new( %$v );
    my $s = $e->sendmail;

    print $s;                   # 1 = Always return 1
    print $e->response->error;  # 0 = Always return 0
    print $e->response->dsn;    # D.S.N. is always "undef"

    warn Data::Dumper::Dumper $e->response;
    $VAR1 = bless( {
             'dsn' => undef,
             'error' => 0,
             'code' => '200',
             'host' => undef,
             'port' => undef,
             'rcpt' => 'neko@example.org',
             'message' => [ 'OK' ],
             'command' => 'DATA'
            }, 'Haineko::SMTPD::Response' );

=head1 CLASS METHODS

=head2 C<B<new( I<%arguments> )>>

C<new()> is a constructor of Haineko::SMTPD::Relay::Screen

    my $e = Haineko::SMTPD::Relay::Screen->new( 
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

C<sendmail()> will print an email to standard error device.

    my $e = Haineko::SMTPD::Relay::Screen->new( %argvs );
    print $e->sendmail;         # Always 1
    print Dumper $e->response;  # Dumps Haineko::SMTPD::Response object

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut


