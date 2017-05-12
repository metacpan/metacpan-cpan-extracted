use strict;

use Test::More tests => 4;

use Digest::BubbleBabble qw( bubblebabble );

# Test vectors from from draft-huima-01.txt.
my %spec_tests = (
    ''              => 'xexax',
    '1234567890'    => 'xesef-disof-gytuf-katof-movif-baxux',
    'Pineapple'     => 'xigak-nyryk-humil-bosek-sonax',
);

while ( my( $str, $babble ) = each %spec_tests ) {
    is bubblebabble( Digest => $str ), $babble, "matches for '$str'";
}

my $dgst = pack "H*", "0a86c1b0428a6ce8103dfcc666519ae2918655d8";
my $bb = "xedim-kibyr-bybum-poryv-migyf-tazes-kunah-cikev-dugom-kihat-maxyx";

is bubblebabble( Digest => $dgst ), $bb, 'matches for custom sha-1 digest';