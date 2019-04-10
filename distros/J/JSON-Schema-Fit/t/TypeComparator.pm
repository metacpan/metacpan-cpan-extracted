package TypeComparator;

use strict;

use Test::Deep;
use B;

# copied from JSON::packportPP::_looks_like_number
sub _is_number {
    my $value = shift;
    my $b_obj = B::svref_2object(\$value);
    my $flags = $b_obj->FLAGS;
    return 1 if $flags & ( B::SVp_IOK() | B::SVp_NOK() ) and !( $flags & B::SVp_POK() );
    return;
}

# real number comparator
sub real_number {
    my $expected = shift;
    return code sub {
        my $got = shift;
        return (0, "value has string flags") if !_is_number($got);
        return $got == $expected;
    };
}

# real string comparator
sub real_string {
    my $expected = shift;
    return code sub {
        my $got = shift;
        return (0, "value has number flags") if _is_number($got);
        return $got eq $expected;
    };
}

1;
