#!perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }

END {print "not ok 1\n" unless $loaded;}

use IO::Extended ':all';

use strict;

use warnings;

#use diagnostics;

our $loaded = 1;

print "ok 1\n";

	for( 0..10 )
	{
		printf "set tabsize = %s (%s)\n", tabs( $_ ), indstr();

		for( 0..5 )
		{
			printfln 'set indentation = %s ( x tabsize = %d chars)', ind( $_ ), length indstr();

			println 'Hello, this is println calling..';

			printfln 'Hello, this is %s calling..', 'printfln';

			print my $out = sprintfln 'Hello, this is %s calling..', 'sprintfln';
		}

		while(indb())
		{
			printfln 'set indentation = %s ( x tabsize = %d chars)', ind(), length indstr();

			println 'Hello, this is println calling..';

			printfln 'Hello, this is %s calling..', 'printfln';

			print my $out = sprintfln 'Hello, this is %s calling..', 'sprintfln';
		}
	}

warnfln "We now expect an Hurray... at the beginning of the line";

warnfln "%s This is a warnfln test %S showing the %%S feature.", 'Hurray...', 'warning';

$_ = 'ALL RIGHT';

println;

eval
{
    diefln 'OK - and with diefln we wont live %s.', 'forever';
}

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

