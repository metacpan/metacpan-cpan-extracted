package HTTP::Daemon::UNIX;

our $DATE = '2016-08-03'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

use HTTP::Daemon;
use IO::Handle::Record; # for peercred()
use IO::Socket::UNIX::Util qw(create_unix_socket);

our @ISA = qw(HTTP::Daemon IO::Socket::UNIX);

sub new {
    my ($class, %args) = @_;

    # XXX normalize arg case first

    my $sock = IO::Socket::UNIX::Util::create_unix_socket(
        $args{Local});
    bless $sock, $class;
}

sub url {
    my ($self) = @_;
    my $hostpath = $self->hostpath;
    $hostpath =~ s!^/!!;
    my $url = $self->_default_scheme . ":" . $hostpath;

    # note: my LWP::Protocol::http::SocketUnixAlt requires this syntax ("//"
    # separates the Unix socket path and URI):
    # http:abs/path/to/unix.sock//uri/path
}

1;
# ABSTRACT: HTTP::Daemon over Unix sockets

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Daemon::UNIX - HTTP::Daemon over Unix sockets

=head1 VERSION

This document describes version 0.06 of HTTP::Daemon::UNIX (from Perl distribution HTTP-Daemon-UNIX), released on 2016-08-03.

=head1 SYNOPSIS

 use HTTP::Daemon::UNIX;

 # arguments will be passed to IO::Socket::UNIX, but Listen=>1 and
 # Type=>SOCK_STREAM will be added by default. also, HTTP::Daemon::UNIX will try
 # to delete stale socket first, for convenience.
 my $d = HTTP::Daemon::UNIX->new(Local => "/path/to/unix.sock");

 # will print something like: "http:path/to/unix.sock"
 print "Please contact me at: <URL:", $d->url, ">\n";

 # after that, use like you would use HTTP::Daemon
 while (my $c = $d->accept) {
     while (my $r = $c->get_request) {
         if ($r->method eq 'GET' and $r->uri->path eq "/xyzzy") {
             # remember, this is *not* recommended practice :-)
             $c->send_file_response("/etc/passwd");
         } else {
             $c->send_error(RC_FORBIDDEN);
         }
     }
     $c->close;
     undef($c);
 }

 # client side code, using LWP::Protocol::http::SocketUnixAlt
 use LWP::Protocol::http::SocketUnixAlt;
 use LWP::UserAgent;
 use HTTP::Request::Common;

 my $ua = LWP::UserAgent->new;
 my $orig_imp = LWP::Protocol::implementor("http");
 LWP::Protocol::implementor(http => 'LWP::Protocol::http::SocketUnixAlt');
 my $resp = $ua->request(GET "http:path/to/unix.sock//uri/path");
 LWP::Protocol::implementor(http => $orig_imp);

=head1 DESCRIPTION

This is a quick hack to enable L<HTTP::Daemon> to serve requests over Unix
sockets, by mixing in L<IO::Socket::UNIX> and HTTP::Daemon as parents to
L<HTTP::Daemon::UNIX> and overriding IO::Socket::INET-related stuffs.

Basic stuffs seem to be working, but this module has not been tested
extensively, so beware that things might blow up in your face.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Daemon-UNIX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Daemon-UNIX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Daemon-UNIX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Daemon>

L<LWP::Protocol::http::SocketUnixAlt>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
