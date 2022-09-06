use Test2::V0 '-target' => 'JSON::Path';
local $JSON::Path::Safe = 0;

#  use strict;
#  use JSON::Path;
#  use diagnostics;

my $json =
'{ "phones": [ { "type" : "iPhone", "number": "(123rpar 456-7890" }, { "type" : "home", "number": "(123) 456-7890" } ] }';

my $phone_number;
$phone_number = '(123) 456-7890';

#  $phone_number = '(123rpar 456-7890'; # <-- works, the above does not

my $jpath =
  JSON::Path->new('$.phones.[?($_->{number} eq "(123) 456-7890")].type');
my @types = $jpath->values($json);
is($types[0], "home", "Got the right type");
done_testing();
