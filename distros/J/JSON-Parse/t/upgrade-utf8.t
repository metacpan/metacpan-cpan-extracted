use FindBin '$Bin';
use lib "$Bin";
use JPT;

my $jp = JSON::Parse->new ();
$jp->upgrade_utf8 (1);
no utf8;
my $json = '{"場":"部"}';
my $out = $jp->parse ($json);
use utf8;
use Data::Dumper;
print Dumper ($out);
my @keys = keys %$out;
ok (utf8::is_utf8 ($keys[0]), "Upgraded UTF-8 to character encoding");
cmp_ok (length ($out->{"場"}), '==', 1, "Got utf8");

done_testing ();
