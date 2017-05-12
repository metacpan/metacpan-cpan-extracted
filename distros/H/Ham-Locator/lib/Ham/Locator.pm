#!/usr/bin/perl

#=======================================================================
# Locator.pm / Ham::Locator
# $Id: Locator.pm 10 2011-01-16 15:36:53Z andys $
# $HeadURL: http://daedalus.dmz.dn7.org.uk/svn/Ham-Locator/lib/Ham/Locator.pm $
# (c)2010 Andy Smith <andy.smith@nsnw.co.uk>
#-----------------------------------------------------------------------
#:Description
# Module to easily convert between Maidenhead locators and coordinates
# in latitude and longitude format.
#-----------------------------------------------------------------------
#:Synopsis
#
# use Ham::Locator;
# my $m = new Ham::Locator;
# $m->set_loc('IO93lo');
# my ($latitude, $longitude) = $m->loc2latlng;
#=======================================================================
#
# With thanks to:-
# * http://home.arcor.de/waldemar.kebsch/The_Makrothen_Contest/fmaidenhead.js
# * http://no.nonsense.ee/qthmap/index.js

# The pod (Perl documentation) for this module is provided inline. For a
# better-formatted version, please run:-
# $ perldoc Locator.pm

=head1 NAME

Ham::Locator - Convert between Maidenhead locators and latitude/longitude.

=head1 SYNOPSIS

  use Ham::Locator;
  my $m = new Ham::Locator;
  $m->set_loc('IO93lo');
  my ($latitude, $longitude) = $m->loc2latlng;

=head1 DEPENDENCIES

=over4

=item * Carp - for error handling

=item * Class::Accessor - for accessor method generation

=back

=cut

# Module setup
package Ham::Locator;

use strict;
use warnings;

our $VERSION = '0.1000';

# Module inclusion
use Carp;
use Data::Dumper;
use POSIX qw(floor fmod);

# Set up accessor methods with Class::Accessor
use base qw(Class::Accessor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( qw(loc latlng precision) );

=head1 CONSTRUCTORS

=head2 Locator->new

Creates a new C<Ham::Locator> object.

=head1 ACCESSORS 

=head2 $locator->set_loc(I<locator>)

Sets the locator to use for conversion to latitude and longitude.

=head2 $locator->set_latlng((I<latitude>, I<longitude>))

Sets the longitude and latitude to use for conversion to the locator.

=head2 $locator->set_precision(I<precision>)

Sets the number of characters of the locator reference to return when calling B<latlng2loc>.

=cut

sub l2n
{
	my ($self, $letter) = @_;

	my $lw = lc $letter;

	my $index = {	'a' => 0,
					'b' => 1,
					'c' => 2,
					'd' => 3,
					'e' => 4,
					'f' => 5,
					'g' => 6,
					'h' => 7,
					'i' => 8,
					'j' => 9,
					'k' => 10,
					'l' => 11,
					'm' => 12,
					'n' => 13,
					'o' => 14,
					'p' => 15,
					'q' => 16,
					'r' => 17,
					's' => 18,
					't' => 19,
					'u' => 20,
					'v' => 21,
					'w' => 22,
					'x' => 23
	};

	return $index->{$lw};
};

sub n2l
{
	my ($self, $number) = @_;

	my $index = {	0 => 'a',
					1 => 'b',
					2 => 'c',
					3 => 'd',
					4 => 'e',
					5 => 'f',
					6 => 'g',
					7 => 'h',
					8 => 'i',
					9 => 'j',
					10 => 'k',
					11 => 'l',
					12 => 'm',
					13 => 'n',
					14 => 'o',
					15 => 'p',
					16 => 'q',
					17 => 'r',
					18 => 's',
					19 => 't',
					20 => 'u',
					21 => 'v',
					22 => 'w',
					23 => 'x'
	};

	return $index->{$number};
};

=head1 METHODS

=head2 $locator->latlng2loc

converts the latitude and longitude set by B<set_latlng> to the locator, and returns it as a string.

=cut

sub latlng2loc
{
	my ($self) = @_;

	if($self->get_latlng eq "")
	{
		return 0;
	}

	my $latlng = $self->get_latlng;

	my $field_lat	= @{$latlng}[0];
	my $field_lng	= @{$latlng}[1];

	my $locator;

	my $lat = $field_lat + 90;
	my $lng = $field_lng + 180;

	# Field
	$lat = ($lat / 10) + 0.0000001;
	$lng = ($lng / 20) + 0.0000001;
	$locator .= uc($self->n2l(floor($lng))).uc($self->n2l(floor($lat)));

	# Square
	$lat = 10 * ($lat - floor($lat));
	$lng = 10 * ($lng - floor($lng));
	$locator .= floor($lng).floor($lat);
	
	# Subsquare
	$lat = 24 * ($lat - floor($lat));
	$lng = 24 * ($lng - floor($lng));
	$locator .= $self->n2l(floor($lng)).$self->n2l(floor($lat));

	# Extended square
	$lat = 10 * ($lat - floor($lat));
	$lng = 10 * ($lng - floor($lng));
	$locator .= floor($lng).floor($lat);
	
	# Extended Subsquare
	$lat = 24 * ($lat - floor($lat));
	$lng = 24 * ($lng - floor($lng));
	$locator .= $self->n2l(floor($lng)).$self->n2l(floor($lat));

	if($self->get_precision)
	{
		return substr $locator, 0, $self->get_precision;
	}
	else
	{
		return $locator;
	}
}
	

=head2 $locator->loc2latlng

Converts the locator set by B<set_loc> to latitude and longitude, and returns them as an array of two values.

=cut

sub loc2latlng
{
	my ($self) = @_;

	if($self->get_loc eq "")
	{
		return 0;
	}

	my $loc = $self->get_loc;

	if(length $loc lt 4)
	{
		$loc .= "55LL55LL";
	}
	elsif(length $loc lt 6)
	{
		$loc .= "LL55LL";
	}
	elsif(length $loc lt 8)
	{
		$loc .= "55LL";
	}
	elsif(length $loc lt 10)
	{
		$loc .= "LL";
	}

	if($loc !~ m/[a-rA-R]{2}[0-9]{2}[a-xA-X]{2}[0-9]{2}[a-xA-X]{2}/)
	{
		print "Not a valid locator.\n";
		return 0;
	}

	$loc = lc($loc);

	my $i = 0;
	my @l = ();

	while ($i < 10)
	{
		my $a = substr $loc, $i, 1;
		if($a =~ m/[a-zA-Z]/)
		{
			$l[$i] = $self->l2n($a);
		}
		else
		{
			$l[$i] = int(substr $loc, $i, 1);
		}
		$i++;
	}

	my $lng = (($l[0] * 20) + ($l[2] * 2) + ($l[4]/12) + ($l[6]/120) + ($l[8]/2880) - 180);
	my $lat = (($l[1] * 10) + $l[3] + ($l[5]/24) + ($l[7]/240) + ($l[9]/5760) - 90);

	return ($lat, $lng);

};

=head1 CAVEATS

=head1 BUGS

=item1 * None, hopefully!

This module was written by B<Andy Smith> <andy.smith@netprojects.org.uk>.

=head1 COPYRIGHT

$Id: Locator.pm 10 2011-01-16 15:36:53Z andys $

(c)2009 Andy Smith (L<http://andys.org.uk/>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
