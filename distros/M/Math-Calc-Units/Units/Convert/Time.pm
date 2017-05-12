package Math::Calc::Units::Convert::Time;
use base 'Math::Calc::Units::Convert::Metric';
use strict;
use vars qw(%units %pref %ranges %total_unit_map);

%units = ( minute => [ 60, 'sec' ],
	   hour => [ 60, 'minute' ],
	   day => [ 24, 'hour' ],
	   week => [ 7, 'day' ],
           year => [ 365, 'day' ], # Inexact unit... ugh...
);

%pref = ( default => 1,
	  hour => 0.8,
	  day => 0.8,
	  week => 0.4,
	  minute => 0.9,
          year => 0.9,
);

%ranges = ( default => [ 1, 300 ],
	    millisec => [ 1, 999 ],
	    sec => [ 1, 200 ],
	    minute => [ 2, 100 ],
	    hour => [ 1, 80 ],
	    day => [ 1, 500 ],
	    week => [ 1, 4 ],
            year => [ 1, undef ],
);

sub major_pref {
    return 2;
}

sub major_variants {
    my ($self) = @_;
    return grep { ($_ ne 'default') && ($_ ne 'week') } keys %ranges;
}

# Return a list of the variants of the canonical unit of time: 'sec'
sub variants {
    my ($self, $base) = @_;
    return 'sec', (keys %units), map { "${_}sec" } $self->get_prefixes({ small => 1 });
}

sub unit_map {
    my ($self) = @_;
    if (keys %total_unit_map == 0) {
	%total_unit_map = (%{$self->SUPER::unit_map()}, %units);
    }
    return \%total_unit_map;
}

sub canonical_unit { return 'sec'; }

sub abbreviated_canonical_unit { return 's'; }

# demetric : string => [ mult, base ]
#
# Must override here to avoid megahours or milliweeks
#
sub demetric {
    my ($self, $string) = @_;
    if (my $prefix = $self->get_prefix($string)) {
	my $tail = substr($string, length($prefix));
	if ($tail =~ /^sec(ond)?s?$/) {
	    return ($self->get_metric($prefix), "sec");
	}
	return; # Should this fail, or assume it's a non-metric unit?
    } else {
	return (1, $string);
    }
}

# simple_convert : unitName x unitName -> multiplier
#
# Does not allow msec (only millisec or ms)
#
sub simple_convert {
    my ($self, $from, $to) = @_;

    # sec, secs, second, seconds
    $from = "sec" if $from =~ /^sec(ond)?s?$/i;
    $from = "minute" if $from =~ /^min(ute)?s?$/i;

    if (my $easy = $self->SUPER::simple_convert($from, $to)) {
	return $easy;
    }

    # ms == millisec
    if ($from =~ /^(.)s$/) {
	my ($expansion) = $self->expand($1);
        return $self->simple_convert($expansion . "sec", $to);
    }

    return; # Failed
}

##############################################################################

sub preference {
    my ($self, $v) = @_;
    my ($val, $unit) = @$v;
    my $base = lc(($self->demetric($unit))[1]);
    my $pref = $pref{$base} || $pref{default};
    return $pref * $self->prefix_pref(substr($unit, 0, -length($base)));
}

sub get_ranges {
    return \%ranges;
}

sub get_prefs {
    return \%pref;
}

my @BREAKDOWN = qw(year week day hour minute sec ms us ns ps);
sub render {
    my ($self, $val, $name, $power, $options) = @_;
    my $full_name = $name;
    if ($options->{abbreviate}) {
        if ($name =~ /(\w+)sec/) {
            my $prefix = $1;
            my $mabbrev = $self->metric_abbreviation($prefix);
            $name = $mabbrev . "s" unless $mabbrev eq $prefix;
        }
    }
    my $basic = $self->SUPER::render($val, $name, $power, $options);
    return $basic if $power != 1;

    $val *= $self->simple_convert($full_name, 'sec');
    my @spread = $self->spread($val, 'sec', $name, \@BREAKDOWN);
    my $spread = join(" ", map { "$_->[0] $_->[1]" } @spread);

    return "($basic = $spread)" if @spread > 1;
    return $basic;
}

1;
