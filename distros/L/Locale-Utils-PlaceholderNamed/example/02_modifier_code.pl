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
    modifier_code => sub {
        my ($value, $attribute) = @_;
        if ( $attribute eq 'num' ) {
            return $numeric_code->($value);
        }
        return $value;
    },
);

for my $value (undef, 0 .. 2, '345678.90', 45_678.90) { ## no critic (MagicNumbers)
    () = print
        $obj->expand_named(
            '{count :num} EUR',
            count => $value,
    ),
    "\n";
}
# $Id: 02_modifier_code.pl 474 2014-01-24 11:51:14Z steffenw $

__END__

Output:

# $Id: 02_modifier_code.pl 474 2014-01-24 11:51:14Z steffenw $

__END__

Output:

 EUR
0 EUR
1 EUR
2 EUR
345.678,90 EUR
45.678,9 EUR
