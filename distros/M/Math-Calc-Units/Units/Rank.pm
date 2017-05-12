package Math::Calc::Units::Rank;
use base 'Exporter';
use vars qw(@EXPORT_OK);
BEGIN { @EXPORT_OK = qw(choose_juicy_ones render render_unit); }

use Math::Calc::Units::Convert qw(convert canonical);
use Math::Calc::Units::Convert::Multi qw(variants major_variants major_pref pref_score range_score get_class);
use strict;

# choose_juicy_ones : value -> ( value )
#
# Pick the best-sounding units for the given value, and compute the
# resulting magnitude and score. The total number returned is based on
# a magical formula that examines the rates of decay of the scores.
#
sub choose_juicy_ones {
    my ($v, $options) = @_;

    # Collect the variants of the value, together with their scores.
    my @variants = rank_variants($v, $options); # ( < {old=>new}, score > )

    # Remove duplicates
    my %variants; # To remove duplicates: { id => [ {old=>new}, score ] }
    for my $variant (@variants) {
	my $id = join(";;", values %{ $variant->[0] });
	$variants{$id} = $variant;
    }

    my @options;
    for my $variant (values %variants) {
	my ($map, $score) = @$variant;
	my %copy;
        my ($magnitude, $units) = @$v;
	while (my ($unit, $count) = each %$units) {
	    $copy{$map->{$unit}} = $count;
	}
	push @options, [ $score, convert($v, \%copy) ];
    }

    # Pick up to five of the highest scores. If any score is less than
    # 1/10 of the previous score, or 1/25 of the highest score, then
    # don't bother returning it (or anything worse than it.)
    my @juicy;
    my $first;
    my $prev;
    foreach (sort { $b->[0] <=> $a->[0] } @options) {
        my ($score, $val) = @$_;
        last if (defined $prev && ($prev / $score) > 8);
        last if (defined $first && ($first / $score) > 25);
        push @juicy, $val;
        $first = $score unless defined $first;
        $prev = $score;
        last if @juicy == 5;
    }

    return @juicy;
}

# rank_variants : <amount,unit> -> ( < map, score > )
# where map : {original unit => new unit}
#
sub rank_variants {
    my ($v, $options) = @_;

    $v = canonical($v);

    my ($mag, $count) = @$v;

    my @rangeable = grep { $count->{$_} > 0 } keys %$count;
    if (@rangeable == 0) {
	@rangeable = keys %$count;
    }

    return rank_power_variants($mag, \@rangeable, $count, $options);
}

sub choose_major {
    my (@possibilities) = @_;
    my @majors = map { [ major_pref($_), $_ ] } @possibilities;
    return (sort { $a->[0] <=> $b->[0] } @majors)[-1]->[1];
}

# rank_power_variants : value x [unit] x {unit=>power} x options ->
#  ( <map,score> )
#
# $top is the set of units that should be range checked.
#
sub rank_power_variants {
    my ($mag, $top, $power, $options) = @_;

    # Recursive case: we have multiple units left, so pick one to be
    # the "major" unit and select the best combination of the other
    # units for each major variant on the major unit.

    if (keys %$power > 1) {
	# Choose the major unit class (this will return the best
	# result for each of the major variants)
	my $major = choose_major(keys %$power);
	my $majorClass = get_class($major);

	my %powerless = %$power;
	delete $powerless{$major};

	my @ranked; # ( <map,score> )

	# Try every combination of each major variant and the other units
	foreach my $variant (major_variants($major, $options)) {
	    my $mult = $majorClass->simple_convert($variant, $major);
	    my $cval = $mag / $mult ** $power->{$major};

	    print "\n --- for $variant ---\n" if $options->{verbose};
	    my @r = rank_power_variants($cval, $top, \%powerless, $options);
	    next if @r == 0;

	    my $best = $r[0];
	    $best->[0]->{$major} = $variant; # Augment map
	    # Replace score with major pref
	    $best->[1] = pref_score($variant);
	    push @ranked, $best;
	}

	return @ranked;
    }

    # Base case: have a single unit left. Go through all possible
    # variants of that unit.

    if (keys %$power == 0) {
	# Special case: we don't have any units at all
	return [ {}, 1 ];
    }

    my $unit = (keys %$power)[0];
    $power = $power->{$unit}; # Now it's just the power of this unit
    my $class = get_class($unit);
    my (undef, $canon) = $class->to_canonical($unit);
    my $mult = $class->simple_convert($unit, $canon);
    $mag *= $mult ** $power;

    my @choices;
    my @subtop = grep { $_ ne $canon } @$top;
    my $add_variant = (@subtop == @$top); # Flag: add $variant to @$top?

    foreach my $variant (variants($canon)) {
	# Convert from $canon to $variant
	# Input: 4000 / sec             ; (canon=sec)
	# 1 ms -> .001 sec              ; (variant=ms)
	# 4000 / (.001 ** -1) = 4 / ms
	my $mult = $class->simple_convert($variant, $canon);
	my $minimag = $mag / $mult ** $power;

        my @vtop = @subtop;
        push @vtop, $variant if $add_variant;

	my $score = score($minimag, $variant, \@vtop);
	printf "($mag $unit) score %.6f:\t $minimag $variant\n", $score
	    if $options->{verbose};
	push @choices, [ $score, $variant ];
    }

    @choices = sort { $b->[0] <=> $a->[0] } @choices;
    return () if @choices == 0;

    return map { [ {$unit => $_->[1]}, $_->[0] ] } @choices;
}

# Return a string representing a given set of units. The input is a
# map from unit names to their powers (eg lightyears/sec/sec would be
# represented as { lightyears => 1, sec => -2 }); the output is a
# corresponding string such as "lightyears / sec**2".
sub render_unit {
    my ($units, $options) = @_;

    # Positive powers just get appended together with spaces between
    # them.
    my $str = '';
    while (my ($name, $power) = each %$units) {
	if ($power > 0) {
	    $str .= get_class($name)->render_unit($name, $power, $options);
	    $str .= " ";
	}
    }
    chop($str);

    # Negative powers will be placed after a "/" character, because
    # they're in the denominator.
    my $botstr = '';
    while (my ($name, $power) = each %$units) {
	if ($power < 0) {
	    $botstr .= get_class($name)->render_unit($name, -$power, $options);
	    $botstr .= " ";
	}
    }
    chop($botstr);

    # Combine the numerator and denominator appropriately.
    if ($botstr eq '') {
	return $str;
    } elsif ($botstr =~ /\s/) {
	return "$str / ($botstr)";
    } else {
	return "$str / $botstr";
    }
}

# render : <value,unit> -> string
sub render {
    my ($v, $options) = @_;
    my ($mag, $units) = @$v;

    # No units
    if (keys %$units == 0) {
	# Special-case percentages
	my $str = sprintf("%.4g", $mag);
	if (($mag < 1) && ($mag >= 0.01)) {
            if ($options->{abbreviate}) {
                $str .= sprintf(" = %.4g percent", 100 * $mag);
            } else {
                $str .= sprintf(" = %.4g%%", 100 * $mag);
            }
	}
	return $str;
    }

    my @top;
    my @bottom;
    while (my ($name, $power) = each %$units) {
	if ($power > 0) {
	    push @top, $name;
	} else {
	    push @bottom, $name;
	}
    }

    my $str;
    if (@top == 1) {
	my ($name) = @top;
	$str = get_class($name)->render($mag, $name, $units->{$name}, $options);
	$str .= " ";
    } else {
	$str = sprintf("%.4g ", $mag);
	foreach my $name (@top) {
	    $str .= get_class($name)->render_unit($name, $units->{$name}, $options);
	    $str .= " ";
	}
    }

    if (@bottom > 0) {
	my $botstr;
	foreach my $name (@bottom) {
	    $botstr .= get_class($name)->render_unit($name, -$units->{$name}, $options);
	    $botstr .= " ";
	}
	chop($botstr);

	if (@bottom > 1) {
	    $str .= "/ ($botstr) ";
	} else {
	    $str .= "/ $botstr ";
	}
    }

    chop($str);
    return $str;
}

# max_range_score : amount x [ unit ] -> score
#
# Takes max score for listed units.
#
sub max_range_score {
    my ($mag, $units) = @_;
    my $score = 0;

    foreach my $name (@$units) {
	my $uscore = range_score($mag, $name);
	$score = $uscore if $score < $uscore;
    }

    return $score;
}

# Arguments:
#  $mag - The magnitude of the value (in the given unit)
#  $unit - The unit to use to figure out what sounds best
#  $top - ...I'll get back to you...
sub score {
    my ($mag, $unit, $top) = @_;
    my @rangeable = @$top ? @$top : ($unit);
    my $pref = pref_score($unit);
    my $range_score = max_range_score($mag, \@rangeable);
    return $pref * $range_score;
}

1;
