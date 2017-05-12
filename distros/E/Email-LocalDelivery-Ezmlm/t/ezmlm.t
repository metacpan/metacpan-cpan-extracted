#!perl -w
use strict;
use Test::More tests => 2;
use Email::LocalDelivery;

ok( Email::LocalDelivery->deliver("I am the eggplant" => 't/ezmlm//'), "delivery" );
ok( -e "t/ezmlm/archive/0/01", "file is there" );
