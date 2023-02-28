#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

my $expr = Math::Formula->new(test => 1);

sub try_pattern($$)
{   my ($pattern, $expect) = @_;
	my $regexp  = MF::PATTERN::_to_regexp($pattern);
	is ref $regexp, 'Regexp', "pattern '$pattern'";
	is $regexp, $expect;
}

try_pattern '',   '(?^u:^$)';
try_pattern 'a',  '(?^u:^a$)';
try_pattern 'ab', '(?^u:^ab$)';

try_pattern '*',  '(?^u:^.*$)';
try_pattern '\*', '(?^u:^\*$)';

try_pattern '?',  '(?^u:^.$)';
try_pattern '\?', '(?^u:^\?$)';

try_pattern '[a-z]', '(?^u:^[a-z]$)';
try_pattern '[!a-z!]', '(?^u:^[^a-z\!]$)';
try_pattern '[{}]', '(?^u:^[{}]$)';

try_pattern 'b,c,d', '(?^u:^b\,c\,d$)';
try_pattern 'a{b,c,d}e', '(?^u:^a(?:b|c|d)e$)';
try_pattern '{b,c,d}', '(?^u:^(?:b|c|d)$)';

### INFIX operators

my @infix = (
	[ true  => '"pict.jpg"   like "*.jpg"' ],
	[ false => '"pict.jpg" unlike "*.jpg"' ],
	[ false => '"pict.jpg"   like "*.png"' ],
	[ true  => '"pict.jpg" unlike "*.png"' ],
	[ true  => '"pict.jpg"   like "*.{gif,png,jpg}"' ],
	[ false => '"pict.jpg" unlike "*.{gif,png,jpg}"' ],
);

foreach (@infix)
{	my ($result, $rule) = @$_;

	$expr->_test($rule);
	my $eval = $expr->evaluate;
	is $eval->token, $result, "$rule -> $result";
	isa_ok $eval, 'MF::BOOLEAN';
}

### like with MF::REGEXP
# this can happen when the result of a CODE expression is guessed
# wrongly.

my $regexp = MF::REGEXP->new(undef, qr/b/);
my $string = MF::STRING->new(undef, "abc");

is $string->infix('like', $regexp)->token, 'true', 'like regexp';
is $string->infix('unlike', $regexp)->token, 'false', 'unlike regexp';

done_testing;
