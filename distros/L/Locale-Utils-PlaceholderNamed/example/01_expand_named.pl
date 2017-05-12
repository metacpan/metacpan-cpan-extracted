#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

require Locale::Utils::PlaceholderNamed;

my $numeric_code = sub {
    my $value = shift;

    defined $value
        or return $value;
    # set the , between 3 digits
    while ( $value =~ s{(\d+) (\d{3})}{$1,$2}xms ) {}
    # German number format
    $value =~ tr{.,}{,.};

    return $value;
};

my $obj = Locale::Utils::PlaceholderNamed->new(
    is_strict => 1,
);

for my $value (undef, 0 .. 2, '345678.90', 45_678.90) { ## no critic (MagicNumbers)
    () = print
        $obj->expand_named(
            '{count} EUR',
            count => $numeric_code->($value),
    ),
    "\n";
}

$obj->is_strict(0);

for my $value (undef, 0 .. 2, '345678.90', 45_678.90) { ## no critic (MagicNumbers)
    () = print
        $obj->expand_named(
            '{count} EUR',
            # also possible as hash reference
            {
                count  => $value,
            },
    ),
    "\n";
}

# $Id: 01_expand_named.pl 569 2015-02-02 07:45:21Z steffenw $

__END__

Output:

{count} EUR
0 EUR
1 EUR
2 EUR
345.678,90 EUR
45.678,9 EUR
 EUR
0 EUR
1 EUR
2 EUR
345678.90 EUR
45678.9 EUR
