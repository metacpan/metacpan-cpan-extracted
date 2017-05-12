package FormValidator::Nested::Filter::String;
use strict;
use warnings;
use utf8;

use Lingua::JA::Regular::Unicode qw//;



sub remove_hyphen {
    my $value = shift;

    $value =~ tr/-‐//d;

    return $value;
}


sub alnum_z2h {
    my $value = shift;

    return Lingua::JA::Regular::Unicode::alnum_z2h($value);
}

1;

