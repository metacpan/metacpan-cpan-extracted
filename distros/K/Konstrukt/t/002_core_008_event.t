# check core module: event

use strict;
use warnings;

use Test::More tests => 8;

#=== Dependencies
#none

#Event
use Konstrukt::Event;

my $test_object = Konstrukt::Test::Event->new();

#init
is($Konstrukt::Event->init(), 1, "init");

#register
is($Konstrukt::Event->register('testevent', $test_object, \&Konstrukt::Test::Event::foo), 1, "register");

#trigger
is($Konstrukt::Event->trigger('testevent', 'bar'), 1, "trigger");
is($test_object->{foo}, "bar", "trigger");

#deregister
is($Konstrukt::Event->deregister('testevent', $test_object, \&Konstrukt::Test::Event::foo), 1, "deregister");
$test_object->{foo} = "baz";
$Konstrukt::Event->trigger('testevent', 'bar');
is($test_object->{foo}, "baz", "deregister");

#deregister_all_by_object
$Konstrukt::Event->register('testevent', $test_object, \&Konstrukt::Test::Event::foo);
$Konstrukt::Event->register('testevent', $test_object, \&Konstrukt::Test::Event::bar);
is($Konstrukt::Event->deregister_all_by_object('testevent', $test_object), 1, "deregister_all_by_object");
$Konstrukt::Event->trigger('testevent', 'bar');
is($test_object->{foo}, "baz", "deregister_all_by_object");

package Konstrukt::Test::Event;

sub new { bless {}, $_[0] }

sub foo { $_[0]->{foo} = $_[1] }

1;
