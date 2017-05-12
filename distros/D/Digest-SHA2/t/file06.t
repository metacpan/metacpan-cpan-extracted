use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    open INFILE, "t/file06.dat";
    my $sha2obj = new Digest::SHA2;
    $sha2obj->addfile(*INFILE);
    my $digest = $sha2obj->hexdigest();
    is("f08a78cbbaee082b052ae0708f32fa1e50c5c421aa772ba5dbb406a2ea6be342",
        $digest);

    close INFILE;

    open INFILE, "t/file06.dat";
    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->addfile(*INFILE);
    my $digest2 = $sha2obj2->hexdigest();
    is("37b49ef3d08de53e9bd018b0630067bd43d09c427d06b05812f48531bce7d2a698ee2d1ed1ffed46fd4c3b9f38a8a557",
        $digest2);

    close INFILE;

    open INFILE, "t/file06.dat";
    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->addfile(*INFILE);
    my $digest3 = $sha2obj3->hexdigest();
    is("b3de4afbc516d2478fe9b518d063bda6c8dd65fc38402dd81d1eb7364e72fb6e6663cf6d2771c8f5a6da09601712fb3d2a36c6ffea3e28b0818b05b0a8660766",
        $digest3);

    close INFILE;
};

