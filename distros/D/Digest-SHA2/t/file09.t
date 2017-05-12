use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    open INFILE, "t/file09.dat";
    my $sha2obj = new Digest::SHA2;
    $sha2obj->addfile(*INFILE);
    my $digest = $sha2obj->hexdigest();
    is("8ff59c6d33c5a991088bc44dd38f037eb5ad5630c91071a221ad6943e872ac29",
        $digest);

    close INFILE;

    open INFILE, "t/file09.dat";
    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->addfile(*INFILE);
    my $digest2 = $sha2obj2->hexdigest();
    is("92dca5655229b3c34796a227ff1809e273499adc2830149481224e0f54ff4483bd49834d4865e508ef53d4cd22b703ce",
        $digest2);

    close INFILE;

    open INFILE, "t/file09.dat";
    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->addfile(*INFILE);
    my $digest3 = $sha2obj3->hexdigest();
    is("0e928db6207282bfb498ee871202f2337f4074f3a1f5055a24f08e912ac118f8101832cdb9c2f702976e629183db9bacfdd7b086c800687c3599f15de7f7b9dd",
        $digest3);

    close INFILE;
};

