package Langertha::HTTP::Redirect;
# ABSTRACT: The redirect policy both HTTP backends follow: credentials stay on their origin
our $VERSION = '0.503';
use strict;
use warnings;
use HTTP::Request;
use URI;
use URI::Escape qw( uri_unescape );


# Headers that describe the representation, not the caller: the only ones that
# go to another origin.
my %KEEP = map { $_ => 1 } qw(
  accept accept-charset accept-encoding accept-language
  content-type content-language user-agent
);

# Names under which a request carries a credential. Only used to find the
# secret values the chain sent (which must not reach another origin in a URL);
# headers to another origin are dropped by the %KEEP allowlist, not by name.
# Anchored on the whole name: a pagination cursor (Gemini's pageToken,
# page_token, nextPageToken) is not a credential, and treating its value as one
# would drop it from a cross-origin redirect and lose the page.
my $CREDENTIAL_NAME = qr/\A(?:
    (?:api[-_]?)?key
  | token | (?:access|auth|bearer|id|refresh|session)[-_]?token
  | auth | (?:proxy-)?authori[sz]ation
  | (?:client[-_])?secret | passw(?:or)?d
  | sig | signature
  | (?:[a-z0-9]+-)+(?:token|key|secret)
)\z/xi;

# A secret this short would match too much of an unrelated URL; it is still
# dropped as an exact query value, just not searched for in the rest of the URL.
my $MIN_SEARCHED = 8;

my %FOLLOWED_CODE = map { $_ => 1 } 301, 302, 303, 307, 308;

sub same_origin {
  my ( $left, $right ) = map { URI->new("$_") } @_;
  return 0 unless lc( $left->scheme // '' ) eq lc( $right->scheme // '' );
  return 0 unless $left->can('host') && $right->can('host');
  return 0 unless lc( $left->host // '' ) eq lc( $right->host // '' );
  return ( $left->port // 0 ) == ( $right->port // 0 ) ? 1 : 0;
}


sub next_request {
  my ( $request, $response, $pinned_host ) = @_;
  return undef unless $FOLLOWED_CODE{ $response->code };
  my $location = $response->header('Location');
  return undef unless defined $location && length $location;
  return _refuse( $response, 'only GET and HEAD are redirected, not ' . uc $request->method )
    unless ( uc $request->method ) =~ /\A(?:GET|HEAD)\z/;
  my $next = HTTP::Request->new( $request->method,
    URI->new_abs( $location, $request->uri ), $request->headers->clone, $request->content );
  $next->protocol( $request->protocol ) if defined $request->protocol;
  $next->remove_header( 'Host', 'Cookie' );
  return guard_referral( $next, $response, $pinned_host ) ? $next : undef;
}


sub guard_referral {
  my ( $referral, $response, $pinned_host ) = @_;
  # The method of the request the redirect answers, not the referral's: LWP
  # turns a 302/303 POST into a GET, and a requests_redirectable with POST in it
  # would otherwise re-send a body (a chat, AKI's key) to wherever Location says.
  my $original = $response->request;
  return _refuse( $response, 'only GET and HEAD are redirected, not '
      . ( $original ? uc $original->method : 'a request of unknown method' ) )
    unless $original && ( uc $original->method ) =~ /\A(?:GET|HEAD)\z/;
  my $from = $original->uri;
  my $to   = $referral->uri;
  my $scheme = lc( $to->scheme // '' );
  return _refuse( $response, "not to a non-HTTP URL ($scheme)" )
    unless $scheme eq 'http' || $scheme eq 'https';
  return _refuse( $response, 'not from https to http' )
    if lc( $from->scheme // '' ) eq 'https' && $scheme eq 'http';
  # A connection pinned to a checked address (connect_address, karr k375) is
  # pinned for its host only; another host would be resolved afresh, which is
  # the DNS-rebinding window the pin closes.
  return _refuse( $response, "connect_address pins $pinned_host; not to another host (" . lc( $to->host // '' ) . ')' )
    if defined $pinned_host && $from->can('host') && lc( $from->host // '' ) eq lc $pinned_host
      && !( $to->can('host') && lc( $to->host // '' ) eq lc $pinned_host );
  return 1 if same_origin( $from, $to );

  $referral->remove_header($_) for grep { !$KEEP{ lc $_ } } $referral->header_field_names;

  $to = $to->clone;
  $to->userinfo(undef);
  my %secret = _chain_secrets($response);
  if ( %secret && defined $to->query ) {
    my @pairs = $to->query_form;
    my ( @kept, $dropped );
    while ( my ( $name, $value ) = splice @pairs, 0, 2 ) {
      if ( defined $value && $secret{$value} ) { $dropped = 1 }
      else                                     { push @kept, $name, $value }
    }
    # Rewritten only when something was dropped, so an untouched query keeps
    # its bytes (a presigned URL's signature must not be re-encoded).
    if ($dropped) {
      if (@kept) { $to->query_form( \@kept ) }
      else       { $to->query(undef) }
    }
  }
  my $url = uri_unescape("$to");
  for my $value ( grep { length >= $MIN_SEARCHED } keys %secret ) {
    return _refuse( $response, 'a credential of the request would be in the URL of another origin' )
      if index( $url, $value ) >= 0;
  }
  $referral->uri($to);
  return 1;
}

# A redirect that is not followed goes back to the caller as the 3xx; say why on
# it, the way LWP does for its own refusals (Client-Warning).
sub _refuse {
  my ( $response, $reason ) = @_;
  $response->push_header( 'Client-Warning' => "redirect not followed: Langertha::HTTP::Redirect: $reason" );
  return undef;
}


# Every credential value the chain of requests behind $response carried: query
# values under a credential-like name, and credential-like header values (with
# and without their auth scheme). The value set, not the names, is what a
# redirect URL is checked against, so an echo under any name is caught.
sub _chain_secrets {
  my ($response) = @_;
  my %secret;
  for ( my $hop = $response; $hop; $hop = $hop->previous ) {
    my $request = $hop->request or next;
    my @pairs = $request->uri->can('query_form') ? $request->uri->query_form : ();
    while ( my ( $name, $value ) = splice @pairs, 0, 2 ) {
      $secret{$value} = 1 if defined $value && length $value && $name =~ $CREDENTIAL_NAME;
    }
    for my $name ( grep { $_ =~ $CREDENTIAL_NAME } $request->header_field_names ) {
      for my $value ( $request->header($name) ) {
        next unless defined $value && length $value;
        $secret{$value} = 1;
        $secret{$1} = 1 if $value =~ /\A\S+\s+(\S+)\s*\z/;
      }
    }
  }
  return %secret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::HTTP::Redirect - The redirect policy both HTTP backends follow: credentials stay on their origin

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::HTTP::Redirect;

    # Net::Async::HTTP, one hop at a time (max_redirects => 0):
    my $next = Langertha::HTTP::Redirect::next_request( $request, $response );
    return $response unless $next;              # not followed: the caller sees the 3xx

    # LWP (Langertha::HTTP::UserAgent::redirect_ok), on the referral LWP built:
    return 0 unless Langertha::HTTP::Redirect::guard_referral( $referral, $response );

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

An engine puts its credential on each request for B<its own> origin: an
C<Authorization> or C<x-api-key> header, a C<?key=> query parameter. Neither
HTTP client keeps it there on a redirect. L<LWP::UserAgent> clones the request
with every header (it drops only C<Authorization>, and only since 6.83), so an
C<x-api-key> reached whatever host the server named; L<Net::Async::HTTP> keeps
the Location's query, so a server echoing the request URI (C<return 301
https://new.example$request_uri>) sent Gemini's C<?key=> along (karr k374).

This module is the one policy both backends follow
(L<Langertha::HTTP::UserAgent> for LWP, L<Langertha::Role::AsyncHTTP> for
L<Net::Async::HTTP>):

=over 4

=item * Only C<GET> and C<HEAD> are followed, on 301, 302, 303, 307 and 308
with a C<Location> — what both clients follow by default. A C<POST> (chat,
embeddings, a key in the body) is never re-sent anywhere, even through an
agent whose C<requests_redirectable> lists it.

=item * Only to C<http> or C<https>, and never from C<https> down to C<http>.

=item * On the B<same origin> (scheme, host and port) the request goes on
unchanged, credential included. C<Cookie> and C<Host> are never carried over.
C<http://host> to C<https://host> is B<another> origin (the scheme differs):
the credential is dropped, so a keyed GET behind an http-to-https redirect
gets a 401 from the https side. Configure the engine with the C<https> URL.

=item * To B<another origin> only the representation headers go along
(C<Accept>, C<Accept-Charset>, C<Accept-Encoding>, C<Accept-Language>,
C<Content-Type>, C<Content-Language>, C<User-Agent>) — every other header is
dropped, so an auth header of any name stays behind without a list of names to
keep up to date. Userinfo is dropped from the new URL. Every query parameter
whose value is a credential the chain of requests carried (a query value
under a credential-like name such as C<key>, or a credential-like header's
value, without its C<Bearer>/C<Basic> scheme) is removed; the target's own
query is otherwise kept byte for byte. If such a credential would still be in
the new URL (in its path, say), the redirect is not followed.

=back

A redirect that is not followed leaves the 3xx response to the caller, which
then fails with its status line like any other non-success response. When
this policy refused it, the response carries a C<Client-Warning> header saying
why (C<redirect not followed: Langertha::HTTP::Redirect: ...>); so does the
last 3xx when the hop limit ran out on L<Net::Async::HTTP>.

=head2 same_origin

    Langertha::HTTP::Redirect::same_origin( $uri_a, $uri_b );   # 1 or 0

True when both URLs have the same scheme, host and port (compared
case-insensitively, a default port equal to its explicit number).

=head2 next_request

    my $next = Langertha::HTTP::Redirect::next_request( $request, $response );
    my $next = Langertha::HTTP::Redirect::next_request( $request, $response, $pinned_host );

The request to send for the redirect C<$response> to C<$request>, or C<undef>
when it is not followed. C<$request> is not modified. The chain of earlier
responses (C<< $response->previous >>) is searched for credentials too.
C<$pinned_host> is passed on to L</guard_referral>.

=head2 guard_referral

    my $follow = Langertha::HTTP::Redirect::guard_referral( $referral, $response );
    my $follow = Langertha::HTTP::Redirect::guard_referral( $referral, $response, $pinned_host );

Applies the policy to C<$referral>, the request about to be sent for the
redirect C<$response> (whose C<request> is the hop it answers). Returns false
when the redirect must not be followed, and then adds a C<Client-Warning>
header naming the reason to C<$response> (C<redirect not followed:
Langertha::HTTP::Redirect: ...>); otherwise strips C<$referral> in place if it
goes to another origin and returns true. The method checked is the one of
C<< $response->request >>, so a C<POST> is refused even when an agent's
C<requests_redirectable> would allow it.

When C<$pinned_host> is given (the host of an engine's
L<Langertha::Role::HTTP/connect_address>), a redirect from that host to any
other host is refused too (C<connect_address pins ...; not to another host>):
the pinned address was checked for that host only. A redirect staying on the
host, on any port, is decided as usual and connects to the pinned address
again.

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
