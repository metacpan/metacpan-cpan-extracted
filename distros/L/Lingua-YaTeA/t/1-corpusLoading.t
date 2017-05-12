
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1-corpusLoading.t'

#########################

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 2;

BEGIN { use_ok('Lingua::YaTeA::Corpus');}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Instantiation of abstract subclass


use Lingua::YaTeA; 
use Config::General; 
use Lingua::YaTeA::Corpus;

my %config = Lingua::YaTeA::load_config("t/yatea/yatea.rc");
my $yatea = Lingua::YaTeA->new($config{"OPTIONS"}, \%config);
my $corpus = Lingua::YaTeA::Corpus->new("examples/sampleEN.ttg",$yatea->getOptionSet,$yatea->getMessageSet);
ok( (defined $corpus) && (ref($corpus) eq "Lingua::YaTeA::Corpus"), "new corpus() works");
