
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1-corpusLoading.t'

#########################

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 2;

BEGIN {}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Instantiation of abstract subclass

use File::Path; 
use Lingua::BioYaTeA; 
use Config::General; 
use Lingua::BioYaTeA::Corpus;

my %config = Lingua::BioYaTeA->load_config("t/bioyatea/bioyatea.rc");
my $bioyatea = Lingua::BioYaTeA->new($config{"OPTIONS"}, \%config);
my $corpus = Lingua::BioYaTeA::Corpus->new("examples/sampleEN.ttg",$bioyatea->getOptionSet,$bioyatea->getMessageSet);
ok($bioyatea->termExtraction($corpus) == 0, 'term extraction works');
ok((stat('sampleEN/bioyatea/raw/termList.txt'))[7] != 0, 'Number of extracted terms greater than 0');
rmtree('sampleEN');
