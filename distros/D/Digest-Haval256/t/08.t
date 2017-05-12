use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Digest::Haval256')
};

BEGIN {
    open INFILE, "t/file2.test";
    my $haval = new Digest::Haval256;
    $haval->addfile(*INFILE);
    my $digest = $haval->hexdigest();
    close INFILE;
    is("b45cb6e62f2b1320e4f8f1b0b273d45add47c321fd23999dcf403ac37636d963",
        $digest);
};

