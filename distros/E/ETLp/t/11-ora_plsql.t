#!perl
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";
use ETLp::Test::OraProc;

if (!eval "require DBD::Oracle") {
    plan skip_all => 'DBD::Oracle not installed';
} elsif (!($ENV{ORA_USER} && $ENV{ORA_PASS} && $ENV{ORA_DSN})) {
    plan skip_all =>
'Environment variables ORA_USER and ORA_PASS are not set. ORA_DB is optional';
}

$ENV{USER} = $ENV{ORA_USER};
$ENV{PASS} = $ENV{ORA_PASS};
$ENV{DSN}  = $ENV{ORA_DSN};

ETLp::Test::OraProc->runtests;
