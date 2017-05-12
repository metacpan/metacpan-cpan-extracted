#!perl

use Test::More;
use Gcis::Client;
use Data::Dumper;
use v5.14;

unless ($ENV{GCIS_DEV_URL}) {
    plan skip_all => "set GCIS_DEV_URL to run live tests";
}
plan tests => 1;

my $c = Gcis::Client->connect(url => $ENV{GCIS_DEV_URL});

my $ok = $c->get("/login");

is $ok->{login}, 'ok', 'login ok';


