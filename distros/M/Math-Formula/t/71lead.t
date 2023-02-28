#!/usr/bin/env perl
# test ::Context::new(lead_expression)
  
use warnings;
use strict;
use utf8;

use Math::Formula          ();
use Math::Formula::Context ();
use Test::More;

#!!! All other tests use the lead_expression eq '' options, so we only
#!!! need to test the alternative approach.

my $c1 = Math::Formula::Context->new(name => 'test', lead_expressions => '=');

$c1->add({
	person  => 'Larry',
	awake   => '=gosleep - wakeup',
	wakeup  => '=07:00:00',
	gosleep => [ '23:30:00', returns => 'MF::TIME' ],
});

# Got a string?

my $s1 = $c1->formula('person');
ok defined $s1, 'Got the string';
is $s1->name, 'person';

my $e1 = $s1->expression;
isa_ok $e1, 'MF::STRING', '... is a STRING';

my $n1 = $s1->evaluate;
isa_ok $n1, 'MF::STRING', '... evals to STRING';

is $n1->token, '"Larry"', '... token with dquotes';
is $n1->value, 'Larry', '... value without dquotes';

# Math still working?

my $run1 = $c1->evaluate('awake');
ok defined $run1, 'run math';
isa_ok $run1, 'MF::DURATION';
is $run1->token, 'PT16H30M0S';

done_testing;
