#! /usr/bin/env perl
use strict;
use warnings;
no warnings 'once';
use Test::More;

use_ok( 'Exporter::Extensible' ) or BAIL_OUT;

ok( eval q{
	package Example;
	$INC{'Example.pm'}=1;

	use Exporter::Extensible -exporter_setup => 0;
	our ($scalar, @array, %hash);
	sub code { 1 }
	our %EXPORT= (
		code => \&code,
		'$scalar' => \$scalar,
		'@array' => \@array,
		'%hash' => \%hash,
		-opt => [ "opt", 0 ],
	);
	our %EXPORT_TAGS= (
		group1 => [ 'code' ],
	);
	sub opt {
		no strict "refs";
		push @{ shift->{into}.'::opt_output' }, __PACKAGE__;
	}
	1;
}, 'declare Example' ) or diag $@;

ok( eval q{
	package Child1;
	$INC{'Child1.pm'}=1;
	
	use parent 'Example';
	our (@array, %hash);
	our %EXPORT= (
		'@array' => \@array,
		code_child1 => sub {},
	);
	our %EXPORT_TAGS= (
		group1 => [ 'code_child1' ],
	);
	sub code { 2 }
	sub opt {
		my $self= shift;
		no strict "refs";
		push @{ $self->{into}.'::opt_output' }, __PACKAGE__;
		$self->maybe::next::method(@_);
	}
	1;
}, 'declare Child1' ) or diag $@;

ok( eval q{
	package Child2;
	$INC{'Child2.pm'}=1;
	
	use parent 'Example';
	our (@array, %hash);
	our %EXPORT= (
		'@array' => \@array,
		'code_child2' => sub {},
	);
	our %EXPORT_TAGS= (
		group1 => [ 'code_child2' ],
		default => [ 'code_child2' ],
	);
	sub code { 3 }
	sub opt {
		my $self= shift;
		no strict "refs";
		push @{ $self->{into}.'::opt_output' }, __PACKAGE__;
		$self->maybe::next::method(@_);
	}
	1;
}, 'declare Child2' ) or diag $@;

ok( eval q{
	package MultInherit;
	$INC{'MultInherit.pm'}=1;
	
	use parent 'Child1', 'Child2';
	our @array;
	our %EXPORT= (
		'@array' => \@array
	);
	sub code { 4 }
	sub opt {
		my $self= shift;
		no strict "refs";
		push @{ $self->{into}.'::opt_output' }, __PACKAGE__;
		$self->maybe::next::method(@_);
	}
	1;
}, 'declare MultInherit' ) or diag $@;

subtest reexported_var => \&test_reexported_var;
sub test_reexported_var {
	# The array is defined in each of the packages.  It should not inherit at all, since each re-defined it.
	
	Example->import_into('DestPkg', { replace => 1 }, '@array');
	is( *DestPkg::array{ARRAY}, *Example::array{ARRAY}, "Is Example's array" );
	isnt( *DestPkg::array{ARRAY}, *Child1::array{ARRAY}, "Isn't Child1's array" );

	Child1->import_into('DestPkg', { replace => 1 }, '@array');
	is( *DestPkg::array{ARRAY}, *Child1::array{ARRAY}, "Is Child1's array" );
	isnt( *DestPkg::array{ARRAY}, *Example::array{ARRAY}, "Isn't Example's array" );
	
	MultInherit->import_into('DestPkg', { replace => 1 }, '@array');
	is( *DestPkg::array{ARRAY}, *MultInherit::array{ARRAY}, "Is MultInherit's array" );
	isnt( *DestPkg::array{ARRAY}, *Child1::array{ARRAY}, "Isn't Child1's array" );
	isnt( *DestPkg::array{ARRAY}, *Child2::array{ARRAY}, "Isn't Child2's array" );
	isnt( *DestPkg::array{ARRAY}, *Example::array{ARRAY}, "Isn't Example's array" );

	done_testing;
}

subtest inherited_var => \&test_inherited_var;
sub test_inherited_var {
	# The hash is defined in each package, but only Example exported it.
	# (the exporter should not be searching package hierarchy for variables,
	#  only searching the hierarchy of %EXPORT vars)
	for (qw( Child1 Child2 MultInherit )) {
		$_->import_into('DestPkg', '%hash');
		is( *DestPkg::hash{HASH}, *Example::hash{HASH}, "Is Example's hash" );
		no strict 'refs';
		isnt( *DestPkg::hash{HASH}, *{$_.'::hash'}{HASH}, "Isn't $_\'s hash" );
		undef *DestPkg::hash;
	}
	done_testing;
}

subtest inherited_sub => \&test_inherited_sub;
sub test_inherited_sub {
	# Like %hash above, but testing coderefs
	for (qw( Child1 Child2 MultInherit )) {
		$_->import_into('DestPkg', 'code');
		is( DestPkg->can('code'), Example->can('code'), "Is Example's sub" );
		isnt( DestPkg->can('code'), $_->can('code'), "Isn't $_\'s sub" );
		undef *DestPkg::code;
	}
	done_testing;
}

subtest inherited_option => \&test_inherited_option;
sub test_inherited_option {
	# Option implementations actually get some inheritance behavior.
	# Only Exporter defined the option, but it should invoke MultInherit's overridden version.
	MultInherit->import_into('DestPkg', -opt);
	is_deeply(
		\@DestPkg::opt_output,
		[ 'MultInherit', 'Child1', 'Child2', 'Example' ],
		'option called ancestors in c3 order'
	);
	done_testing;
}

subtest inherited_tags => \&test_inherited_tags;
sub test_inherited_tags {
	my @tests= (
		[ Example => group1 => [ 'code' ] ],
		[ Child1  => group1 => [ 'code', 'code_child1' ] ],
		[ Child2  => group1 => [ 'code', 'code_child2' ] ],
		[ MultInherit => group1 => [ 'code', 'code_child1', 'code_child2' ] ],
		[ MultInherit => all    => [ '$scalar', '@array', '%hash', 'code', 'code_child1', 'code_child2' ] ],
		[ MultInherit => default => [ 'code_child2' ] ],
	);
	for (@tests) {
		my ($pkg, $tag, $expected)= @$_;
		is_deeply( [ sort @{$pkg->exporter_get_tag($tag)} ], [ sort @$expected ], "$pkg\'s $tag" );
	}
	done_testing;
}

done_testing;
