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
	[ 'export a generator',
		'sub _generate_alpha :Export(=) {}',
		{ alpha => \\'_generate_alpha' },
	],
	[ 'export a generator of scalar',
		'sub _generateScalar_alpha :Export(=$) {}',
		{ '$alpha' => \\'_generateScalar_alpha' },
	],
	[ 'export a generator of different name',
		'sub build_alpha :Export(=@alpha) {}',
		{ '@alpha' => \\'build_alpha' },
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
