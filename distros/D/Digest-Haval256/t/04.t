use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Digest::Haval256')
};

BEGIN {
    my $haval = new Digest::Haval256;
    $haval->add("HAVAL");
    my $digest = $haval->hexdigest();
    is("153d2c81cd3c24249ab7cd476934287af845af37f53f51f5c7e2be99ba28443f",
        $digest);
};

