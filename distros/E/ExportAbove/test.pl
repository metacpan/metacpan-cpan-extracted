# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

END {print "cannot load ExportAbove\n" unless $loaded;}
use ExportAbove;
$loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package ExportAbove::Test;
BEGIN { $| = 1; print "1..9\n"; }
use ExportAbove;
BEGIN { print(((grep /^BEGIN$/, @EXPORT) ? 'not ' : ''),"ok 1\n"); }
$a = 1;
use ExportAbove;
BEGIN { print(((grep /^\$a$/, @EXPORT) ? '' : 'not '),"ok 2\n"); }
@a = (1);
use ExportAbove;
BEGIN { print(((grep /^\@a$/, @EXPORT) ? '' : 'not '),"ok 3\n"); }
%a = (a => 1);
use ExportAbove;
BEGIN { print(((grep /^%a$/, @EXPORT) ? '' : 'not '),"ok 4\n"); }
sub foo {1}
use ExportAbove;
BEGIN { print(((grep /^foo$/, @EXPORT) ? '' : 'not '),"ok 5\n"); }
sub bar {1}
use ExportAbove qw(OK);
BEGIN { print(((grep /^bar$/, @EXPORT_OK) ? '' : 'not '),"ok 6\n"); }
sub baz {1}
use ExportAbove qw(:Tag);
BEGIN { print(((grep /^baz$/, @{$EXPORT_TAGS{Tag}} and grep /^baz$/, @EXPORT) 
	? '' : 'not '),"ok 7\n"); }
sub qux {1}
use ExportAbove qw(:Tag OK);
BEGIN { print(((grep /^qux$/, @{$EXPORT_TAGS{Tag}} and grep /^qux$/, @EXPORT_OK)
	? '' : 'not '),"ok 8\n"); }
sub quux {1}
no ExportAbove;
BEGIN { print(((grep /^quux$/, @EXPORT) ? 'not ' : ''),"ok 9\n"); }
