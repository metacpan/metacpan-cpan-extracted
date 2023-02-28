#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Test::More;

use Math::Formula          ();
use Math::Formula::Context ();

my $expr = Math::Formula->new(test => 1);

my $b1 = MF::BOOLEAN->new(undef, 1 > 2);
is $b1->token, 'false', 'boolean from calculation, false';
is $b1->value, '0';

my $b2 = MF::BOOLEAN->new(undef, '');
is $b2->token, 'false';
is $b2->value, '0';

my $b3 = MF::BOOLEAN->new(undef, undef);
is $b3->token, 'false';
is $b3->value, '0';

my $b4 = MF::BOOLEAN->new(undef, 2 > 1);
is $b4->token, 'true', 'boolean from calculation, true';
is $b4->value, '1';

my $b5 = MF::BOOLEAN->new(undef, 42);
is $b5->token, 'true';
is $b5->value, '1';

### PREFIX operators

is_deeply $expr->_tokenize('true'),     [ MF::BOOLEAN->new('true') ];
is_deeply $expr->_tokenize('false'),    [ MF::BOOLEAN->new('false') ];

### INFIX operators

my @infix = (
	# Prefix operators
	[ false => 'not true'  ],
	[ true  => 'not false' ],

	# Infix operators
	[ true  => 'true  and true'  ],
	[ false => 'false and true'  ],
	[ false => 'true  and false' ],
	[ false => 'false and false' ],

	[ true  => 'true  or  true'  ],
	[ true  => 'false or  true'  ],
	[ true  => 'true  or  false' ],
	[ false => 'false or  false' ],

	[ false => 'true  xor true'  ],
	[ true  => 'false xor true'  ],
	[ true  => 'true  xor false' ],
	[ false => 'false xor false' ],

	[ false => 'false and true or false' ],

	# with cast
	[ true  => 'true and 1' ],
	[ false => 'true and 0' ],
	[ true  => '1 and 1' ],
	[ false => '0 and 0' ],
);

foreach (@infix)
{	my ($result, $rule) = @$_;

	$expr->_test($rule);
	is $expr->evaluate->token, $result, "$rule -> $result";
}

my $context = Math::Formula::Context->new(name => 'test');
is $context->run('not true')->token, 'false';
is $context->run('not false')->token, 'true';

done_testing;
