#
# $Id: copy.t,v 0.70 2005/08/09 15:47:00 dankogai Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
my $Debug = $ARGV[0] || 0;
BEGIN { plan tests => 5 };

use MacOSX::File::Copy;
ok(1); # If we made it this far, we're ok.
$MacOSX::File::Copy::DEBUG = $Debug;

ok(copy($0, "dummy")) or warn $MacOSX::File::OSErr;
ok(copy($0, "dummy", 0))  or warn $MacOSX::File::OSErr;
ok(move("dummy", "dummy2"))  or warn $MacOSX::File::OSErr;
ok(move("dummy2", "t/dummy2"))  or warn $MacOSX::File::OSErr;
unlink "t/dummy2";
