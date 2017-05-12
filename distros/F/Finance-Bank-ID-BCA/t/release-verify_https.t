#!perl

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for release candidate testing');
    }
    if ($ENV{OFFLINE}) {
        require Test::More;
        Test::More::plan(skip_all => 'offline');
    }
}

use strict;
use Test::More tests => 3-1;

use Finance::Bank::ID::BCA;

my $ibank = Finance::Bank::ID::BCA->new(verify_https => 1);
$ibank->_set_default_mech;

$ibank->mech->get($ibank->site);
ok($ibank->mech->success, 'normal request succeed');

# https_ca_dir always set by WWW::Mechanize?
#{
#    local $ibank->mech->{https_ca_dir};
#    my $req = HTTP::Request->new(GET => $ibank->site);
#    my $resp = $ibank->mech->request($req);
#    like($resp->headers_as_string,
#         qr/^Client-SSL-Warning: Peer certificate not verified/m,
#         'request has SSL warning because https_ca_dir unset');
#}

$ibank->mech->{https_host} = "example.com";
eval { $ibank->mech->get($ibank->site) };
like($@, qr/Bad SSL certificate subject/, 'request failed because https_host doesnt match');
