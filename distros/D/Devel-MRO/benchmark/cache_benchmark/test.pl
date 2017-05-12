#!perl -w
use strict;

use Benchmark qw(:all);

use mro_compat;

{
	package A;
	package B;
	package C;
	our @ISA = qw(A B);
	package D;
	our @ISA = qw(C);
}

print  "Benchmark of get_linear_isa() for 'direct' vs. 'cached'\n";
printf "Perl %vd on $^O\n";

print "Cache enabled\n";
cmpthese timethese -1 => {
	'mroc (direct)' => sub{
		my $isa_ref = mro_compat::get_linear_isa_dfs('D');
	},
	'mroc (cached)' => sub{
		my $isa_ref = mro_compat::get_linear_isa('D');
	},
};

print "\nCache disabled (i.e. the first access)\n";
cmpthese timethese -1 => {
	'mroc (direct)' => sub{
		mro_compat::method_changed_in('D');
		my $isa_ref = mro_compat::get_linear_isa_dfs('D');
	},
	'mroc (cached)' => sub{
		mro_compat::method_changed_in('D');
		my $isa_ref = mro_compat::get_linear_isa('D');
	},
};
