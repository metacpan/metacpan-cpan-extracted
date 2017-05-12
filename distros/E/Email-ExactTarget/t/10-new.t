#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;

use Email::ExactTarget;


# Create an object to communicate with Exact Target.
my $exact_target;
lives_ok(
	sub
	{
		$exact_target = Email::ExactTarget->new(
			'username'                => 'XXXXX',
			'password'                => 'XXXXX',
			'verbose'                 => 0,
			'unaccent'                => 1,
		);
	},
	'Instantiate a new Email::ExactTarget object.',
);

isa_ok(
	$exact_target,
	'Email::ExactTarget',
	'Object returned by Email::ExactTarget->new()',
);
