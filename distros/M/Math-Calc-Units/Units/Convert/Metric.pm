package Math::Calc::Units::Convert::Metric;
use base 'Math::Calc::Units::Convert::Base';
use strict;

use vars qw(%niceSmallMetric %metric %pref %abbrev %reverse_abbrev $metric_prefix_test);

%niceSmallMetric = ( milli => 1e-3,
		     micro => 1e-6,
		     nano => 1e-9,
		     pico => 1e-12,
		     femto => 1e-15,
);

%metric = ( kilo => 1e3,
	    mega => 1e6,
	    giga => 1e9,
	    tera => 1e12,
	    peta => 1e15,
	    exa => 1e18,
	    centi => 1e-2,
	    %niceSmallMetric,
);

%pref = ( unit => 1.0,
	  kilo => 0.8,
	  mega => 0.8,
	  giga => 0.8,
	  tera => 0.7,
	  peta => 0.6,
	  exa => 0.3,
	  centi => 0.1,
	  milli => 0.8,
	  micro => 0.8,
	  nano => 0.6,
	  pico => 0.4,
	  femto => 0.3,
);

%abbrev = ( k => 'kilo',
	    M => 'mega',
	    G => 'giga',
	    T => 'tera',
	    P => 'peta',
	    E => 'exa',
	    c => 'centi',
	    m => 'milli',
	    u => 'micro',
	    n => 'nano',
	    p => 'pico',
	    f => 'femto',
);

%reverse_abbrev = reverse %abbrev;

# Cannot use the above tables directly because this class must be
# overridable.  So the following three methods (get_metric,
# get_abbrev, and get_prefix) are the only things that are specific to
# this class. All other methods can be used unchanged in subclasses.

sub pref_score {
    my ($self, $unitName) = @_;
    my $prefix = $self->get_prefix($unitName);
    $unitName = substr($unitName, length($prefix || ""));
    my $prefix_pref = defined($prefix) ? $self->prefix_pref($prefix) : 1;
    return $prefix_pref * $self->SUPER::pref_score($unitName);
}

sub get_metric {
    my ($self, $what) = @_;
    return $metric{$what};
}

sub get_abbrev {
    my ($self, $what) = @_;
    return $abbrev{$what};
}

$metric_prefix_test = qr/^(${\join("|",keys %metric)})/i;

sub get_prefix {
    my ($self, $what) = @_;
    if ($what =~ $metric_prefix_test) {
	return $1;
    } else {
	return;
    }
}

sub get_prefixes {
    my ($self, $options) = @_;
    if ($options->{small}) {
        return grep { $metric{$_} < 1 } keys %metric;
    } else {
        return keys %metric;
    }
}

sub get_abbrev_prefix {
    my ($self, $what) = @_;
    my $prefix = substr($what, 0, 1);
    if ($abbrev{$prefix} || $abbrev{lc($prefix)}) {
	return $prefix;
    } else {
	return;
    }
}

sub variants {
    my ($self, $base) = @_;
    my @main = $self->SUPER::variants($base);
    my @variants;
    for my $u (@main) {
	push @variants, $u, map { "$_$u" } $self->get_prefixes();
    }
    return @variants;
}

sub prefix_pref {
    my ($self, $prefix) = @_;
    return $pref{lc($prefix)} || $pref{unit};
}

# demetric : string => mult x base
#
# (pronounced de-metric, not demmetric or deme trick)
#
sub demetric {
    my ($self, $string) = @_;
    if (my $prefix = $self->get_prefix($string)) {
	my $base = substr($string, length($prefix));
	return ($self->get_metric($prefix), $base);
    } else {
	return (1, $string);
    }
}

# expand : char => ( prefix )
#
sub expand {
    my ($self, $char) = @_;
    my @expansions;
    my ($exact, $lower);
    if ($exact = $self->get_abbrev($char)) {
	push @expansions, $exact;
    } elsif (($char ne lc($char)) && ($lower = $self->get_abbrev(lc($char)))) {
	push @expansions, $lower;
    }
    return @expansions;
}

# simple_convert : unitName x unitName -> multiple:number
#
# A little weird, because it allows centimegamilliwatts
#
# Example:
# megadouble -> millisingle
#
# (mult_from, base_from) is (1_000_000, double)
# (mult_to, base_to) is (.001, single)
# submult is 2 (from converting double -> single)
#
# return submult * (mult_from / mult_to) = 2_000_000_000
#
sub simple_convert {
    my ($self, $from, $to) = @_;

    my ($mult_from, $base_from) = $self->demetric($from) or return;
    my ($mult_to, $base_to) = $self->demetric($to) or return;

    my $submult = $self->SUPER::simple_convert($base_from, $base_to);
    return if ! defined $submult;

    return $submult * ($mult_from / $mult_to);
}

sub metric_abbreviation {
    my ($self, $prefix) = @_;
    return $reverse_abbrev{$prefix} || $prefix;
}

sub render {
    my ($self, $val, $name, $power, $options) = @_;
    if ($options->{abbreviate}) {
        my $stem = $self->canonical_unit;
        if ($name =~ /(\w+)\Q$stem\E$/) {
            my $prefix = $reverse_abbrev{$1};
            if (defined($prefix)) {
                $name = $prefix . $self->abbreviated_canonical_unit;
            }
        }
    }
    return $self->SUPER::render($val, $name, $power, $options);
}

1;
