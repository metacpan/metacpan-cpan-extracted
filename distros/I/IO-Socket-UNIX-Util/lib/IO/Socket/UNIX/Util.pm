package IO::Socket::UNIX::Util;

our $DATE = '2014-12-05'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

use IO::Socket::UNIX;
use POSIX qw(locale_h);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       create_unix_socket
                       create_unix_stream_socket
                       create_unix_datagram_socket
               );

sub create_unix_socket {
    my ($path, $mode, $opts) = @_;

    $opts //= {};

    my $old_locale = setlocale(LC_ALL);

    my $sock;

    setlocale(LC_ALL, "C"); # so that error messages are in English
    # probe the Unix socket first, delete if stale
    {
        $sock = IO::Socket::UNIX->new(
            Type => SOCK_STREAM,
            Peer => $path,
            %$opts,
        );
        my $err = $@ unless $sock;
        if ($sock) {
            die "Some process is already listening on $path, aborting";
        } elsif ($err =~ /^connect: permission denied/i) {
            die "Cannot access $path, aborting";
        } elsif (1) { #$err =~ /^connect: connection refused/i) {
            unlink $path;
        } elsif ($err !~ /^connect: no such file/i) {
            die "Cannot bind to $path: $err";
        }
    }
    setlocale(LC_ALL, $old_locale);

    # XXX this is a race condition

    # create listening socket now
    $sock = IO::Socket::UNIX->new(
        Type   => SOCK_STREAM,
        Local  => $path,
        Listen => 1,
        %$opts,
    );
    die "Can't create listening Unix socket: $@" unless $sock;

    if (defined $mode) {
        warn "Can't chmod $path: $!" unless chmod($mode, $path);
    }

    $sock;
}

sub create_unix_stream_socket {
    my ($path, $mode, $opts) = @_;
    $opts //= {};
    create_unix_socket($path, $mode, {Type=>SOCK_STREAM, %$opts});
}

sub create_unix_datagram_socket {
    my ($path, $mode, $opts) = @_;
    $opts //= {};
    create_unix_socket($path, $mode, {Type=>SOCK_DGRAM, %$opts});
}

1;
# ABSTRACT: Unix domain socket utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Socket::UNIX::Util - Unix domain socket utilities

=head1 VERSION

This document describes version 0.05 of IO::Socket::UNIX::Util (from Perl distribution IO-Socket-UNIX-Util), released on 2014-12-05.

=head1 FUNCTIONS

=head2 create_unix_socket($path[, $mode, \%opts]) => SOCKET

Create a listening Unix socket (by default with Type SOCK_STREAM) using
L<IO::SOcket::UNIX>. C<%opts> will be passed to L<IO::Socket::UNIX>.

Die on failure.

This function creates Unix domain socket with the usual way of using
L<IO::Socket::UNIX> with some extra stuffs: remove stale socket first, show more
detailed/precise error message, chmod with $mode.

=head2 create_unix_stream_socket($path[, $mode, \%opts]) => SOCKET

Shortcut for:

 create_unix_socket($path, $mode, {Type=>SOCK_STREAM, %opts});

which is the default anyway.

=head2 create_unix_datagram_socket($path[, $mode, \%opts]) => SOCKET

Shortcut for:

 create_unix_socket($path, $mode, {Type=>SOCK_DGRAM, %opts});

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/IO-Socket-UNIX-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SHARYANTO-IO-Socket-Utils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=IO-Socket-UNIX-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
