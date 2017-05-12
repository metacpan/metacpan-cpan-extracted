# This tests for an old bug where empty strings didn't work properly.
use warnings;
use strict;
use JSON::Parse 'parse_json';
use Test::More;
my $json = parse_json ('{"buggles":"","bibbles":""}');
is ($json->{buggles}, '');
is ($json->{bibbles}, '');
$json->{buggles} .= "chuggles";
is ($json->{bibbles}, '');
done_testing ();
exit;
