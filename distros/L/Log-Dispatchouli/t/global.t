use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Log::Dispatchouli::Global '$Logger' => { init => {
  ident   => 't/global.t',
  log_pid => 0,
  to_self => 1,
}};

{
  package Alpha;
  use Log::Dispatchouli::Global '$Logger';

  sub call_bravo {
    my ($self, $n) = @_;
    
    local $Logger = $Logger->proxy({ proxy_prefix => "$n: " });

    $Logger->log("inside call_bravo");

    Bravo->endpoint;
  }
}

{
  package Bravo;
  use Log::Dispatchouli::Global '$Logger' => { -as => 'L' };

  sub endpoint {
    my ($self, $n) = @_;
    
    $L->log("inside Bravo::endpoint");
  }
}

isa_ok($Logger, 'Log::Dispatchouli', 'imported $Logger');

$Logger->log("first");

Alpha->call_bravo(123);

$Logger->log("last");

my $events = $Logger->events;

is($events->[0]->{message}, 'first', '1st log');
is($events->[1]->{message}, '123: inside call_bravo', '2nd log');
is($events->[2]->{message}, '123: inside Bravo::endpoint', '3rd log');
is($events->[3]->{message}, 'last', '4th log');

done_testing;
