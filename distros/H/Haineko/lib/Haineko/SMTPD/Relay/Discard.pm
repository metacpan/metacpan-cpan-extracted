package Haineko::SMTPD::Relay::Discard;
use parent 'Haineko::SMTPD::Relay';
use strict;
use warnings;
use Time::Piece;
use Haineko::SMTPD::Response;

sub new {
    my $class = shift;
    my $argvs = { @_ };

    $argvs->{'time'}  ||= Time::Piece->new;
    $argvs->{'retry'}   = 0;
    $argvs->{'sleep'}   = 0;
    $argvs->{'timeout'} = 0;
    $argvs->{'startls'} = 0;
    return bless $argvs, __PACKAGE__;
}

sub sendmail {
    my $self = shift;

    $self->response( Haineko::SMTPD::Response->r( 'data', 'discard' ) );
    $self->response->rcpt( $self->{'rcpt'} );
    $self->response->mailer('Discard');
    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::Relay::Discard - Discard mailer class

=head1 DESCRIPTION

Discard any message

=head1 SYNOPSIS

    use Haineko::SMTPD::Relay::Discard;
    my $e = Haineko::SMTPD::Relay::Discard->new;
    my $s = $e->sendmail;

    print $s;                   # always return 1
    print $e->response->error;  # always return 0
    print $e->response->dsn;    # always return undef

    warn Data::Dumper::Dumper $e->response;
    $VAR1 = bless( {
             'dsn' => undef
             'error' => 0,
             'code' => '200',
             'message' => [ 'Discard' ],
             'command' => 'DATA'
            }, 'Haineko::SMTPD::Response' );

=head1 CLASS METHODS

=head2 B<new( I<%arguments> )>

new() is a constructor of Haineko::SMTPD::Relay::Discard

    my $e = Haineko::SMTPD::Relay::Discard->new;

=head1 INSTANCE METHODS

=head2 B<sendmail>

sendmail() will discard any message

    my $e = Haineko::SMTPD::Relay::Discard->new;
    print $e->sendmail;         # 1, message discarded
    print Dumper $e->response;  # Dumps Haineko::SMTPD::Response object

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
