
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 0-creation.t'

#########################

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 4;

BEGIN { use_ok('Lingua::YaTeA') ; use_ok('Config::General') ;}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Instantiation of abstract subclass

# eval { use Lingua::YaTeA; use Config::General; use Lingua::YaTeA::Corpus; };
# ok(defined 1);

my %config = Lingua::YaTeA::load_config("t/yatea/yatea.rc");
ok( (scalar(keys(%config)) > 0), 'Config loading works');

my $yatea = Lingua::YaTeA->new($config{"OPTIONS"}, \%config);
ok( defined($yatea) && ref($yatea) eq 'Lingua::YaTeA', 'new() works');
