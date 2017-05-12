#!perl -w
use strict;

use Benchmark qw(:all);

use MRO::Compat;
{
	package Devel::MRO;
	use XSLoader;
	XSLoader::load(__PACKAGE__);
}

{
	package A;
	package B;
	package C;
	our @ISA = qw(A B);
	package D;
	our @ISA = qw(C);
}

print  "Benchmark for mro::get_linear_isa() vs. mro_get_linear_isa() in mro_compat.h\n";
printf "Perl %vd on $^O\n";

cmpthese timethese -1 => {
	'mro::' => sub{
		my $isa_ref = mro::get_linear_isa('D');
	},
	'mro_compat' => sub{
		my $isa_ref = Devel::MRO::mro_get_linear_isa('D');
	},
};
