use FindBin '$Bin';
use lib "$Bin";
use LJMT;

my $input = '~abxyz!"#$ABXYZ';
my $wide = ascii2wide ($input);
like ($wide, qr/ＡＢＸＹＺ/, "got wide ascii out");

my $roundtrip = wide2ascii ($wide);
is ($input, $roundtrip, "Roundtrip OK");

done_testing ();
