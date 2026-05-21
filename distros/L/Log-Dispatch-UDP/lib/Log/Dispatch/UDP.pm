package Log::Dispatch::UDP;

use v5.8;
use strict;
use warnings;
use parent 'Log::Dispatch::Output';

use Carp qw(croak);
use IO::Socket::INET;
use Socket 2.026 qw(SOCK_DGRAM);

use namespace::clean;

# ABSTRACT: Log messages to a remote UDP socket

our $VERSION = '0.02';

sub new {
    my ( $class, %params ) = @_;

    my $host = $params{'host'} or croak 'host parameter required';
    my $port = $params{'port'} or croak 'port parameter required';

    my $sock = IO::Socket::INET->new(
        Proto    => 'udp',
        Type     => SOCK_DGRAM,
        PeerAddr => $host,
        PeerPort => $port,
    );

    croak $! unless $sock;

    my $self = bless {
        sock => $sock,
    }, $class;

    $self->_basic_init(%params);

    return $self;
}

sub log_message {
    my ( $self, %params ) = @_;

    my $message = $params{'message'};
    my $sock    = $self->{'sock'};

    $sock->send($message, 0);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords netcat

=head1 NAME

Log::Dispatch::UDP - Log messages to a remote UDP socket

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
    outputs => [
        [
            'UDP'
            host      => $destination_host,
            port      => $destination_port,
            min_level => 'info',
        ],
    ],
  );

  $log->info('my message');

=head1 DESCRIPTION

This class can be used to write messages to a UDP socket
listening on some remote host.  The datagrams themselves
contain only the messages (there's no real structure to them),
so you can easily listen in using netcat.

=head1 SECURITY CONSIDERATIONS

Log messages are not encrypted.  Be wary of logging authentication
details such as usernames, passwords or session ids, financial
information such as credit cards, or other personally identifying
information over unsecured channels.

=head1 SEE ALSO

L<Log::Dispatch>

=for Pod::Coverage new

=for Pod::Coverage log_message

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Log-Dispatch-UDP>
and may be cloned from L<https://github.com/robrwo/perl-Log-Dispatch-UDP.git>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.8 or later.
Future releases may only support Perl versions released in the last ten (10) years.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Log-Dispatch-UDP/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

This module is currently maintained by Robert Rothenberg <perl@rhizomnic.com>.

=head1 CONTRIBUTOR

=for stopwords Robert Rothenberg

Robert Rothenberg <perl@rhizomnic.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012, 2026 by Rob Hoelz <rob@hoelz.ro>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
