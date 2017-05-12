# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Event-Lib.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Event::Lib; 
ok(1); # If we made it this far, we're ok.


my $fail;
foreach my $constname (qw(
	EVBUFFER_EOF EVBUFFER_ERROR EVBUFFER_READ EVBUFFER_TIMEOUT
	EVBUFFER_WRITE EVLIST_ACTIVE EVLIST_ALL EVLIST_INIT EVLIST_INSERTED
	EVLIST_INTERNAL EVLIST_SIGNAL EVLIST_TIMEOUT EVLOOP_NONBLOCK
	EVLOOP_ONCE EV_PERSIST EV_READ EV_SIGNAL EV_TIMEOUT EV_WRITE
	_EVENT_LOG_DEBUG _EVENT_LOG_MSG _EVENT_LOG_WARN _EVENT_LOG_ERR _EVENT_LOG_ONCE
	EVENT_FREE_NOWARN
	)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Event::Lib macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }
}
if ($fail) {
  print "not ok 2\n";
} else {
  print "ok 2\n";
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

