# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1-corpusLoading.t'

#########################

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 5;

BEGIN {use_ok('Lingua::BioYaTeA::PostProcessing') ;}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Instantiation of abstract subclass

my %options = ('configuration' => 't/bioyatea/post-processing-filtering-test.conf', 
	       'input-file' => 't/sampleEN-bioyatea-out.xml', 
	       'output-file' => 't/sampleEN-bioyatea-out-pp.xml',
	       'tmp-dir' => 't',
    );

my $postProc = Lingua::BioYaTeA::PostProcessing->new(\%options);
ok( defined($postProc) && ref($postProc) eq 'Lingua::BioYaTeA::PostProcessing', 'new() works');
$postProc->_printOptions(\*stderr);
$postProc->load_configuration;
ok(scalar(keys %{$postProc->reg_exps}) > 0, 'configuration loading works');
$postProc->defineTwigParser;
ok(defined $postProc->twig_parser, 'definition of the twig parser works');
# $postProc->filtering;
ok($postProc->filtering == 1, 'Filtering works');
$postProc->rmlog;
unlink("t/sampleEN-bioyatea-out-pp.xml");
