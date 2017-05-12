use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    open INFILE, "t/file10.dat";
    my $sha2obj = new Digest::SHA2;
    $sha2obj->addfile(*INFILE);
    my $digest = $sha2obj->hexdigest();
    is("80fced5a97176a5009207cd119551b42c5b51ceb445230d02ecc2663bbfb483a",
        $digest);

    close INFILE;

    open INFILE, "t/file10.dat";
    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->addfile(*INFILE);
    my $digest2 = $sha2obj2->hexdigest();
    is("aa1e77c094e5ce6db81a1add4c095201d020b7f8885a4333218da3b799b9fc42f00d60cd438a1724ae03bd7b515b739b",
        $digest2);

    close INFILE;

    open INFILE, "t/file10.dat";
    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->addfile(*INFILE);
    my $digest3 = $sha2obj3->hexdigest();
    is("fae25ec70bcb3bbdef9698b9d579da49db68318dbdf18c021d1f76aaceff962838873235597e7cce0c68aabc610e0deb79b13a01c302abc108e459ddfbe9bee8",
        $digest3);

    close INFILE;
};

