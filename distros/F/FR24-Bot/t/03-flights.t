use v5.12;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Temp qw/ :POSIX /;
use Data::Dumper;
use_ok('FR24::Utils');

my $flights = FR24::Utils::parse_flights('', 1);

# Function is working (will return a valid structure even if empty)
ok($flights, "Function is working");
ok($flights->{"status"}, "Got status");
ok($flights->{"status"} eq "OK", "Got status: OK " . $flights->{"status"}); 
ok($flights->{"total"} == 28, "Got expected flights: 28==" . $flights->{"total"});

# Specific flight?
#"485789",51.94,0.9666,64.76496,38275,539,"6250",0,"","",1689143721,"","","",false,-1216,"KLM100"
my $id = "485789";
my $callsign = "KLM100";
my $lat = 51.94;
my $long = 0.9666;
my $flight = $flights->{"data"}->{$id};
ok($flight, "Got flight $id");
ok($flight->{"callsign"} eq $callsign, "Got expected callsign: $callsign==" . $flight->{"callsign"});
ok($flight->{"lat"} eq $lat, "Got expected latitude: $lat=" . $flight->{"lat"});
ok($flight->{"long"} eq $long, "Got expected longitude: $long=" . $flight->{"long"});


done_testing();

__DATA__
{
  "3c6708": [
    "3c6708", 
    53.21,
    0.913,
    110.556046,
    43000,
    521,
    "2027",
    0,
    "",
    "",
    1689143761,
    "",
    "",
    "",
    false,
    0,
    "DLH481"
  ],
...