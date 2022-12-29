use Test2::V0 '-target' => 'JSON::Path';
local $JSON::Path::Safe = 0;

#  use strict;
#  use JSON::Path;
#  use diagnostics;

my $json = q|{
  "phones": [
    { "type" : "iPhone", "number": "(123rpar 456-7890" },
    { "type" : "home", "number": "(123) 456-7890" },
    { "type" : "''\"']w[(o)\\r{k}'\"''", "number": "987 654 321" }
  ]
}|;
use Data::Dumper;
warn(Dumper($json));

my $phone_number;
$phone_number = '(123) 456-7890';

#  $phone_number = '(123rpar 456-7890'; # <-- works, the above does not

my $jpath =
  JSON::Path->new('$.phones.[?($_->{number} eq "(123) 456-7890")].type');
my @types = $jpath->values($json);
is($types[0], "home", "Got the right type");

local $JSON::Path::Safe = 1;
$jpath = JSON::Path->new(q|$.phones[?(@.type == "''\"']w[(o)\\r{k}'\"''")]|);
@types = $jpath->paths($json);
is($types[0], q|$['phones']['2']|, "Got the right type with insane quotes all around");

done_testing();
