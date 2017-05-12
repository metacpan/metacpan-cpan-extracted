use strict;
use warnings;

package HTTP::CookieMonster::Cookie;
$HTTP::CookieMonster::Cookie::VERSION = '0.09';
use Moo;

# in order of args required in $cookie_jar->scan callback

has 'version'   => ( is => 'rw', );
has 'key'       => ( is => 'rw', );
has 'val'       => ( is => 'rw', );
has 'path'      => ( is => 'rw', );
has 'domain'    => ( is => 'rw', );
has 'port'      => ( is => 'rw', );
has 'path_spec' => ( is => 'rw', );
has 'secure'    => ( is => 'rw', );
has 'expires'   => ( is => 'rw', );
has 'discard'   => ( is => 'rw', );
has 'hash'      => ( is => 'rw', );

1;

# ABSTRACT: Cookie representation used by HTTP::CookieMonster

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::CookieMonster::Cookie - Cookie representation used by HTTP::CookieMonster

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use HTTP::CookieMonster::Cookie;
    my $cookie = HTTP::CookieMonster::Cookie->new(
        key       => 'cookie-name',
        val       => 'cookie-val',
        path      => '/',
        domain    => '.somedomain.org',
        path_spec => 1,
        secure    => 0,
        expires   => 1376081877
    );

    use WWW::Mechanize;
    use HTTP::CookieMonster;

    my $mech = WWW::Mechanize->new;
    my $monster = HTTP::CookieMonster->new( cookie_jar => $mech->cookie_jar );
    $monster->set_cookie( $cookie );

    $mech->get( $url );    # passes $cookie in request

=head1 DESCRIPTION

This module is intended to be used by L<HTTP::CookieMonster> to represent
cookies found in an L<HTTP::Cookies> cookie_jar.  To keep things familiar, I
have chosen method names which reflect the positional parameter names laid out
in the $cookie_jar->scan( \&callback ) documentation.

Not being intimately familiar with the HTTP cookie spec, I haven't forced
validation or default values on any attributes, so please be aware that the
burden is on the user to provide "correct" data if you are using this module
directly.

I have provided some sample values below.  To get a better idea of what is
required, try visiting a few sites and dumping their cookies.

    use Data::Printer;
    my $mech = WWW::Mechanize->new;
    $mech->get( 'http://www.google.ca' );
    my $monster = HTTP::CookieMonster->new( cookie_jar => $mech->cookie_jar );
    p $monster->all_cookies;

=head2 version

    $cookie->version( 0 );

=head2 key

The name of the cookie.

    $cookie->key( "session_id" );

=head2 val

The value of the cookie.

    $cookie->val( "random_stuff" );

If you are creating a new cookie, you should escape the value first.

    use URI::Escape qw( uri_escape );
    $cookie->value( uri_escape( 'random_stuff' ) );

=head2 path

    $cookie->path( "/" );

=head2 domain

    $cookie->domain( ".google.ca" );

=head2 port

=head2 path_spec

    $cookie->path_spec( 1 );

=head2 secure

    $cookie->secure( 1 );

=head2 expires

    $cookie->expires( 1407696193 );

=head2 discard

=head2 hash

    $cookie->hash( { HttpOnly => undef } );

=head1 SEE ALSO

This is mainly useful for creating cookies to be used by L<LWP::UserAgent> and
L<WWW::Mechanize classes>.  If you need to create cookies to set via headers,
have a look at L<Cookie::Baker>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
