package Math::Calc::Units::Convert::Base;
use strict;

sub major_pref {
    return 0;
}

# major_variants :void -> ( unit name )
#
# Return the set of prefix-free variants of the class that you might
# want to use as a final result. So for time, this would return
# "second" and "year" but not "millisecond" or "gigayear".
#
# Only this base class will ever use the unit passed in, and that's
# because this base class is used for unknown units. Subclasses should
# return a list of variants regardless of what is passed as $unit.
#
sub major_variants {
    my ($self, $unit) = @_;
    return $unit;
}

# singular : unitName -> unitName
#
# Convert a possibly pluralized unit name to the uninflected singular
# form of the same name.
#
# Example: inches -> inch
# Example: inch -> inch
#
# I suppose I ought to optionally allow Lingu::EN::Inflect or whatever
# it's called.
#
sub singular {
    my $self = shift;
    local $_ = shift;

    return $_ unless /s$/;
    return $1 if /^(.*[^e])s$/;  # doesn't end in es => just chop off the s
    return $1 if /^(.*(ch|sh))es$/;   # eg inches -> inch
    return $1 if /^(.*[aeiou][^aeiou]e)s$/; # scales -> scale
    chop; return $_; # Chop off the s
}

sub unit_map {
    return {};
}

sub variants {
    my ($self, $base) = @_;
    my $map = $self->unit_map();
    return ($base, keys %$map);
}

# same : unit x unit -> boolean
#
# Returns whether the two units match, where a unit is a string (eg
# "week") and a power. So "days" and "toothpicks" are not the same,
# nor are feet and square feet.
sub same {
    my ($self, $u, $v) = @_;
    return 0 if keys %$u != keys %$v;
    while (my ($name, $power) = each %$u) {
        return 0 if ! exists $v->{$name};
	return 0 if $v->{$name} != $power;
    }
    return 1;
}

# simple_convert : unitName x unitName -> multiplier
#
# Second unit name must be canonical.
#
sub simple_convert {
    my ($self, $from, $to) = @_;
    return 1 if $from eq $to;

    my $map = $self->unit_map();
    my $w = $map->{$from} || $map->{lc($from)};
    if (! $w) {
	$from = $self->singular($from);
	$w = $map->{$from} || $map->{lc($from)};
    }
    return if ! $w; # Failed

    # We might have only gotten one step closer (hour -> minute -> sec)
    if ($w->[1] ne $to) {
	my $submult = $self->simple_convert($w->[1], $to);
	return if ! defined $submult;
	return $w->[0] * $submult;
    } else {
	return $w->[0];
    }
}

# to_canonical : unitName -> amount x unitName
#
# Convert the given unit to the canonical unit for this class, along
# with a conversion factor.
#
sub to_canonical {
    my ($self, $unitName) = @_;
    my $canon = $self->canonical_unit();
    if ($canon) {
	my $mult = $self->simple_convert($unitName, $canon);
	return if ! defined $mult;
	return ($mult, $canon);
    } else {
	return (1, $self->singular($unitName));
    }
}

# canonical_unit : void -> unit name
#
# Return the canonical unit for this class.
#
sub canonical_unit {
    return;
}

sub abbreviated_canonical_unit {
    my ($self) = @_;
    return $self->canonical_unit;
}

#################### RANKING, SCORING, DISPLAYING ##################

# spread : magnitude x base unit x units to spread over
#  -> ( <mag,unit> )
#
# @$units MUST BE SORTED, LARGER UNITS FIRST!
#
my $THRESHOLD = 0.01;
sub spread {
    my ($self, $mag, $base, $start, $units) = @_;
    die if $mag < 0; # Must be given a positive value!
    return [ 0, $base ] if $mag == 0;

    my $orig = $mag;

    my @desc;
    my $started = 0;
    foreach my $unit (@$units) {
	$started = 1 if $unit eq $start;
	next unless $started;

	last if ($mag / $orig) < $THRESHOLD;
	my $mult = $self->simple_convert($unit, $base);
	my $n = int($mag / $mult);
	next if $n == 0;
	$mag -= $n * $mult;
	push @desc, [ $n, $unit ];
    }

    return @desc;
}

# range_score : amount x unitName -> score
#
# Returns 1 if the value is in range for the unit, 0.1 if the value is
# infinitely close to being in range, and decaying to 0.001 as the
# value approaches infinitely far away from the range.
#
# For the outside of range values, I convert to log space (so 1/400 is
# just as far away from 1 as 400 is). I then treat the allowed range
# as a one standard deviation wide segment of a normal distribution,
# and use appropriate modifiers to make the result range from 0.001 to
# 0.1.
#
# The above formula was carefully chosen from thousands of
# possibilities, by picking things at random and scribbling them down
# on a piece of paper, then pouring sparkling apple cider all over and
# using the one that was still readable.
#
# Ok, not really. Just pretend that I went to that much trouble.
#
sub range_score {
    my ($self, $val, $unitName) = @_;
    my $ranges = $self->get_ranges();
    my $range = $ranges->{$unitName} || $ranges->{default};

    # Return 1 if it's in range
    if ($val >= $range->[0]) {
	if (! defined $range->[1] || ($val <= $range->[1])) {
	    return 1;
	}
    }

    $val = _sillylog($val);

    my $r0 = _sillylog($range->[0]);
    my $r1;
    if (defined $range->[1]) {
	$r1 = _sillylog($range->[1]);
    } else {
	$r1 = 4;
    }

    my $width = $r1 - $r0;
    my $mean = ($r0 + $r1) / 2;
    my $stddev = $width / 2;

    my $n = ($val - $mean) / $stddev; # Normalized value

    our $mulconst;
    $mulconst ||= 0.999 * exp(1/8);

    return 0.001 + $mulconst * exp(-$n**2/2);
}

# Infinity-free logarithm
sub _sillylog {
    my $x = shift;
    return log($x) if $x;
    return log(1e-50);
}

# pref_score : unitName -> score
#
# Maps a unit name (eg week) to a score. Higher scores are more likely
# to be chosen.
sub pref_score {
    my ($self, $unitName) = @_;
    my $prefs = $self->get_prefs();
    my $specific = $prefs->{$unitName};
    return defined($specific) ? $specific : $prefs->{default};
}

# get_prefs : void -> { unit name => score }
#
# Return a map of unit names to their score, higher scores meaning
# they're more likely to be chosen.
sub get_prefs {
    return { default => 0.1 };
}

sub get_ranges {
    return { default => [ 1, undef ] };
}

# render_unit : unit name x power -> descriptive string
#
# Return a rendering of the given unit name and a power to raise the
# unit to.
#
# Example: render_unit("weeks", 2) produces "weeks**2".
#
sub render_unit {
    my ($self, $name, $power, $options) = @_;
    if ($power == 1) {
	return $name;
    } else {
	return "$name**$power";
    }
}

# render : value x name x power -> descriptive string
#
# Return a rendering of the given value with the given units.
#
# Example: render(4.8, "weeks", -1) produces "4.8 weeks**-1".
#
sub render {
    my ($self, $val, $name, $power, $options) = @_;
    return sprintf("%.5g ",$val).$self->render_unit($name, $power, $options);
}

sub construct {
    return;
}

1;
