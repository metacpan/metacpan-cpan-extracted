# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use File::Log;
print 'Use it..........';
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

## Can we create a log object
print 'Create object...';
my $log;
ok( sub { $log = File::Log->new(); } );


## Can we write a msg to the log
print "Write msg ......";
my $msg = "This is a test\n";
$log->msg(0, $msg);
local $/;
open F, 'test.log';
my $str = <F>;
ok( $str, "/$msg/" );
close F;

## Use say to write to the log
print "Write say ......";
$msg = "This is a test";
$msg_result = "This is a test\n";
$log->say(0, $msg);
local $/;
open F, 'test.log';
my $str = <F>;
ok( $str, "/$msg_result/" );
close F;


## Can we write a exception to the log
print "Write exp ......";
$msg = "This is an exception\n";
$log->exp($msg);
local $/;
open F, 'test.log';
my $str = <F>;
ok( $str, "/$msg/" );
close F;
