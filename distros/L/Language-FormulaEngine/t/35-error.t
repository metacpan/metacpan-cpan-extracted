#! /usr/bin/env perl
use Test2::V0 qw( ok is note diag object prop call match done_testing );
use Data::Dumper;
use Try::Tiny;
use Language::FormulaEngine;

my $msg= "Not an integer";
my @tests= (
	[ 'ErrNUM($msg)',
		object {
			prop blessed => 'Language::FormulaEngine::Error::ErrNUM';
			call message => $msg;
		},
	],
	[ 'ErrNUM->new($msg)',
		object {
			prop blessed => 'Language::FormulaEngine::Error::ErrNUM';
			call message => $msg;
		},
	],
	[ 'ErrNUM(message => $msg)',
		object {
			prop blessed => 'Language::FormulaEngine::Error::ErrNUM';
			call message => $msg;
		},
	],
	[ 'ErrNUM message => $msg',
		object {
			prop blessed => 'Language::FormulaEngine::Error::ErrNUM';
			call message => $msg;
		},
	],
	[ 'ErrNUM { message => $msg }',
		object {
			prop blessed => 'Language::FormulaEngine::Error::ErrNUM';
			call message => $msg;
		},
	],
	[ 'auto_wrap_error(do { eval { my $x; $$x } || $@ })',
		object {
			prop blessed => 'Language::FormulaEngine::Error::ErrNA';
		},
	],
);

for (0..$#tests) {
	my ($code, $check)= @{$tests[$_]};
	my $val= eval 'package test'.$_.'; use Language::FormulaEngine::Error ":all"; '.$code;
	defined $val or note $@;
	is( $val, $check, $code );
}

done_testing;
