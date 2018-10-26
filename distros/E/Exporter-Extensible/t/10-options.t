#! /usr/bin/env perl
use strict;
use warnings;
no warnings 'once', 'redefine';
use Test::More;
use Scalar::Util 'weaken';

use_ok( 'Exporter::Extensible' ) or BAIL_OUT;

my @events;
ok( eval q{
	package Example;
	$INC{'Example.pm'}=1;

	use Exporter::Extensible -exporter_setup => 1;
	our %EXPORT= (
		-alpha => [ 'alpha', 0 ],
		-beta  => [ 'beta',  1 ],
		-gamma => [ 'gamma', '?' ],
		-delta => [ 'delta', '*' ],
	);
	sub exporter_install {
		push @events, 'install';
		shift->SUPER::exporter_install(@_);
	}
	
	sub alpha {
		my $self= shift;
		@_ == 0 or die "Unexpected arguments to 'alpha'";
		push @events, 'alpha';
	}
	sub beta {
		my ($self, $arg1)= (shift, shift);
		@_ == 0 or die "Unexpected arguments to 'beta'";
		push @events, 'beta';
	}
	sub gamma {
		my ($self, $maybe_arg)= (shift, shift);
		@_ == 0 or die "Unexpected arguments to 'gamma'";
		push @events, 'gamma';
		if ($maybe_arg) {
			push @events, $maybe_arg->{event};
		}
		$self->exporter_also_import('-alpha');
	}
	sub delta {
		my ($self, @all_args)= @_;
		main::note "Delta Sees ".join(' ', @all_args);
		push @events, 'delta';
		my $n= 0;
		for (@all_args) {
			++$n;
			last if $_ eq 'd';
		}
		return $n;
	}
	1;
}, 'declare Example' ) or diag $@;

my @tests= (
	[
		[qw( -delta )],
		[qw( delta install )],
	],
	[
		[qw( -alpha -delta )],
		[qw( alpha delta install )],
	],
	[
		[qw( -beta -delta )],
		[qw( beta install )],
	],
	[
		[qw( -gamma )],
		[qw( gamma alpha install )],
	],
	[
		[ -gamma => { event => 'x' } ],
		[qw( gamma x alpha install )],
	],
	[
		[qw( -gamma -delta )],
		[qw( gamma delta install )],
	],
	[
		[qw( -delta -alpha -beta -gamma 1 2 3 4 5 d )],
		[qw( delta install )],
	]
);

my $n= 0;
for (@tests) {
	my ($args, $events)= @$_;
	@events= ();
	Example->import_into("Test::_Namespace".$n++, @$args);
	is_deeply( \@events, $events, join(' ', 'import', @$args) );
}

done_testing;
