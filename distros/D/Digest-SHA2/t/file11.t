use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    open INFILE, "t/file11.dat";
    my $sha2obj = new Digest::SHA2;
    $sha2obj->addfile(*INFILE);
    my $digest = $sha2obj->hexdigest();
    is("88ee6ada861083094f4c64b373657e178d88ef0a4674fce6e4e1d84e3b176afb",
        $digest);

    close INFILE;

    open INFILE, "t/file11.dat";
    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->addfile(*INFILE);
    my $digest2 = $sha2obj2->hexdigest();
    is("78cc6402a29eb984b8f8f888ab0102cabe7c06f0b9570e3d8d744c969db14397f58ecd14e70f324bf12d8dd4cd1ad3b2",
        $digest2);

    close INFILE;

    open INFILE, "t/file11.dat";
    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->addfile(*INFILE);
    my $digest3 = $sha2obj3->hexdigest();
    is("211bec83fbca249c53668802b857a9889428dc5120f34b3eac1603f13d1b47965c387b39ef6af15b3a44c5e7b6bbb6c1096a677dc98fc8f472737540a332f378",
        $digest3);

    close INFILE;
};

