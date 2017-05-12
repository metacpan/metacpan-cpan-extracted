package Math::Calc::Units::Convert::Combo;
use base 'Math::Calc::Units::Convert::Base2Metric';
use strict;
use vars qw(%units %metric_units %prefixable_metric_units %total_unit_map);
use vars qw(%ranges %pref);

%units = (
);

%metric_units = (
);

%prefixable_metric_units = ( bps => [ 1, { bit => 1, sec => -1 } ] );

%ranges = ( default => [ 1, 999 ] );

%pref = ( default => 1 );

sub canonical_unit { return; }

sub unit_map {
    my ($self) = @_;
    if (keys %total_unit_map == 0) {
	%total_unit_map = (%{$self->SUPER::unit_map()},
			   %units,
			   %metric_units,
			   %prefixable_metric_units);
    }
    return \%total_unit_map;
}

# Singular("Mbps") is Mbps, not Mbp
sub singular {
    my ($self, $unit) = @_;
    return $self->SUPER::singular($unit) unless $unit =~ /bps$/;
    return $unit;
}

# demetric : string => mult x base
#
sub demetric {
    my ($self, $string) = @_;
    if (my $prefix = $self->get_prefix($string)) {
	my $tail = lc($self->singular(substr($string, length($prefix))));
	if ($metric_units{$tail}) {
	    return ($self->get_metric($prefix), $tail);
	}
    } elsif (my $abbrev = $self->get_abbrev_prefix($string)) {
	my $tail = lc($self->singular(substr($string, length($abbrev))));
	if ($prefixable_metric_units{$tail}) {
	    my $prefix = $self->get_abbrev($abbrev);
	    return ($self->get_metric($prefix), $tail);
	}
    }

    return (1, $string);
}

# to_canonical : unitName -> amount x unitName
#
sub to_canonical { return; }

sub lookup_compound {
    my ($self, $unitName) = @_;

    foreach (keys %units, keys %metric_units, keys %prefixable_metric_units) {
	if (my $mult = $self->simple_convert($unitName, $_)) {
	    my $u = $units{$_}
	            || $metric_units{$_}
	            || $prefixable_metric_units{$_};
	    return [ $mult * $u->[0], $u->[1] ];
	}
    }

    return;
}

sub get_ranges {
    return \%ranges;
}

sub get_prefs {
    return \%pref;
}

1;
