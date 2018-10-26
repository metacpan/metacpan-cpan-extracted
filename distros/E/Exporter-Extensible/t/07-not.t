#! /usr/bin/env perl
use strict;
use warnings;
no warnings 'once';
use Test::More;
use Scalar::Util 'weaken';

use_ok( 'Exporter::Extensible' ) or BAIL_OUT;

ok( eval q{
	package Example;
	$INC{'Example.pm'}=1;

	use Exporter::Extensible -exporter_setup => 1;
	export(qw( stat log log_debug epilogue ));
	sub stat {}
	sub log {}
	sub log_debug {}
	sub epilogue {}
	1;
}, 'declare Example' ) or diag $@;

no strict 'refs';

my @tests= (
	[ 'baseline',
		[':all'],
		[qw( stat log log_debug epilogue )]
	],
	[ 'exclude specific',
		[{ not => 'log' }, ':all'],
		[qw( stat log_debug epilogue )]
	],
	[ 'exclude specific, in-line',
		[':all', { -not => 'log' }],
		[qw( stat log_debug epilogue )]
	],
	[ 'exclude by regex',
		[{ not => qr/log/ }, ':all' ],
		[qw( stat )]
	],
	[ 'exclude by coderef',
		[{ not => sub { length($_) < 5 } }, ':all' ], 
		[qw( log_debug epilogue )]
	],
	[ 'exclude by multi',
		[{ not => [ sub { length($_) < 5 }, qr/^log/ ] }, ':all' ],
		[qw( epilogue )]
	],
);
my $i= 0;
for (@tests) {
	my ($name, $import_args, $export_list)= @$_;
	my $pkg= "CleanNamespace".$i++;
	Example->import_into($pkg, @$import_args);
	no strict 'refs';
	my @imported= sort keys %{$pkg.'::'};
	is_deeply( \@imported, [ sort @$export_list ], $name );
}

done_testing;
