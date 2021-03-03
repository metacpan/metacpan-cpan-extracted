use FindBin '$Bin';
use lib "$Bin";
use GZT;

use_ok ('Gzip::Zopfli');
my $in = 'something' x 1000;
my $out = zopfli_compress ($in);
cmp_ok (length ($out), '<', length ($in), "compressed something");

done_testing ();
