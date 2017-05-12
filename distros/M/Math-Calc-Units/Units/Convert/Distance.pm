package Math::Calc::Units::Convert::Distance;
use base 'Math::Calc::Units::Convert::Metric';
use strict;

my %total_unit_map;

my %ranges = ( default => [ 1, 999 ] );

my %distance_units = ( inch => [ 2.54, 'centimeter' ],
		       foot => [ 12, 'inch' ],
		       yard => [ 3, 'foot' ],
		       mile => [ 5280, 'foot' ],
);

my %distance_pref = ( meter => 1.1,
		      inch => 0.7,
		      foot => 0.9,
		      yard => 0,
		      mile => 1.0,
);

my %aliases = ( 'feet' => 'foot',
              );

# Perform all math in terms of meters
sub canonical_unit { return 'meter'; }

# Metric.pm uses this to construct unit names
sub abbreviated_canonical_unit { return 'm'; }

# Preference for this class's canonical unit to be the "major" unit
# used. The major unit is the one that determines the range of values
# to use for computing the overall preference. For example, if you
# have 240000 meters/day, you would want to pick "240km/hour", which
# is based on the number "240" being a decent one to use for meters.
# If you had instead chosen 'hour' as the major unit, then you
# wouldn't like using 240 because 240 hours should really be described
# as 10 days.
#
# Note that the above example is not realistic, because the only units
# that are eligible for being chosen as the major unit are the ones in
# the numerator. So major_pref() is really only used for something
# like "square meter seconds", where you want to choose between
# "meter" and "second".
sub major_pref { return 1; }

sub major_variants {
    my ($self) = @_;
    return $self->variants('meter');
}

sub get_ranges {
    return \%ranges;
}

# Return the relative preference of different units. Meters are
# preferred over miles, miles over feet.
sub get_prefs {
    return \%distance_pref;
}

sub singular {
    my ($self, $unit) = @_;
    $unit = $self->SUPER::singular($unit);
    return $aliases{$unit} || $unit;
}

sub unit_map {
    my ($self) = @_;
    if (keys %total_unit_map == 0) {
	%total_unit_map = (%{$self->SUPER::unit_map()}, %distance_units);
    }
    return \%total_unit_map;
}

# simple_convert : unitName x unitName -> multiplier
#
sub simple_convert {
    my ($self, $from, $to) = @_;

    # 'm', 'meter', or 'meters'
    return 1 if $from =~ /^m(eter(s?))?$/i;

    if (my $easy = $self->SUPER::simple_convert($from, $to)) {
	return $easy;
    }

    # km == kilometer
    if ($from =~ /^(.)m(eter(s?))?$/i) {
	if (my ($prefix) = $self->expand($1)) {
	    return $self->simple_convert($prefix . "meter", $to);
	}
    }

    return; # Failed
}

# Override Metric::variants because only meters should be given metric
# prefixes, not inches, feet, etc.
sub variants {
    my ($self, $base) = @_;
    my $canon = $self->canonical_unit();
    return ($base,
            keys %{ $self->unit_map() },
            map { "$_$canon" } $self->get_prefixes());
}

1;
