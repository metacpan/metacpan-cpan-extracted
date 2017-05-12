# check that the module loads correctly and methods are available

use strict;
use warnings;
use Test::More qw(no_plan);

our $ok;
BEGIN {
	our $ok = use_ok('Getopt::Helpful');
}

SKIP: {
	my @methods = qw(
		Get
		Get_from
		ordered
		opts
		help_table
		help_string
		builtins
		usage
		spec_parse
		);
	$ok or skip('could not load', 2 + scalar(@methods));
	my $hopt = Getopt::Helpful->new();
	ok($hopt, 'constructor');
	isa_ok($hopt, 'Getopt::Helpful', 'class') or
		skip('constructor ack', scalar(@methods));
	foreach my $method (@methods) {
		ok($hopt->can($method), "can $method");
	}
}



diag( "Testing Getopt::Helpful $Getopt::Helpful::VERSION, Perl $], $^X" );

# vi:filetype=perl
