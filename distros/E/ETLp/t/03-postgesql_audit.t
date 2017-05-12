#!perl
use strict;
use Test::More;
#use ETLp;
use FindBin qw($Bin);
use lib "$Bin/lib";
use ETLp::Test::Audit;
use ETLp::Config;

if (!eval "require DBD::Pg") {
    plan skip_all => 'DBD::Pg not installed';
} elsif (!($ENV{PG_USER} && $ENV{PG_DSN})) {
    plan skip_all =>
'Environment variables PG_USER, and PG_DSN are not set. PG_PASS is optional';
} 

$ENV{USER} = $ENV{PG_USER};
$ENV{PASS} = $ENV{PG_PASS} if $ENV{PG_PASS};
$ENV{DSN}  = $ENV{PG_DSN};
        
ETLp::Test::Audit->runtests;
