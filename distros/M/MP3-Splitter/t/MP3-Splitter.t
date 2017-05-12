# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MP3-Splitter.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use MP3::Splitter;
ok(1, 1, 'loaded'); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

for (<0*_test.mp3>) {
  1 while unlink;
}
ok(1, 1, 'cleanup after old runs');

mp3split_read('test.mp3', 'cuts', {verbose => 1});
ok(1, 1, 'split with Xing finished');

mp3split_read('test.mp3', 'cuts', {verbose => 1, keep_Xing => 0,
				   name_callback => sub {sprintf "%02d__%s", shift, shift}});
ok(1, 1, 'split without Xing finished');
