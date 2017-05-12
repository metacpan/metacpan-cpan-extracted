#!/usr/bin/perl -w

use strict;
use Test::More;

use Guard::Stats;

my $class = shift;

if (!$class) {
	print "# Usage: $0 <class::name>\n";
	print "# Check whether Guard::Stats may work with given class\n";
	exit 2;
};

plan tests => 8;

eval "require $class" or die "Failed to load $class: $@";

my $G0 = Guard::Stats->new;
my $G1 = Guard::Stats->new( guard_class => $class );

# Simple check: create, destroy
do {
	my $g0 = $G0->guard;
	my $g1 = $G1->guard;
	identic_ok($G1, $G0);
};
identic_ok($G1, $G0);

# More advanced check
do {
	my $g0 = $G0->guard;
	my $g1 = $G1->guard;

	$g0->end;
	$g1->end;
	identic_ok ( $G1, $G0 );

	my @warn;
	local $SIG{__WARN__} = sub { push @warn, shift };
	eval {
		$g1->end("Second time");
	};
	ok (scalar @warn, "Warning emitted");
	identic_ok ( $G1, $G0 );
};
identic_ok ( $G1, $G0 );

# end w/argument
do {
	my $g0 = $G0->guard;
	my $g1 = $G1->guard;

	$g0->end("foo");
	$g1->end("foo");

	identic_ok ( $G1, $G0 );
};
identic_ok ( $G1, $G0 );

sub identic_ok {
	my ($o1, $o0) = @_;

	is_deeply( $o1->get_stat, $o0->get_stat, "Identic")
		and return 1;

	diag "Expected: ", explian $o0->get_stat;
	diag "Got: ", explian $o1->get_stat;
	return;
};
