#!perl

use strict;
use warnings;

use Test::More;

use HTTP::Cookies ();
use HTTP::Date ();
use HTTP::Request ();
use HTTP::Response ();
use URI ();

my $expiry_string = HTTP::Date::time2str( time + 86400 );
my $jar = HTTP::Cookies->new();

plan tests => 20;

# https://curl.haxx.se/rfc/cookie_spec.html

# First Example transaction sequence:
{
    my $res = HTTP::Response->new( 200, 'OK' );
    my $req = request_for('www.acme.com');
    $res->request($req);

    # 1.1
    # Client requests a document, and receives in the response:
    #   Set-Cookie: CUSTOMER=WILE_E_COYOTE; path=/; expires=Wednesday, 09-Nov-99 23:12:40 GMT
    $res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE; path=/ ; expires=${expiry_string}");
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 1, '1.1: res: found the cookie');

    # 1.2
    # When client requests a URL in path "/" on this server, it sends:
    #   Cookie: CUSTOMER=WILE_E_COYOTE
    # Client requests a document, and receives in the response:
    #   Set-Cookie: PART_NUMBER=ROCKET_LAUNCHER_0001; path=/
    $req = request_for('www.acme.com');
    $jar->add_cookie_header($req);
    is($req->header("Cookie"), "CUSTOMER=WILE_E_COYOTE", '1.2: req: customer');
    is($req->header("Cookie2"), q{$Version="1"}, '1.2: req: version');
    $res->request($req);
    $res->header("Set-Cookie" => "PART_NUMBER=ROCKET_LAUNCHER_0001; path=/");
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 2, '1.2: res: two cookies found');

    # 1.3
    # When client requests a URL in path "/" on this server, it sends:
    #   Cookie: CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001
    # Client receives:
    #   Set-Cookie: SHIPPING=FEDEX; path=/foo
    $req = request_for('www.acme.com');
    $jar->add_cookie_header($req);
    my $h = $req->header("Cookie"); # checking header contents is easier
    like($h, qr/PART_NUMBER=ROCKET_LAUNCHER_0001/, '1.3: req: first cookie found');
    like($h, qr/CUSTOMER=WILE_E_COYOTE/, '1.3: req: second cookie found');
    $res->request($req);
    $res->header("Set-Cookie" => "SHIPPING=FEDEX; path=/foo");
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 3, '1.3: res: three cookies found');

    # 1.4
    # When client requests a URL in path "/" on this server, it sends:
    #   Cookie: CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001
    $req = request_for('www.acme.com');
    $jar->add_cookie_header($req);
    $h = $req->header("Cookie"); # checking header contents is easier
    like($h, qr/PART_NUMBER=ROCKET_LAUNCHER_0001/, '1.4: req: first cookie found');
    like($h, qr/CUSTOMER=WILE_E_COYOTE/, '1.4: req: second cookie found');
    unlike($h, qr/SHIPPING=FEDEX/, '1.4: req: no shipping cookie');
    $res->request($req);
    $res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001");
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 3, '1.4: res: three cookies found');

    # 1.5
    # When client requests a URL in path "/foo" on this server, it sends:
    #   Cookie: CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001; SHIPPING=FEDEX
    # The last Cookie is buggy, because both specifications says that the
    # most specific cookie must be sent first.  SHIPPING=FEDEX is the
    # most specific and should thus be first.
    $req = request_for('www.acme.com/foo');
    $jar->add_cookie_header($req);
    $h = $req->header("Cookie"); # checking header contents is easier
    like($h, qr/PART_NUMBER=ROCKET_LAUNCHER_0001/, '1.5: req: first cookie found');
    like($h, qr/CUSTOMER=WILE_E_COYOTE/, '1.5: req: second cookie found');
    like($h, qr/SHIPPING=FEDEX/, '1.5: req: third cookie found');
    $res->request($req);
    $res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001");
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 3, '1.5: res: three cookies found');
}

# Second Example transaction sequence:
# Assume all mappings from above have been cleared.
{
    $jar->clear();
    my $res = HTTP::Response->new( 200, 'OK' );
    my $req = request_for('www.acme.com');
    $res->request($req);

    # 2.1
    # Client receives:
    #   Set-Cookie: PART_NUMBER=ROCKET_LAUNCHER_0001; path=/
    # When client requests a URL in path "/" on this server, it sends:
    #   Cookie: PART_NUMBER=ROCKET_LAUNCHER_0001
    $res->header("Set-Cookie" => "PART_NUMBER=ROCKET_LAUNCHER_0001; path=/");
    $jar->extract_cookies($res);
    $req = request_for('www.acme.com');
    $jar->add_cookie_header($req);
    is($req->header("Cookie"), "PART_NUMBER=ROCKET_LAUNCHER_0001", '2.1: req: cookie found');
    $res->request($req);
    $res->header("Set-Cookie" => "PART_NUMBER=ROCKET_LAUNCHER_0001; path=/");
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 1, '2.1: res: one cookie found');

    # 2.2
    # Client receives:
    #   Set-Cookie: PART_NUMBER=RIDING_ROCKET_0023; path=/ammo
    # When client requests a URL in path "/ammo" on this server, it sends:
    #   Cookie: PART_NUMBER=RIDING_ROCKET_0023; PART_NUMBER=ROCKET_LAUNCHER_0001
    # NOTE: There are two name/value pairs named "PART_NUMBER" due to the inheritance of the "/" mapping in addition to the "/ammo" mapping.
    $res->header("Set-Cookie", "PART_NUMBER=RIDING_ROCKET_0023; path=/ammo");
    $jar->extract_cookies($res);
    $req = request_for('www.acme.com/ammo');
    $jar->add_cookie_header($req);
    my $h = $req->header("Cookie"); # checking header contents is easier
    like($h, qr/PART_NUMBER=ROCKET_LAUNCHER_0001/, '2.2: req: first cookie found');
    like($h, qr/PART_NUMBER=RIDING_ROCKET_0023/, '2.2: req: second cookie found');
    $res->request($req);
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 2, '2.2: res: three cookies found');
}

sub count_cookies_for {
    my $host = shift;
    my $count = 0;
    $jar->scan( sub { $_[4] eq $host && $count++ });
    return $count;
}

sub request_for {
    my $uri = URI->new('http://'.shift)->canonical;
    my $req = HTTP::Request->new( GET => $uri);
    $req->header( Host => $uri->host_port );
    return $req;
}
