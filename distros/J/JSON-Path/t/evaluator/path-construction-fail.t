use Test2::V0 '-target' => 'JSON::Path';
use JSON::MaybeXS qw/decode_json/;

# Test demonstrating RT #122109, "paths method succeeds in search but then fails on path construction"
# https://rt.cpan.org/Ticket/Display.html?id=122109
#
local $JSON::Path::Safe = 0;
my $json = '{
   "4" : {
      "value_raw" : "European",
      "value" : "European",
      "name" : "Ethnicity",
      "type" : "radio",
      "id" : 4
   },
   "1" : {
      "middle" : "",
      "first" : "James",
      "value" : "James Bowery",
      "last" : "Bowery",
      "name" : "Name",
      "type" : "name",
      "id" : 1
   },
   "3" : {
      "value_raw" : "Male",
      "value" : "Male",
      "name" : "Gender",
      "type" : "radio",
      "id" : 3
   },
   "2" : {
      "unix" : 1498176000,
      "time" : "",
      "date" : "06/23/2017",
      "value" : "06/23/2017",
      "name" : "Birthdate",
      "type" : "date-time",
      "id" : 2
   },
   "5" : {
      "value" : "jabowery@emailservice.com",
      "name" : "Email",
      "type" : "text",
      "id" : 5
   }
}';
my $json_hash = decode_json($json);
my $p3        = $CLASS->new('$.[?($_->{name} eq "Email")]');
my @paths;
ok lives { @paths = $p3->paths($json_hash) }, q{paths() did not die} or diag qq{Caught exception: $@};
is \@paths, [q{$['5']}], q{paths() produced correct path};
done_testing;
