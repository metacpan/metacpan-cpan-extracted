use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use English qw( -no_match_vars );

use lib 'lib';
use lib $Bin;
use lib "$Bin/../lib";

our $THIS_TEST_HAS_TESTS  = 4;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );

use TestClass;

eval 'use TestClass qw(notExported)';
ok( $EVAL_ERROR, 'bail on not exported sub' );

eval 'use TestClass qw(hello)';
ok(!$EVAL_ERROR, 'hello was exported' );

my  $hello = do { eval 'use TestClass qw(hello); hello()' };
is( $hello, 'hello world' );

do  { eval 'use TestClass qw(notExported); notExported()' };
like( $EVAL_ERROR, qr/TestClass does not export notExported/ );
