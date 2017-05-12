use Test::More tests => 2;

use MARC::Descriptions;

my $td = MARC::Descriptions->new;
$s = $td->get("245","description");
$s = "Hmm.";
$s = $td->get("245","description");
is( $s, "Title Statement", "Can't change value in string");

$href = $td->get("210","subfields");
$href->{"a"}->{description} = "Hmm.";
$href = $td->get("210","subfields");
is( $href->{"a"}->{description}, "Abbreviated title", "Can't change
value in hash" );
