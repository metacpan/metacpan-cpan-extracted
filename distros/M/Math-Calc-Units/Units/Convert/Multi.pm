package Math::Calc::Units::Convert::Multi;
use base 'Exporter';
use vars qw(@EXPORT_OK);
BEGIN {
    @EXPORT_OK = qw(to_canonical simple_convert singular
		    variants major_variants
		    major_pref range_score pref_score
		    get_class construct);
};
require Math::Calc::Units::Convert::Time;
require Math::Calc::Units::Convert::Byte;
require Math::Calc::Units::Convert::Date;
require Math::Calc::Units::Convert::Distance;
require Math::Calc::Units::Convert::Combo;
use strict;
use vars qw(@UnitClasses);

@UnitClasses = qw(Math::Calc::Units::Convert::Time
		  Math::Calc::Units::Convert::Byte
		  Math::Calc::Units::Convert::Date
		  Math::Calc::Units::Convert::Distance
		  Math::Calc::Units::Convert::Combo);

# to_canonical : unit -> value
#
sub to_canonical {
    my ($unit) = @_;

    my $val = 1;
    my %newUnit;

    while (my ($unitName, $power) = each %$unit) {
	my ($mult, $canon) = name_to_canonical($unitName);
	$val *= $mult ** $power;

	if (ref $canon) {
	    # Uh oh, it was a combination of basic types
	    my $c = to_canonical($canon);
	    $val *= $c->[0] ** $power;
	    while (my ($name, $subPower) = each %{ $c->[1] }) {
		if (($newUnit{$name} += $subPower * $power) == 0) {
		    delete $newUnit{$name};
		}
	    }
	} else {
	    if (($newUnit{$canon} += $power) == 0) {
		delete $newUnit{$canon};
	    }
	}
    }

    return [ $val, \%newUnit ];
}

# name_to_canonical : unitName -> value x baseUnit
#
# Memoizing this doubles the speed of the test suite.
#
my %CANON_CACHE;
sub name_to_canonical {
    my $unitName = shift;
    $CANON_CACHE{$unitName} ||= [ _name_to_canonical($unitName) ];
    return @{ $CANON_CACHE{$unitName} };
}

sub _name_to_canonical {
    my ($unitName) = @_;

    # First, check for compound units
    if (my $v = Math::Calc::Units::Convert::Combo->lookup_compound($unitName)) {
	return @$v;
    }

    foreach my $uclass (@UnitClasses) {
	if (my ($val, $base) = $uclass->to_canonical($unitName)) {
	    return ($val, $base);
	}
    }
    return Math::Calc::Units::Convert::Base->to_canonical($unitName);
}

sub get_class {
    my ($unitName) = @_;
    my (undef, $canon) = name_to_canonical($unitName);
    foreach my $uclass (@UnitClasses) {
	my $canon_unit = $uclass->canonical_unit();
	next if ! defined $canon_unit;
	return $uclass if $canon_unit eq $canon;
    }
    return 'Math::Calc::Units::Convert::Base';
}

sub simple_convert {
    my ($u, $v) = @_;
    foreach my $uclass (@UnitClasses) {
	my $c;
	return $c if $c = $uclass->simple_convert($u, $v);
    }
    return;
}

sub singular {
    my ($unitName) = @_;
    return get_class($unitName)->singular($unitName);
}

sub variants {
    my ($base) = @_;
    return get_class($base)->variants($base);
}

sub major_variants {
    my ($base) = @_;
    return get_class($base)->major_variants($base);
}

sub major_pref {
    my ($base) = @_;
    return get_class($base)->major_pref($base);
}

sub range_score {
    my ($val, $unitName) = @_;
    die if ref $unitName;
    return get_class($unitName)->range_score($val, $unitName);
}

sub pref_score {
    my ($unitName) = @_;
    die if ref $unitName;
    return get_class($unitName)->pref_score($unitName);
}

sub construct {
    my ($constructor, $args) = @_;
    foreach my $uclass (@UnitClasses) {
	my $c;
	return $c if $c = $uclass->construct($constructor, $args);
    }
    return;
}

1;
