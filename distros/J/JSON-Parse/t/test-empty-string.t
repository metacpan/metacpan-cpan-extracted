# This tests for an old bug where empty strings didn't work properly.
use FindBin '$Bin';
use lib "$Bin";
use JPT;
my $json = parse_json ('{"buggles":"","bibbles":""}');
is ($json->{buggles}, '');
is ($json->{bibbles}, '');
$json->{buggles} .= "chuggles";
is ($json->{bibbles}, '');
done_testing ();
exit;
