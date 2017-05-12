use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    open INFILE, "t/file03.dat";
    my $sha2obj = new Digest::SHA2;
    $sha2obj->addfile(*INFILE);
    my $digest = $sha2obj->hexdigest();
    is("cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1",
        $digest);

    close INFILE;

    open INFILE, "t/file03.dat";
    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->addfile(*INFILE);
    my $digest2 = $sha2obj2->hexdigest();
    is("09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039",
        $digest2);

    close INFILE;

    open INFILE, "t/file03.dat";
    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->addfile(*INFILE);
    my $digest3 = $sha2obj3->hexdigest();
    is("8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909",
        $digest3);

    close INFILE;
};

