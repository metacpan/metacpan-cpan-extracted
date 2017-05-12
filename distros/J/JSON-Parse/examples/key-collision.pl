#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse qw/parse_json parse_json_safe/;
my $j = '{"a":1, "a":2}';
my $p = parse_json ($j);
print "Ambiguous key 'a' is ", $p->{a}, "\n";
my $q = parse_json_safe ($j);
