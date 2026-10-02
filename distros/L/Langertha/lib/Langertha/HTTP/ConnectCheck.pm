package Langertha::HTTP::ConnectCheck;
# ABSTRACT: Check that the modules Net::Async::HTTP loads at connect time load
our $VERSION = '0.503';
use strict;
use warnings;
use URI;


# Private to IO::Async (IO::Async::Loop->connect loads it via __new_feature);
# see the POD above for the assumption and when this check can go.
my @CONNECTOR = ( 'IO::Async::Internals::Connector', undef,
  'every HTTP connection needs it' );
# Net::Async::HTTP 0.50 requires 0.12 (the ->connect(handle) fix) after loading.
my @SSL = ( 'IO::Async::SSL', '0.12',
  'an SSL (https) connection needs it, with IO::Socket::SSL, Net::SSLeay and the system libssl' );

sub connect_error {
  my ( $uri, $ssl ) = @_;
  $uri = URI->new("$uri") unless ref $uri;
  my $scheme = lc( $uri->scheme // 'http' );
  # Net::Async::HTTP 0.50 (_do_request) derives SSL from the scheme, but passes
  # the caller's own SSL option after it, so an explicit one wins.
  $ssl //= $scheme eq 'https';
  my $target = $uri->can('host_port') && defined $uri->host && length $uri->host
    ? $scheme.'://'.$uri->host_port
    : $scheme.' URL';
  for my $need ( \@CONNECTOR, $ssl ? \@SSL : () ) {
    my ( $module, $min_version, $why ) = @{$need};
    ( my $file = "$module.pm" ) =~ s{::}{/}g;
    local $@;
    next if eval { require $file; $module->VERSION($min_version) if defined $min_version; 1 };
    my ($reason) = split /\n/, $@;
    return "cannot connect to $target: $module failed to load ($reason); $why";
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::HTTP::ConnectCheck - Check that the modules Net::Async::HTTP loads at connect time load

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::HTTP::ConnectCheck;

    if ( my $error = Langertha::HTTP::ConnectCheck::connect_error( $request->uri ) ) {
      return Future->fail( "$class: $error\n", 'connect' );
    }
    return $net_async_http->do_request( request => $request );

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

L<Net::Async::HTTP> loads some modules only when it opens a connection:
L<IO::Async::Internals::Connector> for every connection, L<IO::Async::SSL>
(with L<IO::Socket::SSL>, L<Net::SSLeay> and the system's libssl) for https.
When such a load dies, Net::Async::HTTP 0.50 has already counted the
connection against the host, and the dead connection keeps the host's slot:
every later request to that host waits forever, even once the module loads
(C<max_connections_per_host> is one by default). Core asks this module before
it hands a request to a L<Net::Async::HTTP> client
(L<Langertha::Role::AsyncHTTP>, L<Langertha::Content::Image>), so a broken
install is an error that names the module instead of a hang (karr k353).

=head2 connect_error

    my $error = Langertha::HTTP::ConnectCheck::connect_error( $uri );
    my $error = Langertha::HTTP::ConnectCheck::connect_error( $uri, $ssl );  # an explicit SSL option

Returns C<undef> when the modules a connection to C<$uri> (a L<URI> or a
string) needs load, else a one-line message without a trailing newline:
C<< cannot connect to <scheme>://<host>:<port>: <module> failed to load
(<first line of the load error>); <why it is needed> >>. Only scheme, host and
port name the target: a query or userinfo may carry a key.

Whether the connection needs SSL follows L<Net::Async::HTTP> 0.50: a C<SSL>
request option, passed here as C<$ssl>, wins when given (C<_do_request> puts
the caller's options after the C<SSL> it derives from the scheme), so C<http>
with C<< SSL => 1 >> connects with SSL and C<https> with C<< SSL => 0 >>
without; otherwise the scheme decides (C<https> is SSL).

A module that loads is not loaded again (perl keeps it in C<%INC>), so once
the modules are in, the check costs a few microseconds per request.

C<IO::Async::Internals::Connector> is a B<private> module name of L<IO::Async>,
hard-coded here on the assumption that L<IO::Async::Loop> keeps loading it
lazily under that name on connect (true for IO::Async 0.805). If IO::Async
renames it, the check reports a module that cannot load on every request, and
this module must follow the rename. The whole check can go once
L<Net::Async::HTTP> releases the host's slot when a connect-time load dies.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
