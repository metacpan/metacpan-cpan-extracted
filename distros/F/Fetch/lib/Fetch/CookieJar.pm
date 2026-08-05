package Fetch::CookieJar;

use strict;
use warnings;

our $VERSION = '0.09';

require Fetch;

1;

__END__

=head1 NAME

Fetch::CookieJar - store cookies and apply them to requests

=head1 SYNOPSIS

    my $ua = Fetch->new(cookie_jar => 1);        # auto-create a jar
    $ua->post('https://site/login', body => 'u=me&p=secret')->get;
    # the Set-Cookie from that response is now sent on later requests:
    my $res = $ua->get('https://site/account')->get;

    # or manage a jar directly
    my $jar = Fetch::CookieJar->new;
    $jar->set_cookie('sid=abc; Path=/; Secure', 'site', '/login');
    my $cookie = $jar->cookie_header('site', '/account', 1);   # "sid=abc"

=head1 DESCRIPTION

A cookie store following the practical parts of RFC 6265: it parses
C<Set-Cookie> response headers and builds the C<Cookie> header for an outgoing
request, honouring Domain (host-only and subdomain matching), Path, Expires /
Max-Age and the Secure flag. Cookies are keyed by (domain, path, name).

Give a jar to L<Fetch> with C<< Fetch->new(cookie_jar => $jar) >> (or
C<< cookie_jar => 1 >> to make a fresh one) and it is applied automatically,
including across redirects.

=head1 METHODS

=head2 set_cookie($set_cookie_value, $host, $request_path)

Parse one C<Set-Cookie> value as if received from C<$host> for C<$request_path>
and store it (or delete it, if expired).

=head2 extract($response_or_headers, $host, $request_path)

Store every C<Set-Cookie> in a L<Fetch::Response> or L<Fetch::Headers>.

=head2 cookie_header($host, $request_path, $secure)

The C<Cookie> header value for a request to C<$host>/C<$request_path> (pass a
true C<$secure> for https), or undef if nothing matches.

=head2 clear / count / purge

Remove all cookies; how many are stored; drop expired ones.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
