#!perl
use FindBin qw($Bin);
use Test::More tests => 1;
use lib $Bin;
use MultiPackage;

MultiPackage::go();
MultiPackage::Sub::go();

ok(1);
