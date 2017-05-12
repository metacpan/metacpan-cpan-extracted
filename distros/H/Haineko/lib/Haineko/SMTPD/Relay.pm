package Haineko::SMTPD::Relay;
use strict;
use warnings;
use Class::Accessor::Lite;

my $rwaccessors = [
    'time',     # (Time::Piece)
    'mail',     # (String) Envelope from
    'rcpt',     # (String) Envelope to
    'head',     # (ArrayRef) Email headers
    'body',     # (ScalarRef) Body part
    'attr',     # (HashRef) Email::MIME attributes
    'host',     # (String) Relay server hostname
    'port',     # (String) Relay server port
    'auth',     # (Integer) Rerquire SMTP-AUTH or not
    'retry',    # (Integer) Retry count when an SMTP server returns 4XX.
    'sleep',    # (Integer) Sleep for specified seconds until the next retrying
    'debug',    # (Integer) 1 = Debug mode(Net::SMTP)
    'timeout',  # (Integer) Timeout
    'username', # (String) Username for SMTP-AUTH
    'password', # (String) Password for SMTP-AUTH
    'response', # (Haineko::SMTPD::Response) ESMTP Replies from MTA
    'starttls', # (Integer) use STARTTLS or not
];
my $roaccessors = [];
my $woaccessors = [];
Class::Accessor::Lite->mk_accessors( @$rwaccessors );


sub new {
    my $class = shift;
    my $argvs = { @_ };
    return bless $argvs, __PACKAGE__;
}

sub defaulthub {
    my $class = shift;
    return {
        'host' => '127.0.0.1',
        'port' => 25,
        'auth' => 0,
        'mailer' => 'ESMTP',
    };
}

sub sendmail {
    my $self = shift;
    # Code for sending email at each class in Relay/*.pm
    return 0;
}

sub getbounce {
    my $self = shift;
    # Code for getting email bounce at each class in Relay/*.pm
    return 0;
}

1;
__END__
=encoding utf8

=head1 NAME

Haineko::SMTPD::Relay - SMTP Connection class

=head1 DESCRIPTION

Base class for relaying to external SMTP server. Two instance methods: sendmail()
and getbounce() should be implemented at sub class.

=head1 SEE ALSO

=over 2

=item *
L<Haineko::SMTPD::Relay::ESMTP> - Relaying via ESMTP 

=item *
L<Haineko::SMTPD::Relay::SendGrid> - Relaying via SendGrid Web API

=item *
L<Haineko::SMTPD::Relay::AmazonSES> - Relaying via Amazon SES API

=item *
L<Haineko::SMTPD::Relay::Discard> - Email blackhole

=back

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
