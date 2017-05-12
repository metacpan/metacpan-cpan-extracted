use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Digest::Haval256')
};

BEGIN {
    open INFILE, "t/file3.test";
    my $haval = new Digest::Haval256;
    $haval->addfile(*INFILE);
    my $digest = $haval->hexdigest();
    close INFILE;
    is("de8fd5ee72a5e4265af0a756f4e1a1f65c9b2b2f47cf17ecf0d1b88679a3e22f",
        $digest);
};

