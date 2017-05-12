#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/AppKit TestApp/i, 'see if it has our text');

$mech->content_like(qr/Access denied/i, 'check not logged in');
$mech->submit_form(form_number => 1,
    fields => {
        username => 'appkitadmin',
        password => 'password',
        remember => 'remember',
    },
);
$mech->content_like(qr/Welcome to AppKit TestApp/i, 'Check login good');


done_testing;
