use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    open INFILE, "t/file05.dat";
    my $sha2obj = new Digest::SHA2;
    $sha2obj->addfile(*INFILE);
    my $digest = $sha2obj->hexdigest();
    is("ab64eff7e88e2e46165e29f2bce41826bd4c7b3552f6b382a9e7d3af47c245f8",
        $digest);

    close INFILE;

    open INFILE, "t/file05.dat";
    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->addfile(*INFILE);
    my $digest2 = $sha2obj2->hexdigest();
    is("e28e35e25a1874908bf0958bb088b69f3d742a753c86993e9f4b1c4c21988f958bd1fe0315b195aca7b061213ac2a9bd",
        $digest2);

    close INFILE;

    open INFILE, "t/file05.dat";
    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->addfile(*INFILE);
    my $digest3 = $sha2obj3->hexdigest();
    is("70aefeaa0e7ac4f8fe17532d7185a289bee3b428d950c14fa8b713ca09814a387d245870e007a80ad97c369d193e41701aa07f3221d15f0e65a1ff970cedf030",
        $digest3);

    close INFILE;
};

