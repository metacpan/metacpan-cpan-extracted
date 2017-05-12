use strict;
use warnings;

package HTTP::CookieMonster;
$HTTP::CookieMonster::VERSION = '0.09';
$HTTP::CookieMonster::VERSION = '0.09';

use 5.006;

use Moo;
use Carp qw( croak );
use HTTP::Cookies;
use HTTP::CookieMonster::Cookie;
use Safe::Isa;
use Scalar::Util qw( reftype );
use Sub::Exporter -setup => { exports => ['cookies'] };
use URI::Escape qw( uri_escape uri_unescape );

my @_cookies = ();
has 'cookie_jar' => (
    required => 1,
    is       => 'ro',
    isa      => sub {
        croak 'HTTP::Cookies object expected'
            if !$_[0]->$_isa( 'HTTP::Cookies' );
        }

);

sub BUILDARGS {
    my ( $class, @args ) = @_;

    return { cookie_jar => shift @args } if @args == 1;
    return {@args};
}

# all_cookies() is now a straight method rather than a Moo accessor in order to
# prevent the all_cookies list from getting out of sync with changes to the
# cookie_jar which happen outside of this module.  Rather than trying to detect
# changes, we'll just create a fresh list each time.  Performance penalties
# should be minimal and this keeps things simple.

sub all_cookies {
    my $self = shift;
    @_cookies = ();
    $self->cookie_jar->scan( \&_check_cookies );

    wantarray ? return @_cookies : return \@_cookies;
}

# my $cookie = cookies( $jar ); -- first cookie (makes no sense)
# my $session = cookies( $jar, 'session' );
# my @cookies = cookies( $jar );
# my @sessions = cookies( $jar, 'session' );

sub cookies {
    my ( $cookie_jar, $name ) = @_;
    croak 'This function is not part of the OO interface'
        if $cookie_jar->$_isa( 'HTTP::CookieMonster' );

    my $monster = HTTP::CookieMonster->new( $cookie_jar );

    if ( !$name ) {
        if ( !wantarray ) {
            croak
                'Please specify a cookie name when asking for a single cookie';
        }
        return @{ $monster->all_cookies };
    }

    return $monster->get_cookie( $name );
}

sub get_cookie {
    my $self = shift;
    my $name = shift;

    my @cookies = ();
    foreach my $cookie ( $self->all_cookies ) {
        if ( $cookie->key eq $name ) {
            return $cookie if !wantarray;
            push @cookies, $cookie;
        }
    }

    return shift @cookies if !wantarray;
    return @cookies;
}

sub set_cookie {
    my $self   = shift;
    my $cookie = shift;

    if ( !$cookie->$_isa( 'HTTP::CookieMonster::Cookie' ) ) {
        croak "$cookie is not a HTTP::CookieMonster::Cookie object";
    }

    return $self->cookie_jar->set_cookie(
        $cookie->version,           $cookie->key,
        uri_escape( $cookie->val ), $cookie->path,
        $cookie->domain,            $cookie->port,
        $cookie->path_spec,         $cookie->secure,
        $cookie->expires,           $cookie->discard,
        $cookie->hash
    ) ? 1 : 0;
}

sub delete_cookie {
    my $self   = shift;
    my $cookie = shift;

    if ( !$cookie->$_isa( 'HTTP::CookieMonster::Cookie' ) ) {
        croak "$cookie is not a HTTP::CookieMonster::Cookie object";
    }

    $cookie->expires( -1 );

    return $self->set_cookie( $cookie );
}

sub _check_cookies {
    my @args = @_;

    push @_cookies,
        HTTP::CookieMonster::Cookie->new(
        version   => $args[0],
        key       => $args[1],
        val       => uri_unescape( $args[2] ),
        path      => $args[3],
        domain    => $args[4],
        port      => $args[5],
        path_spec => $args[6],
        secure    => $args[7],
        expires   => $args[8],
        discard   => $args[9],
        hash      => $args[10],
        );

    return;
}

1;

# ABSTRACT: Easy read/write access to your jar of HTTP::Cookies
#

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::CookieMonster - Easy read/write access to your jar of HTTP::Cookies

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    # Use the functional interface for quick read-only access
    use HTTP::CookieMonster qw( cookies );
    use WWW::Mechanize;

    my $mech = WWW::Mechanize->new;
    my $url = 'http://www.nytimes.com';
    $mech->get( $url );

    my @cookies = cookies( $mech->cookie_jar );
    my $cookie  = cookies( $mech->cookie_jar, 'RMID' );
    print $cookie->val;

    # Use the OO interface for read/write access

    use HTTP::CookieMonster;

    my $monster = HTTP::CookieMonster->new( $mech->cookie_jar );
    my $cookie = $monster->get_cookie('RMID');
    print $cookie->val;

    $cookie->val('random stuff');
    $monster->set_cookie( $cookie );

    # now fetch page using mangled cookie
    $mech->get( $url );

=head1 DESCRIPTION

This module was created because messing around with L<HTTP::Cookies> is
non-trivial.  L<HTTP::Cookies> a very useful module, but using it is not always
as easy and clean as it could be. For instance, if you want to find a
particular cookie, you can't just ask for it by name.  Instead, you have to use
a callback:

    $cookie_jar->scan( \&callback )

The callback will be invoked with 11 positional parameters:

    0 version
    1 key
    2 val
    3 path
    4 domain
    5 port
    6 path_spec
    7 secure
    8 expires
    9 discard
    10 hash

That's a lot to remember and it doesn't make for very readable code.

Now, let's say you want to save or update a cookie. Now you're back to the many
positional params yet again:

    $cookie_jar->set_cookie( $version, $key, $val, $path, $domain, $port, $path_spec, $secure, $maxage, $discard, \%rest )

Also not readable. Unless you have an amazing memory, you may find yourself
checking the docs regularly to see if you did, in fact, get all those params in
the correct order etc.

HTTP::CookieMonster gives you a simple interface for getting and setting
cookies. You can fetch an ARRAY of all your cookies:

    my @all_cookies = $monster->all_cookies;
    foreach my $cookie ( @all_cookies ) {
        print $cookie->key;
        print $cookie->val;
        print $cookie->secure;
        print $cookie->domain;
        # etc
    }

Or, if you know for a fact exactly what will be in your cookie jar, you can
fetch a cookie by name.

    my $cookie = $monster->get_cookie( 'plack_session' );

This gives you fast access to a cookie without a callback, iterating over a
list etc. It's good for quick hacks and you can dump the cookie quite easily to
inspect its contents in a highly readable way:

    use Data::Printer;
    p $cookie;

If you want to mangle the cookie before the next request, that's easy too.

    $cookie->val('woohoo');
    $monster->set_cookie( $cookie );
    $mech->get( $url );

Or, add an entirely new cookie to the jar:

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

    $monster->set_cookie( $cookie );
    $mech->get( $url );

=head2 new

new() takes just one required parameter, which is cookie_jar, a valid
L<HTTP::Cookies> object.

    my $monster = HTTP::CookieMonster->new( $mech->cookie_jar );

=head2 cookie_jar

A reader which returns an L<HTTP::Cookies> object.

=head2 all_cookies

Returns an ARRAY of all cookies in the cookie jar, represented as
L<HTTP::CookieMonster::Cookie> objects.

    my @cookies = $monster->all_cookies;
    foreach my $cookie ( @cookies ) {
        print $cookie->key;
    }

=head2 set_cookie( $cookie )

Sets a cookie and updates the cookie jar.  Requires a
L<HTTP::CookieMonster::Cookie> object.

    my $monster = HTTP::CookieMonster->new( $mech->cookie_jar );
    my $s = $monster->get_cookie('session');
    $s->val('random_string');

    $monster->set_cookie( $s );

    # You can also add an entirely new cookie to the jar via this method

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

    $monster->set_cookie( $cookie );

=head2 delete_cookie( $cookie )

Deletes a cookie and updates the cookie jar.  Requires a
L<HTTP::CookieMonster::Cookie> object.

=head2 get_cookie( $name )

Be aware that this method may surprise you by what it returns.  When called in
scalar context, get_cookie() returns the first cookie which exactly matches the
name supplied.  In many cases this will be exactly what you want, but that
won't always be the case.

If you are spidering multiple web sites with the same UserAgent object, be
aware that you'll likely have cookies from multiple sites in your cookie jar.
In this case asking for get_cookie('session') in scalar context may not return
the cookie which you were expecting.  You will be safer calling get_cookie() in
list context:

    $monster = HTTP::CookieMonster->new( $mech->cookie_jar );

    # first cookie with this name
    my $first_session = $monster->get_cookie('session');

    # all cookies with this name
    my @all_sessions  = $monster->get_cookie('session');

=head1 FUNCTIONAL/PROCEDURAL INTERFACE

=head2 cookies

This function will DWIM.  Here are some examples:

    use HTTP::CookieMonster qw( cookies );

    # get all cookies in your jar
    my @cookies = cookies( $mech->cookie_jar );

    # get all cookies of a certain name/key
    my @session_cookies = cookies( $mech->cookie_jar, 'session_cookie_name' );

    # get the first cookie of a certain name/key
    my $first_session_cookie = cookies( $mech->cookie_jar, 'session_cookie_name' );

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
