#!perl

use strict;
use warnings;

use Test::More;

use HTTP::Cookies ();
use HTTP::Date ();
use HTTP::Request ();
use HTTP::Response ();


my $expiry_string = HTTP::Date::time2str( time + 86400 );
my $jar = HTTP::Cookies->new;

{
    local $TODO = 'Unexpected cookies stored';
    my $res = HTTP::Response->new( 200, 'OK' );
    my $req = request_for('www.exceptone.co.uk');
    $res->header( 'Set-Cookie' =>
        "security=fail; Domain=.co.uk; Expires=${expiry_string}" );
    $res->request($req);
    $jar->extract_cookies($res);
    is count_cookies_for('.co.uk'), 0, 'No .co.uk cookies stored in the jar';
}

{
    local $TODO = 'Unexpected cookies stored';
    my $req = request_for('www.google.co.uk');
    $jar->add_cookie_header($req);
    is $req->header('Cookie'), undef, 'No cookies sent to www.google.co.uk';
}

{
    my $req = request_for('www.google.com');
    $jar->add_cookie_header($req);
    is $req->header('Cookie'), undef, 'No cookies sent to www.google.com';
}

{
    local $TODO = 'Unexpected cookies stored';
    my $res = HTTP::Response->new( 200, 'OK' );
    my $req = request_for('www.example.com');
    $res->header( 'Set-Cookie' =>
        "dotcom=pwned; Domain=.com; Expires=${expiry_string}" );
    $res->request($req);
    $jar->extract_cookies($res);
    is count_cookies_for('.com'), 0, 'No .com cookies stored in the jar';
}

{
    local $TODO = 'Unexpected cookies stored';
    my $req = request_for('www.google.com');
    $jar->add_cookie_header($req);
    is $req->header('Cookie'), undef, 'No cookies sent to www.google.com';
}


sub count_cookies_for {
    my $host = shift;
    my $count = 0;
    $jar->scan( sub { $_[4] eq $host && $count++ });
    return $count;
}

sub request_for {
    my $host = shift;
    my $req = HTTP::Request->new( GET => "http://${host}/");
    $req->header( Host => $host );
    return $req;
}

done_testing();
