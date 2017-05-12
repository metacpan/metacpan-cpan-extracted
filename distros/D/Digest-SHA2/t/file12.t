use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    open INFILE, "t/file12.dat";
    my $sha2obj = new Digest::SHA2;
    $sha2obj->addfile(*INFILE);
    my $digest = $sha2obj->hexdigest();
    is("5a2e925a7f8399fa63a20a1524ae83a7e3c48452f9af4df493c8c51311b04520",
        $digest);

    close INFILE;

    open INFILE, "t/file12.dat";
    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->addfile(*INFILE);
    my $digest2 = $sha2obj2->hexdigest();
    is("72ec26cc742bc5fb1ef82541c9cadcf01a15c8104650d305f24ec8b006d7428e8ebe2bb320a465dbdd5c6326bbd8c9ad",
        $digest2);

    close INFILE;

    open INFILE, "t/file12.dat";
    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->addfile(*INFILE);
    my $digest3 = $sha2obj3->hexdigest();
    is("ebad464e6d9f1df7e8aadff69f52db40a001b253fbf65a018f29974dcc7fbf8e58b69e247975fbadb4153d7289357c9b6212752d0ab67dd3d9bbc0bb908aa98c",
        $digest3);

    close INFILE;
};

