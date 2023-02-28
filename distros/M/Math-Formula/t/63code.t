#!/usr/bin/env perl
# Test have your own code in the expression
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

use_ok 'Math::Formula::Context';

my $flag = 4;

sub own_code
{   my ($context, $formula, %other) = @_;

	my $expect_flag = $other{flag};
	ok defined $expect_flag, "call $expect_flag";
	is $flag, $expect_flag, '... encosed';

	isa_ok $context, 'Math::Formula::Context', '...';
	isa_ok $formula, 'Math::Formula', '...';

	my $int = MF::INTEGER->new(undef, $flag);
	isa_ok $int, 'MF::INTEGER';
	$int;
}

my $expr = Math::Formula->new(test => \&own_code);
ok defined $expr, 'created expression with code';
isa_ok $expr->expression, 'CODE';

my $context = Math::Formula::Context->new(name => 'test');
my $result1 = $expr->evaluate($context, expect => 'MF::INTEGER', flag => 4 );
isa_ok $result1, 'MF::INTEGER';
is $result1->value, '4';

$flag = 5;
my $result2 = $expr->evaluate($context, expect => 'MF::FLOAT', flag => 5 );
isa_ok $result2, 'MF::FLOAT';
is $result2->token, '5.0';

done_testing;
