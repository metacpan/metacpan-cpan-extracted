use diagnostics;
use strict;
use warnings;
use Test::More tests => 5;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    my $string1 = "This is a string.";
    my $string2 = "This is another string.";
    my $string3 = "This is a string.This is another string.";

    my $sha2obj = new Digest::SHA2 512;
    $sha2obj->add($string1);
    my $digest = $sha2obj->b64digest();
    is("AUXHdDW4huQ/z6W4puLFqfHCFvaUpl51NU+WeRdFUbegFRty9Ul9WIRbxQM/OfMknuCHzbYCaA7cP97aihj/mw", $digest);

    $sha2obj->reset();
    $sha2obj->add($string1, $string2);
    my $digest2 = $sha2obj->b64digest();
    is("1lw13gbkggujuBoCoQ+gl+lAjSg/FAwVBUn8wNNZ+oW7OmSBatX3bZXNU9+VHAPprrM1A31wUU1RB0+EK/COmw", $digest2);

    $sha2obj->reset();
    $sha2obj->add($string3);
    my $digest3 = $sha2obj->b64digest();
    is("1lw13gbkggujuBoCoQ+gl+lAjSg/FAwVBUn8wNNZ+oW7OmSBatX3bZXNU9+VHAPprrM1A31wUU1RB0+EK/COmw", $digest3);

    $sha2obj->reset();
    $sha2obj->add($string1);
    $sha2obj->add($string2);
    my $digest4 = $sha2obj->b64digest();
    is("1lw13gbkggujuBoCoQ+gl+lAjSg/FAwVBUn8wNNZ+oW7OmSBatX3bZXNU9+VHAPprrM1A31wUU1RB0+EK/COmw", $digest4);
};

