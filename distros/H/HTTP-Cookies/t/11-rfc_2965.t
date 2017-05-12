#!perl

use strict;
use warnings;

use Test::More;

use HTTP::Cookies ();
use HTTP::Request ();
use HTTP::Response ();
use URI ();

my $jar = HTTP::Cookies->new();

plan tests => 13;

# https://www.rfc-editor.org/rfc/rfc2965.txt
# Section 4

# Example 1
{
    # 1-2
    # Most detail of request and response headers has been omitted.  Assume
    # the user agent has no stored cookies.
    # 1. User Agent -> Server
    #   POST /acme/login HTTP/1.1
    #   [form data]
    #   User identifies self via a form.
    # 2. Server -> User Agent
    #   HTTP/1.1 200 OK
    #   Set-Cookie2: Customer="WILE_E_COYOTE"; Version="1"; Path="/acme"
    #   Cookie reflects user's identity.
    my $res = HTTP::Response->new( 200, 'OK' );
    $res->header('Set-Cookie2' => q{Customer="WILE_E_COYOTE"; Version="1"; Path="/acme"});
    my $req = request_for('www.acme.com/acme/login', 'POST');
    # we can skip the form data as it's not necessary here
    $res->request($req);
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 1, '1.1-2: res: found the cookie');

    # 3-4
    # 3. User Agent -> Server
    #  POST /acme/pickitem HTTP/1.1
    #  Cookie: $Version="1"; Customer="WILE_E_COYOTE"; $Path="/acme"
    #  [form data]
    #  User selects an item for "shopping basket".
    # 4. Server -> User Agent
    #  HTTP/1.1 200 OK
    #  Set-Cookie2: Part_Number="Rocket_Launcher_0001"; Version="1"; Path="/acme"
    #  Shopping basket contains an item.
    $req = request_for('www.acme.com/acme/pickitem', 'POST');
    $jar->add_cookie_header($req);
    my $h = $req->header("Cookie"); # checking header contents is easier
    like($h, qr/Customer="?WILE_E_COYOTE"?/, '1.3-4: req: contains header');
    $res->header('Set-Cookie2' => q{Part_Number="Rocket_Launcher_0001"; Version="1"; Path="/acme"});
    $res->request($req);
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 2, '1.3-4: res: found the cookies');

    # 5-6
    # 5. User Agent -> Server
    #  POST /acme/shipping HTTP/1.1
    #  Cookie: $Version="1";
    #    Customer="WILE_E_COYOTE"; $Path="/acme";
    #    Part_Number="Rocket_Launcher_0001"; $Path="/acme"
    #  [form data]
    #  User selects shipping method from form.
    # 6. Server -> User Agent
    #  HTTP/1.1 200 OK
    #  Set-Cookie2: Shipping="FedEx"; Version="1"; Path="/acme"
    #  New cookie reflects shipping method.
    $req = request_for('www.acme.com/acme/shipping', 'POST');
    $jar->add_cookie_header($req);
    $h = $req->header("Cookie"); # checking header contents is easier
    like($h, qr/Customer="?WILE_E_COYOTE"?/, '1.5-6: req: contains cust');
    like($h, qr/Part_Number="?Rocket_Launcher_0001"?/, '1.5-6: req: contains part');
    $res->header('Set-Cookie2' => q{Shipping="FedEx"; Version="1"; Path="/acme"});
    $res->request($req);
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 3, '1.5-6: res: found the cookies');

    # 7-8
    # 7. User Agent -> Server
    #  POST /acme/process HTTP/1.1
    #  Cookie: $Version="1";
    #    Customer="WILE_E_COYOTE"; $Path="/acme";
    #    Part_Number="Rocket_Launcher_0001"; $Path="/acme";
    #    Shipping="FedEx"; $Path="/acme"
    #  [form data]
    #  User chooses to process order.
    # 8. Server -> User Agent
    #  HTTP/1.1 200 OK
    #  Transaction is complete.
    $req = request_for('www.acme.com/acme/process', 'POST');
    $jar->add_cookie_header($req);
    $h = $req->header("Cookie"); # checking header contents is easier
    like($h, qr/Customer="?WILE_E_COYOTE"?/, '1.7-8: req: contains cust');
    like($h, qr/Part_Number="?Rocket_Launcher_0001"?/, '1.7-8: req: contains part');
    like($h, qr/Shipping="?FedEx"?/, '1.7-8: req: contains shipping');
    $res = HTTP::Response->new( 200, 'OK' );
    $res->request($req);
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 3, '1.7-8: res: found the cookies');
}

# Example 2
#This example illustrates the effect of the Path attribute.  All
#   detail of request and response headers has been omitted.  Assume the
#   user agent has no stored cookies.
{
    $jar->clear();
    my $res = HTTP::Response->new( 200, 'OK' );
    # requests to /acme get rocket launcher
    $res->push_header('Set-Cookie2' => q{Part_Number="Rocket_Launcher_0001"; Version="1"; Path="/acme"});
    # requests to /acme/ammo will get rocket launcher and rocket
    $res->push_header('Set-Cookie2' => q{Part_Number="Riding_Rocket_0023"; Version="1"; Path="/acme/ammo"});
    # requests to /acme/anything_else will just get rocket launcher

    my $req = request_for('www.acme.com/acme/', 'POST');
    $res->request($req);
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 1, '2: acme: res: one cookie');

    $jar->clear();
    $req = request_for('www.acme.com/acme/ammo', 'POST');
    $res->request($req);
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 2, '2: acme/ammo: res: two cookies');

    $jar->clear();
    $req = request_for('www.acme.com/acme/parts', 'POST');
    $res->request($req);
    $jar->extract_cookies($res);
    is(count_cookies_for('www.acme.com'), 1, '2: acme/parts: res: one cookie');
}

sub count_cookies_for {
    my $host = shift;
    my $count = 0;
    $jar->scan(sub { $_[4] eq $host && $count++ });
    return $count;
}

sub request_for {
    my $uri = URI->new('http://'.shift);
    my $method = shift || 'GET';
    my $req = HTTP::Request->new($method => $uri);
    $req->header(Host => $uri->host_port);
    return $req;
}
