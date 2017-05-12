
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 0-creation.t'

#########################

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 4;

BEGIN { use_ok('Lingua::BioYaTeA') ; use_ok('Config::General') ;}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Instantiation of abstract subclass

# eval { use Lingua::BioYaTeA; use Config::General; use Lingua::BioYaTeA::Corpus; };
# ok(defined 1);

my %config = Lingua::BioYaTeA->load_config("t/bioyatea/bioyatea.rc");
ok( (scalar(keys(%config)) > 0), 'Config loading works');

my $bioyatea = Lingua::BioYaTeA->new($config{"OPTIONS"}, \%config);

ok( defined($bioyatea) && ref($bioyatea) eq 'Lingua::BioYaTeA', 'new() works');
