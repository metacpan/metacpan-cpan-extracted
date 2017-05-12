# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gtk2-OSXApplication.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Gtk2 "-init";

use Test::More tests => 2;
BEGIN { use_ok('Gtk2::AppIndicator') };


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $osxapp=new Gtk2::AppIndicator("myapp","iconname");
ok(ref($osxapp) eq "Gtk2::AppIndicator" ,"osxapp");


