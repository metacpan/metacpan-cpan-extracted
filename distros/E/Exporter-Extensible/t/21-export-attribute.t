#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util 'weaken';

use_ok( 'Exporter::Extensible' ) or BAIL_OUT;

my @tests= (
	[ 'export a sub',
		'sub alpha :Export {}',
		q{ is_deeply(\%Example::EXPORT, { alpha => \&Example::alpha }) }
	],
	[ 'export a sub in groups',
		'sub alpha :Export( :group1 ) {}',
		q{ is_deeply(\%Example::EXPORT, { alpha => \&Example::alpha }) },
		q{ is_deeply(\%Example::EXPORT_TAGS, { group1 => [qw( alpha )] }) }
	],
	[ 'export sub with alt name with groups',
		'sub alpha :Export( :group2 beta :group3 ) {}',
		q{ is_deeply(\%Example::EXPORT, { beta => \&Example::alpha }) },
		q{ is_deeply(\%Example::EXPORT_TAGS, { group2 => ["beta"], group3 => ["beta"] }) }
	],
	[ 'export multiple sub aliases in multiple groups',
		'sub alpha :Export( :group1 alpha beta :group2 ) {}',
		q{ is_deeply(\%Example::EXPORT, { alpha => \&Example::alpha, beta => \&Example::alpha }) },
		q{ is_deeply(\%Example::EXPORT_TAGS, { group1 => ["alpha","beta"], group2 => ["alpha","beta"] }) }
	],
	[ 'multiple exports of same sub',
		'sub alpha :Export( alpha :group1 ) Export(beta :group2) {}',
		q{ is_deeply(\%Example::EXPORT, { alpha => \&Example::alpha, beta => \&Example::alpha }) },
		q{ is_deeply(\%Example::EXPORT_TAGS, { group1 => ["alpha"], group2 => ["beta"] }) }
	],
	[ 'export a generator',
		'sub _generate_alpha :Export(=) {}',
		q{ is_deeply(\%Example::EXPORT, { alpha => '_generate_alpha' }) },
	],
	[ 'export a generator of scalar',
		'sub _generateScalar_alpha :Export(=$) {}',
		q{ is_deeply(\%Example::EXPORT, { '$alpha' => '_generateScalar_alpha' }) },
	],
	[ 'export a generator of array',
		'sub _generateARRAY_alpha :Export(=@) {}',
		q{ is_deeply(\%Example::EXPORT, { '@alpha' => '_generateARRAY_alpha' }) },
	],
	[ 'export a generator of array',
		'sub alpha :Export(=@) {}',
		q{is_deeply(\%Example::EXPORT, { '@alpha' => 'alpha' })},
	],
	[ 'export a generator of different name',
		'sub build_alpha :Export(=@alpha) {}',
		q{is_deeply(\%Example::EXPORT, { '@alpha' => 'build_alpha' })},
	],
	[ 'export a generator of different name having generator prefix',
		'sub _generateScalar_alpha :Export(=$foo) {}',
		q{is_deeply(\%Example::EXPORT, { '$foo' => '_generateScalar_alpha' })},
	],
	[ 'export a generator and its generated thing',
		'sub _generate_alpha :Export(generate_alpha =@alpha) {}',
		q{is_deeply(\%Example::EXPORT,
			{ 'generate_alpha' => \&Example::_generate_alpha,
			  '@alpha'         => '_generate_alpha'
			} )
		}
	],
	[ 'export an option',
		'sub init_things :Export(-) {}',
		q{ is_deeply(\%Example::EXPORT, { -init_things => 'init_things' }) },
	],
	[ 'export an option with args',
		'sub init_things :Export(-(3)) {}',
		q{ is( ref $Example::EXPORT{'-init_things'}, 'CODE') },
	],
	[ 'export an option with optional arg',
		'sub init_things :Export(-(?)) {}',
		q{ is( ref $Example::EXPORT{'-init_things'}, 'CODE') },
	],
	[ 'export an option with wildcard',
		'sub init_things :Export(-(*)) {}',
		q{ is( ref $Example::EXPORT{'-init_things'}, 'CODE') },
	],
);
for (@tests) {
	my ($name, $code, $expected, $expected_tags)= @$_;
	# clean out namespace
	{ no strict 'refs'; %{'Example::'}= (); }
	# eval the sub and attributes
	ok( eval <<END, "eval - $name" ) or diag "Failed to eval $code: $@";
		package Example;
		use Exporter::Extensible -exporter_setup => 0;
		$code;
		1
END
	# eval the test
	eval $expected
		or diag explain eval '\%Example::EXPORT';
	if (defined $expected_tags) {
		eval $expected_tags
			or diag explain eval '\%Example::EXPORT_TAGS';
	}
}

done_testing;
