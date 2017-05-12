#!perl
use strict;
use Test::More;
#use ETLp;
use FindBin qw($Bin);
use lib "$Bin/lib";
use ETLp::Test::Audit;
use ETLp::Config;

if (!eval "require DBD::mysql") {
    plan skip_all => 'DBD::mysql not installed';
} elsif (!($ENV{MYSQL_USER} && $ENV{MYSQL_DSN})) {
    plan skip_all =>
'Environment variables MYSQL_USER, and MYSQL_DSN are not set. MYSQL_PASS is optional';
} 

$ENV{USER} = $ENV{MYSQL_USER};
$ENV{PASS} = $ENV{MYSQL_PASS} if $ENV{MYSQL_PASS};
$ENV{DSN}  = $ENV{MYSQL_DSN};
        
ETLp::Test::Audit->runtests;
