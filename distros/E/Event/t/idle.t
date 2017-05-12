# idle daydreams of -*-perl-*-

use Test; plan tests => 4;
use Event qw(loop unloop);

# $Event::Eval = 1;
#$Event::DebugLevel = 0;

package myobj;
use Test;

my $myobj;
sub idle {
    my ($o,$e) = @_;
    if (!$myobj) {
	# see if method callbacks work
	ok $o, 'myobj';
	ok $e->w->desc, __PACKAGE__;
    }
    ++$myobj;
}
Event->idle(cb => [__PACKAGE__,'idle'],
	    desc => __PACKAGE__);

package main;

my $count=0;
my $idle = Event->idle(desc => "exit", cb =>
		       sub {
			   my $e = shift;
			   ++$count;
			   unloop() if $count > 2 && $myobj;
		       });

ok ref($idle), 'Event::idle';

Event->idle(cb => sub { ok 0; Event->exit })->cancel;
Event->idle(cb => sub { $idle->again }, repeat => 1, desc => "again");

ok !defined loop();
