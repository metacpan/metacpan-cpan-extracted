use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use English qw( -no_match_vars );
use lib 'lib';
use lib 't';
use lib $Bin;
use lib "$Bin/../lib";

our $THIS_TEST_HAS_TESTS = 2;

plan( tests => $THIS_TEST_HAS_TESTS );

use Getopt::LL; # qw(getoptions);

@ARGV = qw(-t hello world -X);
my $ret;
eval { $ret = Getopt::LL::getoptions({ -t => "string" }) };

like($EVAL_ERROR, qr/Unknown argument: -X/,
    'bail on unknown argument'
);

ok(!$ret);
