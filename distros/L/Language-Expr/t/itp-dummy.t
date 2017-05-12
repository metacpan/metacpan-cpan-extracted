#!perl

use strict;
use warnings;

use Language::Expr;
use POSIX;
use Test::Exception;
use Test::More;

my $itp = Language::Expr->new->get_interpreter('dummy');
lives_ok { $itp->eval('1 + 1') };

DONE_TESTING:
done_testing;
