use v5.10.0;
use lib 't/lib';
use strict;
use warnings;
use Hailo::Test;
use Test::More tests => 552;

my $test = Hailo::Test->new(
    storage => "SQLite",
);
$test->test_badger;
