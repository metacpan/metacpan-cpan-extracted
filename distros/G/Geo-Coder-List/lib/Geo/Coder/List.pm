package Geo::Coder::List;

=head1 NAME

Geo::Coder::List - Provide lots of backends for HTML::GoogleMaps::V3

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

L<Geo::Coder::All> and L<Geo::Coder::Many> are great routines but neither quite does what I want.
This module's primary use is to allow many backends to be used by L<HTML::GoogleMaps::V3>

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Geo::Coder::List object.
=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	# my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# return bless { %args, geocoders => [] }, $class;
	return bless { geocoders => [] }, $class;
}

=head2 push

Add an encoder to list of encoders.

	use Geo::Coder::List;
	use Geo::Coder::GooglePlaces;

	my $list = Geo::Coder::List->new()->push(Geo::Coder::GooglePlaces->new());
=cut

sub push {
	my($self, $geocoder) = @_;

	push @{$self->{geocoders}}, $geocoder;

	return $self;
}

=head2 geocode

Runs geocode on all of the loaded drivers.
See L<Geo::Coder::GooglePlaces::V3> for an explanation
=cut

sub geocode {
	my $self = shift;
	my %params;
	
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} else {
		$params{'location'} = shift;
	}

	my $location = $params{'location'};

	if(!defined($location)) {
		return;
	}

	if((!wantarray) && (my $rc = $locations{$location})) {
		return $rc;
	}

	foreach my $geocoder(@{$self->{geocoders}}) {
		my @rc;
		eval {
			# e.g. over QUERY LIMIT with this one
			# TODO: remove from the list of geocoders
			@rc = $geocoder->geocode(%params);
		};
		next if $@;
		foreach my $location(@rc) {
			# Add HTML::GoogleMaps::V3 compatability
			unless($location->{geometry}{location}{lat}) {
				if($location->{lat}) {
					# OSM
					$location->{geometry}{location}{lat} = $location->{lat};
					$location->{geometry}{location}{lng} = $location->{lon};
				} elsif($location->{BestLocation}) {
					# Bing
					$location->{geometry}{location}{lat} = $location->{BestLocation}->{Coordinates}->{Latitude};
					$location->{geometry}{location}{lng} = $location->{BestLocation}->{Coordinates}->{Longitude};
				} elsif($location->{point}) {
					# Bing
					$location->{geometry}{location}{lat} = $location->{point}->{coordinates}[0];
					$location->{geometry}{location}{lng} = $location->{point}->{coordinates}[1];
				}

			}
		}

		if(scalar(@rc)) {
			if(wantarray) {
				return @rc;
			}
			$locations{$location} = $rc[0];
			return $rc[0];
		}
	}
}


=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-coder-list at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-List>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Geo::Coder::Many>
L<Geo::Coder::All>
L<Geo::Coder::GooglePlaces>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::List


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-List>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-List>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-List>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-List/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016-2017 Nigel Horne.

This program is released under the following licence: GPL

=cut

1;
