use strict;

use Test::More tests => 1;

use Log::Defer::Viz;

use JSON::XS;

my $z = decode_json q{
    {
       "start" : 1340353046.93565,
       "end" : 0.202386,
       "logs" : [
          [
             0.000158,
             30,
             "This is an info message (log level=30)"
          ],
          [
             0.201223,
             20,
             "Warning! \n\n Here is some more data:",
             {
                 "whatever" : 987
             }
          ]
       ],
       "data" : {
          "junkdata" : "some data"
       },
       "timers" : [
          [
             "junktimer",
             0.000224,
             0.100655
          ],
          [
             "junktimer2",
             0.000281,
             0.202386
          ]
       ]
    }
};

print encode_json($z);

print Log::Defer::Viz::render_timers(width => 80, timers => $z->{timers});


ok(1, 'did a render_timers');
