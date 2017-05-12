# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('GSAPI') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $inst = GSAPI::new_instance();

my $output = "";

GSAPI::set_stdio($inst,
                 sub { "\n" },
                 sub { $output .=$_[0]; length $_[0] },
                 sub { print STDERR $_[0]; length $_[0] }
                );

GSAPI::init_with_args($inst);


GSAPI::run_string($inst, "12345679 9 mul pstack quit\n");
GSAPI::exit($inst);

ok($output =~ /111111111/);
