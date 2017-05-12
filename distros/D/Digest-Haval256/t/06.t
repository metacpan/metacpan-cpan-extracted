use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Digest::Haval256')
};

BEGIN {
    my $haval = new Digest::Haval256;
    $haval->add("");
    my $digest = $haval->hexdigest();
    is("be417bb4dd5cfb76c7126f4f8eeb1553a449039307b1a3cd451dbfdc0fbbe330",
        $digest);
};

