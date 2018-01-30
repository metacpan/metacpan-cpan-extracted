#!/usr/bin/env perl
# Try reporting of misisng parameter.

use warnings;
use strict;
use lib 'lib', '../lib';

use Test::More;

use Log::Report;   # no domains, no translator
use Scalar::Util qw/refaddr/;

dispatcher close => 'default';

my $a = __x"testA {a}", a => undef;
isa_ok($a, 'Log::Report::Message');

is $a->toString, "testA undef";

### warn on normal message
my $linenr  = __LINE__ + 1;
my $b       = __x"testB {b}";

my $bs      = try { $b->toString };
(my $warning) = $@->exceptions;
isa_ok $warning, 'Log::Report::Exception';

is $bs, "testB undef";
is $warning->reason, 'WARNING';
is $warning->message,
   "Missing key 'b' in format 'testB {b}', file $0 line $linenr";

### warn on exception
$linenr     = __LINE__ + 1;
try { error __x"testC {c}" };
my $error   = $@->wasFatal;

my $cs      = try { $error->toString };
($warning)  = $@->exceptions;
isa_ok $warning, 'Log::Report::Exception';

is $cs, "error: testC undef\n";
is $warning->reason, 'WARNING';
is $warning->message,
   "Missing key 'c' in format 'testC {c}', file $0 line $linenr";

done_testing;
