package Math::Calc::Units::Convert;
use base 'Exporter';
use strict;
use vars qw(@EXPORT_OK);
BEGIN { @EXPORT_OK = qw(convert reduce canonical find_top construct); };

use Math::Calc::Units::Convert::Multi qw(to_canonical);

# convert : value x unit -> value
#
# The lower-level conversion routines really only know how to convert
# things to canonical units. But this routine may be called with eg
# 120 minutes -> hours. So we convert both the current and target to
# canonical units, and divide the first by the second. (Doesn't work
# for adding units that aren't multiples of each other, but that's not
# what this tool is for anyway.)
sub convert {
    my ($from, $unit) = @_;

    my $to = [ 1, $unit ];

    my $canon_from = canonical($from);
    my $canon_to = canonical($to);

    die "conversion between incompatible units"
      if not same_units($canon_from->[1], $canon_to->[1]);

    return [ $canon_from->[0] / $canon_to->[0], $unit ];
}

# Are the (canonical) units compatible? (They must have exactly the
# same base units, and each must be raised to exactly the same power.)
sub same_units {
    my ($u1, $u2) = @_;
    return if keys %$u1 != keys %$u2;
    while (my ($bu1, $bp1) = each %$u1) {
        return if ! exists $u2->{$bu1};
        return if $bp1 != $u2->{$bu1};
    }
    return 1;
}

sub canonical {
    my ($v) = @_;
    my $c = to_canonical($v->[1]);
    my $w = [ $v->[0] * $c->[0], $c->[1] ];
    return $w;
}

sub reduce {
    my ($v) = @_;
    return canonical($v, 'reduce, please');
}

sub construct {
    my ($constructor, $args) = @_;
    return Math::Calc::Units::Convert::Multi::construct($constructor, $args);
}

1;
