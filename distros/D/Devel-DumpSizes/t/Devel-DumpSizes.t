# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Devel-DumpSizes.t'

#########################

use Test::More tests => 2;
BEGIN { use_ok('Devel::DumpSizes') };

#########################

our $test_global_var = "hello world";

sub test_dump_size_1 {
	my $test_var = "hello world\n";
	eval { &Devel::DumpSizes::dump_sizes() };
	if ( $@ ) { warn $@, "\n"; return 0; }
	return 1;
}

ok ( &test_dump_size_1 );
