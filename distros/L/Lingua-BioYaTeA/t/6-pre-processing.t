# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1-corpusLoading.t'

#########################

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 3;

BEGIN {use_ok('Lingua::BioYaTeA::PreProcessing') ;}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Instantiation of abstract subclass

my $preProc = Lingua::BioYaTeA::PreProcessing->new();
ok( defined($preProc) && ref($preProc) eq 'Lingua::BioYaTeA::PreProcessing', 'new() and load* work');
my $fh;
open($fh, ">t/example_output_preprocessing-new.ttg") or ($fh = *STDERR);
ok($preProc->process_file("t/example_input_preprocessing.ttg", $fh), 'process file works');
close($fh);

unlink("t/example_output_preprocessing-new.ttg");
