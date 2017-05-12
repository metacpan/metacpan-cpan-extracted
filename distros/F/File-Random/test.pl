# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 284};
use File::Random;
ok 1, "Stupid Load test"; # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
use lib qw:test/lib:;

use strict;
use warnings;

use Data::Dumper;

$Data::Dumper::Indent  = 0;
$Data::Dumper::Varname = 'X';

diag "Test method random_line";
use RandomLine;
RandomLine->new()->runtests();
diag "\n";

diag "Test method random_file";
use RandomFileMethodAllTests;
RandomFileMethodAllTests->new()->runtests();
diag "\n";

	
diag "Test method content_of_random_file";
use ContentOfRandomFileTestOptions;
ContentOfRandomFileTestOptions->new()->runtests();

use ContentOfRandomFileInScalarContext;
ContentOfRandomFileInScalarContext->new()->runtests();
diag "\n";

1;
