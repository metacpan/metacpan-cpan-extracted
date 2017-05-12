#!perl -w

use strict;
use Test::More tests => 19;

BEGIN{
	package Devel::MRO;
	use XSLoader;
	XSLoader::load(__PACKAGE__);

	use Exporter;
	our @ISA    = qw(Exporter);
	our @EXPORT = qw(mro_get_linear_isa mro_method_changed_in mro_get_pkg_gen);
}
use Devel::MRO;

require mro if $] >= 5.011_000;

{
	package A;
	package B;
	our @ISA = qw(A);
	package C;
	our @ISA = qw(A);
	package D;
	our @ISA = qw(B C);

	package E;
	our @ISA = qw(B C);

	package F;
	our @ISA = qw(E);
}

foreach my $class (qw(A B C D E F)){
	is_deeply mro_get_linear_isa($class), mro::get_linear_isa($class), "mro_get_linear_isa($class)";
	like mro_get_pkg_gen($class), qr/\A \d+ \z/xms, 'mro_get_pkg_gen';

	ok eval{ mro_method_changed_in($class); 1 }, 'mro_method_changed_in';# How to test this behavior?
}

@F::ISA = qw(A);
is_deeply mro_get_linear_isa('F'), [qw(F A)], 'after @ISA changed';
