
use Mojo::Base -strict;

use Test::More 0.88;

use Kevin::Commands::Util;
BEGIN { *human_duration = \&Kevin::Commands::Util::_human_duration }

my @TESTS = (
  {dt => 0,       expected => 'less than a second'},
  {dt => 1,       expected => '1 second',},
  {dt => 2,       expected => '2 seconds',},
  {dt => 3,       expected => '3 seconds',},
  {dt => 5,       expected => '5 seconds',},
  {dt => 10,      expected => '10 seconds',},
  {dt => 20,      expected => '20 seconds',},
  {dt => 30,      expected => '30 seconds',},
  {dt => 40,      expected => '40 seconds',},
  {dt => 50,      expected => '50 seconds',},
  {dt => 60,      expected => 'about a minute',},
  {dt => 61,      expected => 'about a minute',},
  {dt => 60 + 10, expected => 'about a minute',},
  {dt => 60 + 20, expected => 'about a minute',},
  {dt => 60 + 30, expected => 'about a minute',},
  {dt => 60 + 40, expected => 'about a minute',},
  {dt => 60 + 50, expected => 'about a minute',},
  {dt => 60 + 59, expected => 'about a minute',},
  {dt => 2 * 60,            expected => '2 minutes',     name => '2 min'},
  {dt => 3 * 60,            expected => '3 minutes',     name => '3 min'},
  {dt => 5 * 60,            expected => '5 minutes',     name => '5 min'},
  {dt => 10 * 60,           expected => '10 minutes',    name => '10 min'},
  {dt => 20 * 60,           expected => '20 minutes',    name => '20 min'},
  {dt => 30 * 60,           expected => '30 minutes',    name => '30 min'},
  {dt => 40 * 60,           expected => '40 minutes',    name => '40 min'},
  {dt => 45 * 60,           expected => '45 minutes',    name => '45 min'},
  {dt => 46 * 60,           expected => 'about an hour', name => '46 min'},
  {dt => 50 * 60,           expected => 'about an hour', name => '50 min'},
  {dt => 70 * 60,           expected => 'about an hour', name => '70 min'},
  {dt => 75 * 60,           expected => 'about an hour', name => '75 min'},
  {dt => 90 * 60,           expected => '2 hours',       name => '90 min'},
  {dt => 91 * 60,           expected => '2 hours',       name => '91 min'},
  {dt => 2 * 60 * 60 - 1,   expected => '2 hours',       name => '2 h - 1 sec'},
  {dt => 2 * 60 * 60,       expected => '2 hours',       name => '2 h'},
  {dt => 3 * 60 * 60,       expected => '3 hours',       name => '3 h'},
  {dt => 5 * 60 * 60,       expected => '5 hours',       name => '5 h'},
  {dt => 10 * 60 * 60,      expected => '10 hours',      name => '10 h'},
  {dt => 20 * 60 * 60,      expected => '20 hours',      name => '20 h'},
  {dt => 30 * 60 * 60,      expected => '30 hours',      name => '30 h'},
  {dt => 40 * 60 * 60,      expected => '40 hours',      name => '40 h'},
  {dt => 45 * 60 * 60,      expected => '45 hours',      name => '45 h'},
  {dt => 47 * 60 * 60,      expected => '47 hours',      name => '47 h'},
  {dt => 2 * 24 * 60 * 60,  expected => '2 days',        name => '48 h'},
  {dt => 3 * 24 * 60 * 60,  expected => '3 days',        name => '3 d'},
  {dt => 5 * 24 * 60 * 60,  expected => '5 days',        name => '5 d'},
  {dt => 10 * 24 * 60 * 60, expected => '10 days',       name => '10 d'},
  {dt => 12 * 24 * 60 * 60, expected => '12 days',       name => '12 d'},
  {dt => 13 * 24 * 60 * 60, expected => '13 days',       name => '13 d'},
  {dt => 2 * 7 * 24 * 60 * 60,   expected => '2 weeks',   name => '14 d'},
  {dt => 3 * 7 * 24 * 60 * 60,   expected => '3 weeks',   name => '3 w'},
  {dt => 30 * 24 * 60 * 60,      expected => '4 weeks',   name => '30 d'},
  {dt => 5 * 7 * 24 * 60 * 60,   expected => '5 weeks',   name => '5 w'},
  {dt => 8 * 7 * 24 * 60 * 60,   expected => '8 weeks',   name => '8 w'},
  {dt => 59 * 24 * 60 * 60,      expected => '8 weeks',   name => '59 d'},
  {dt => 2 * 30 * 24 * 60 * 60,  expected => '2 months',  name => '60 d'},
  {dt => 3 * 30 * 24 * 60 * 60,  expected => '3 months',  name => '3 mon'},
  {dt => 20 * 7 * 24 * 60 * 60,  expected => '4 months',  name => '20 w'},
  {dt => 5 * 30 * 24 * 60 * 60,  expected => '5 months',  name => '5 mon'},
  {dt => 10 * 30 * 24 * 60 * 60, expected => '10 months', name => '10 mon'},
  {dt => 12 * 30 * 24 * 60 * 60, expected => '12 months', name => '12 mon'},
  {dt => 15 * 30 * 24 * 60 * 60, expected => '15 months', name => '15 mon'},
  {dt => 20 * 30 * 24 * 60 * 60, expected => '20 months', name => '20 mon'},
  {dt => 23 * 30 * 24 * 60 * 60, expected => '23 months', name => '23 mon'},
  {dt => 24 * 30 * 24 * 60 * 60, expected => '24 months', name => '24 mon'},
  {
    dt       => (365 + 364) * 24 * 60 * 60,
    expected => '24 months',
    name     => '1 year + 364 d'
  },
  {dt => 2 * 365 * 24 * 60 * 60, expected => '2 years', name => '2*365 d'},
  {dt => 7 * 365 * 24 * 60 * 60, expected => '7 years', name => '7 years'},
  {
    dt       => 30 * 365 * 24 * 60 * 60 + 7 * 24 * 60 * 60,
    expected => '30 years',
    name     => '30 years + 1 week'
  },
);

for my $t (@TESTS) {
  my $dt = $t->{dt};

  my $expected = $t->{expected};
  my $test = 'dt = ' . ($t->{name} // "$dt sec");
  is human_duration($dt), $expected, $test;
}

done_testing;
