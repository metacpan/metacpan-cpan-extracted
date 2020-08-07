#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util 'weaken';

use_ok( 'Exporter::Extensible' ) or BAIL_OUT;

my @tests= (
	[ 'export a sub',
		'sub alpha :Export {}',
		{ alpha => '\&Example::alpha' }
	],
	[ 'export a sub in groups',
		'sub alpha :Export( :group1 ) {}',
		{ alpha => '\&Example::alpha' },
		{ 'group1' => [qw( alpha )] },
	],
	[ 'export sub with alt name with groups',
		'sub alpha :Export( :group2 beta :group3 ) {}',
		{ beta => '\&Example::alpha' },
		{ 'group1' => ['beta'], 'group2' => ['beta'] },
	],
	[ 'export multiple sub aliases in multiple groups',
		'sub alpha :Export( :group1 alpha beta :group1 ) {}',
		{ alpha => '\&Example::alpha', beta => '\&Example::alpha' },
		{ group1 => ['alpha','beta'], group2 => ['alpha','beta'] }
	],
	[ 'multiple exports of same sub',
		'sub alpha :Export( alpha :group1 ) Export(beta :group2) {}',
		{ alpha => '\&Example::alpha', beta => '\&Example::alpha' },
		{ group1 => ['alpha'], group2 => ['beta'] }
	],
	[ 'export a generator',
		'sub _generate_alpha :Export(=) {}',
		{ alpha => \\'_generate_alpha' },
	],
	[ 'export a generator of scalar',
		'sub _generateScalar_alpha :Export(=$) {}',
		{ '$alpha' => \\'_generateScalar_alpha' },
	],
	[ 'export a generator of array',
		'sub _generateARRAY_alpha :Export(=@) {}',
		{ '@alpha' => \\'_generateARRAY_alpha' },
	],
	[ 'export a generator of array',
		'sub alpha :Export(=@) {}',
		{ '@alpha' => \\'alpha' },
	],
	[ 'export a generator of different name',
		'sub build_alpha :Export(=@alpha) {}',
		{ '@alpha' => \\'build_alpha' },
	],
	[ 'export a generator of different name having generator prefix',
		'sub _generateScalar_alpha :Export(=$foo) {}',
		{ '$foo' => \\'_generateScalar_alpha' },
	],
	[ 'export a generator and its generated thing',
		'sub _generate_alpha :Export(generate_alpha =@alpha) {}',
		{ 'generate_alpha' => '\&Example::_generate_alpha',
		  '@alpha'         => \\'_generate_alpha'
		},
	],
	[ 'export an option',
		'sub init_things :Export(-) {}',
		{ '-init_things' => [ 'init_things', 0 ] },
	],
	[ 'export an option with args',
		'sub init_things :Export(-(3)) {}',
		{ '-init_things' => [ 'init_things', 3 ] },
	],
	[ 'export an option with wildcard',
		'sub init_things :Export(-(*)) {}',
		{ '-init_things' => [ 'init_things', '*' ] },
	],
);
for (@tests) {
	my ($name, $code, $expected, $expected_tags)= @$_;
	# clean out namespace
	{ no strict 'refs'; %{'Example::'}= (); }
	ok( eval <<END, "eval - $name" ) or diag "Failed to eval $code: $@";
		package Example;
		use Exporter::Extensible -exporter_setup => 0;
		$code;
		1
END
	# eval bits of $expected which can only be known after the previous eval
	$_= eval $_ or die $@ for grep !ref, values %$expected;
	# then compare it.  need to eval these too since %EXPORT gets re-created each iter
	is_deeply( eval '\%Example::EXPORT', $expected, $name )
		or diag explain eval '\%Example::EXPORT';
}

done_testing;
