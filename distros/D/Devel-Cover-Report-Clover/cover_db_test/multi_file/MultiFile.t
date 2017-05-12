#!perl
use FindBin qw($Bin);
use Test::More tests => 1;
use lib "$Bin";
use MultiFile;
use MultiFile::First;
use MultiFile::Second;

my $ret = MultiFile::go(); # 8

is($ret,8,"call three functions");
