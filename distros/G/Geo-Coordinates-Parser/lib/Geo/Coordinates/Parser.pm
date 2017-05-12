package Geo::Coordinates::Parser;

our $VERSION = '0.01';

use strict;
use warnings;
use Geo::Coordinates::DecimalDegrees qw(dms2decimal dm2decimal);

=pod

=head1 NAME

Geo::Coordinates::Parser - A coordinate parser class.

=head1 SYNOPSIS

	use Geo::Coordinates::Parser;
	my $coordinateparser = Geo::Coordinates::Parser->new('.');
	my $decimaldegree = $coordinateparser->parse(q{E25°42'60"});
	$decimaldegree = $coordinateparser->parse(q{E25.12346"});


=head1 DESCRIPTION

This module provides a method for parsing a coordinate string.


=head1 METHODS

This module provides the following methods:

=over 4

=item new($decimal_delimiter)

Returns a new Geo::Coordinates::Parser object. The decimal
delimiter can be given as an argument. If no argument is
given then period "." character is used as decimal delimiter.

Usage:

	my $coordinateparser = Geo::Coordinates::Parser->new(); # or
	my $coordinateparser = Geo::Coordinates::Parser->new('.'); # same as above, or
	my $coordinateparser = Geo::Coordinates::Parser->new(','); # , is the decimal delimiter

=cut
sub new {
	my $class = shift;
	my $decimal_delimiter = shift || '.';
	my $self = {'decimal_delimiter' => $decimal_delimiter};
	bless($self, $class);

	return $self;
}

=pod

=item parse($coordinatestring)

Parses the coordinate string and returns it's decimal value.
It uses L<Geo::Coordinates::DecimalDegrees> to turn degrees,
minutes and seconds into the equivalent decimal degree. The 
argument can be either a longitude or a latitude. It doesn't
test the sanity of the data. The method simply removes all
unnecessary characters and then converts the degrees,
minutes and seconds to a decimal degree.

Usage:

	my $decimal = $coordinateparser->parse('E25'42'60');

=cut
sub parse {
	my $self = shift;
	my $coordinatestring = shift;
	unless ($coordinatestring) {
		return undef;
	}
	
	# Remove all extra
	my $decimal_delimiter = $self->decimal_delimiter;
	$coordinatestring =~ s/[^0-9$decimal_delimiter]/ /g;
	$coordinatestring =~ s/^\s+//;
	$coordinatestring =~ s/\s+$//;
	
	# Split into degrees, minutes and seconds
	my ($degrees, $minutes, $seconds) = split(/\s+/, $coordinatestring);

	# Return in decimal format with the right delimiter
	if ($minutes and $seconds) {
		return dms2decimal($degrees, $minutes, $seconds);
	} elsif ($minutes and not $seconds) {
		return dm2decimal($degrees, $minutes);
	} else {
		return $degrees;
	}
}

=pod

=item decimal_delimiter($decimal_delimiter)

Returns the decimal delimiter. If an argument is given then
it's sets the delimiter to the given value.

Usage:

	$coordinateparser->decimal_delimiter; # Returns the delimiter
	$coordinateparser->decimal_delimiter(','); # Sets and returns , as the delimiter
	$coordinateparser->decimal_delimiter; # Returns now , as the delimiter

=cut
sub decimal_delimiter {
	my $self = shift;
	my $decimal_delimiter = shift;
	if ($decimal_delimiter) {
		$self->{'decimal_delimiter'} = $decimal_delimiter;
	}
	return $self->{'decimal_delimiter'}; 
}

1;

=pod
	
=back


=head1 REQUIRES

L<Geo::Coordinates::DecimalDegrees>


=head1 SEE ALSO

L<Geo::Coordinates::DecimalDegrees>


=head1 AUTHOR

Carl Räihä, <carl.raiha at gmail.com>


=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Carl Räihä / Frantic Media

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
