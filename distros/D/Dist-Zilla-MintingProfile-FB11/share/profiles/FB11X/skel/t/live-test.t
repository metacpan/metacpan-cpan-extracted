#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Mojo::DOM;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/TestApp/i, 'see if it has our text');

$mech->content_like(qr/Access denied/i, 'check not logged in');
$mech->submit_form_ok({
    with_fields => {
        username => 'fb11admin',
        password => 'password',
        remember => 'remember',
    },
}, "Submit login form");

sub get_dom {
    my ($mech) = @_;
    Mojo::DOM->new($mech->content)
}

do {
    ok( my $main_content = get_dom($mech)->at('.fb11-main-content') );
    like($main_content->at('h1')->all_text, qr/Welcome to TestApp/i, 'Looks like we logged in OK');
};


done_testing;
