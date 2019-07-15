package Geo::Coder::Free;

use strict;
use warnings;

use lib '.';

use Config::Auto;
use Geo::Coder::Free::MaxMind;
use Geo::Coder::Free::OpenAddresses;
use List::MoreUtils;
use Carp;

=head1 NAME

Geo::Coder::Free - Provides a Geo-Coding functionality using free databases

=head1 VERSION

Version 0.20

=cut

our $VERSION = '0.20';

our $alternatives;

=head1 SYNOPSIS

    use Geo::Coder::Free;

    my $geo_coder = Geo::Coder::Free->new();
    my $location = $geo_coder->geocode(location => 'Ramsgate, Kent, UK');

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

    # Use a local download of http://results.openaddresses.io/
    my $openaddr_geo_coder = Geo::Coder::Free->new(openaddr => $ENV{'OPENADDR_HOME'});
    $location = $openaddr_geo_coder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

=head1 DESCRIPTION

Geo::Coder::Free provides an interface to free databases by acting as a front-end to
Geo::Coder::Free::MaxMind and Geo::Coder::Free::OpenAddresses.

The cgi-bin directory contains a simple DIY Geo-Coding website.

    cgi-bin/page.fcgi page=query q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA

You can see a sample website at L<https://geocode.nigelhorne.com/>.

    curl 'https://geocode.nigelhorne.com/cgi-bin/page.fcgi?page=query&q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA'

=head1 METHODS

=head2 new

    $geo_coder = Geo::Coder::Free->new();

Takes one optional parameter, openaddr, which is the base directory of
the OpenAddresses data downloaded from L<http://results.openaddresses.io>.

The database also will include data from Who's On First L<https://whosonfirst.org>.

Takes one optional parameter, directory,
which tells the library where to find the MaxMind and GeoNames files admin1db, admin2.db and cities.[sql|csv.gz].
If that parameter isn't given, the module will attempt to find the databases, but that can't be guaranteed.

=cut

sub new {
	my($proto, %param) = @_;
	my $class = ref($proto) || $proto;

	# Geo::Coder::Free->new not Geo::Coder::Free::new
	return unless($class);

	if(!$alternatives) {
		my $keep = $/;
		local $/ = undef;
		my $data = <DATA>;
		$/ = $keep;

		$alternatives = Config::Auto->new(source => $data)->parse();
		foreach my $entry(keys %{$alternatives}) {
			$alternatives->{$entry} = join(', ', @{$alternatives->{$entry}});
		}
	}

	my $rc = {
		maxmind => Geo::Coder::Free::MaxMind->new(%param),
		alternatives => $alternatives
	};

	if((!$param{'openaddr'}) && $ENV{'OPENADDR_HOME'}) {
		$param{'openaddr'} = $ENV{'OPENADDR_HOME'};
	}

	if($param{'openaddr'}) {
		$rc->{'openaddr'} = Geo::Coder::Free::OpenAddresses->new(%param);
	}
	if(my $cache = $param{'cache'}) {
		$rc->{'cache'} = $cache;
	}

	return bless $rc, $class;
}

=head2 geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latitude'}, "\n";
    print 'Longitude: ', $location->{'longitude'}, "\n";

    # TODO:
    # @locations = $geo_coder->geocode('Portland, USA');
    # diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

    # Note that this yields many false positives and isn't useable yet
    my @matches = $geo_coder->geocode(scantext => 'arbitrary text', region => 'US');

=cut

my %common_words = (
	'the' => 1,
	'and' => 1,
	'at' => 1,
	'she' => 1,
	'of' => 1,
	'for' => 1,
	'on' => 1,
	'in' => 1,
	'an' => 1,
	'to' => 1,
	'road' => 1,
	'is' => 1
);

sub geocode {
	my $self = shift;
	my %param;

	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: geocode(location => $location|scantext => $text)');
	} elsif(@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{location} = shift;
	}

	if($self->{'openaddr'}) {
		if(wantarray) {
			my @rc = $self->{'openaddr'}->geocode(\%param);
			if((my $scantext = $param{'scantext'}) && (my $region = $param{'region'})) {
				$scantext =~ s/\W+/ /g;
				foreach my $word(List::MoreUtils::uniq(split(/\s/, $scantext))) {
					# FIXME:  There are a *lot* of false positives
					next if(exists($common_words{lc$word}));
					if($word =~ /^[a-z]{2,}$/i) {
						@rc = (@rc, $self->{'maxmind'}->geocode({ location => $word, region => $region }));
					}

				}
			}
			return @rc if(scalar(@rc) && $rc[0]);
		} elsif(my $rc = $self->{'openaddr'}->geocode(\%param)) {
			return $rc;
		}
		if((!$param{'scantext'}) && (my $alternatives = $self->{'alternatives'})) {
			# Try some alternatives, would be nice to read this from somewhere on line
			my $location = $param{'location'};
			foreach my $left(keys %{$alternatives}) {
				if($location =~ $left) {
					# ::diag($left, '=>', $alternatives->{$left});
					$location =~ s/$left/$alternatives->{$left}/;
					$param{'location'} = $location;
					if(my $rc = $self->geocode(\%param)) {
						return $rc;
					}
				}
			}
		}
	}

	# FIXME:  scantext only works if OPENADDR_HOME is set
	if($param{'location'}) {
		if(wantarray) {
			my @rc = $self->{'maxmind'}->geocode(\%param);
			return @rc;
		} else {
			return $self->{'maxmind'}->geocode(\%param);
		}
	}
	if(!$param{'scantext'}) {
		Carp::croak('Usage: geocode(location => $location|scantext => $text)');
	}
}

=head2 reverse_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

To be done.

=cut

sub reverse_geocode {
	my $self = shift;
	my %param;

	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: geocode(location => $location|scantext => $text)');
	} elsif(@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{location} = shift;
	}

	# The drivers don't yet support it
	if($self->{'openaddr'}) {
		if(wantarray) {
			my @rc = $self->{'openaddr'}->geocode(\%param);
			return @rc;
		} elsif(my $rc = $self->{'openaddr'}->geocode(\%param)) {
			return $rc;
		}
	}

	if($param{'location'}) {
		if(wantarray) {
			my @rc = $self->{'maxmind'}->geocode(\%param);
			return @rc;
		} else {
			return $self->{'maxmind'}->geocode(\%param);
		}
	}

	Carp::croak('Reverse lookup is not yet supported');
}

=head2	ua

Does nothing, here for compatibility with other Geo-Coders

=cut

sub ua {
}

=head2 run

You can also run this module from the command line:

    perl lib/Geo/Coder/Free.pm 1600 Pennsylvania Avenue NW, Washington DC

=cut

__PACKAGE__->run(@ARGV) unless caller();

sub run {
	require Data::Dumper;

	my $class = shift;

	my $location = join(' ', @_);

	my @rc;
	if($ENV{'OPENADDR_HOME'}) {
		@rc = $class->new(openaddr => $ENV{'OPENADDR_HOME'})->geocode($location);
	} else {
		@rc = $class->new()->geocode($location);
	}

	die "$0: geocoding failed" unless(scalar(@rc));

	print Data::Dumper->new([\@rc])->Dump();
}

sub _normalize {
	my $type = uc(shift);

	$type = uc($type);

	if(($type eq 'AVENUE') || ($type eq 'AVE')) {
		return 'AVE';
	} elsif(($type eq 'STREET') || ($type eq 'ST')) {
		return 'ST';
	} elsif(($type eq 'ROAD') || ($type eq 'RD')) {
		return 'RD';
	} elsif(($type eq 'COURT') || ($type eq 'CT')) {
		return 'CT';
	} elsif(($type eq 'CIR') || ($type eq 'CIRCLE')) {
		return 'CIR';
	} elsif(($type eq 'FT') || ($type eq 'FORT')) {
		return 'FT';
	} elsif(($type eq 'CTR') || ($type eq 'CENTER')) {
		return 'CTR';
	} elsif(($type eq 'PARKWAY') || ($type eq 'PKWY')) {
		return 'PKWY';
	} elsif($type eq 'BLVD') {
		return 'BLVD';
	} elsif($type eq 'PIKE') {
		return 'PIKE';
	} elsif(($type eq 'DRIVE') || ($type eq 'DR')) {
		return 'DR';
	} elsif(($type eq 'SPRING') || ($type eq 'SPG')) {
		return 'SPRING';
	} elsif(($type eq 'RDG') || ($type eq 'RIDGE')) {
		return 'RDG';
	} elsif(($type eq 'CRK') || ($type eq 'CREEK')) {
		return 'CRK';
	} elsif(($type eq 'LANE') || ($type eq 'LN')) {
		return 'LN';
	} elsif(($type eq 'PLACE') || ($type eq 'PL')) {
		return 'PL';
	} elsif(($type eq 'GRDNS') || ($type eq 'GARDENS')) {
		return 'GRDNS';
	} elsif(($type eq 'HWY') || ($type eq 'HIGHWAY')) {
		return 'HWY';
	}

	# Most likely failure of Geo::StreetAddress::US, but warn anyway, just in case
	if($ENV{AUTHOR_TESTING}) {
		# warn $self->{'location'}, ": add type $type";
		warn "Add type $type";
	}
}

=head1 AUTHOR

Nigel Horne <njh@bandsman.co.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 GETTING STARTED

Before you start,
install L<App::csv2sqlite>;
optionally set the environment variable OPENADDR_HOME to point to an empty directory and download the data from L<http://results.openaddresses.io> into that directory;
optionally set the environment variable WHOSONFIRST_HOME to point to an empty directory and download the data using L<https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-sqlite-download>.
You do not need to download the MaxMind data, that will be downloaded automatically.

=head1 MORE INFORMATION

I've written a few Perl related Genealogy programs including gedcom (L<https://github.com/nigelhorne/gedcom>)
and ged2site (L<https://github.com/nigelhorne/ged2site>).
One of the things that these do is to check the validity of your family tree, and one of those tasks is to verify place-names.
Of course places do change names and spelling becomes more consistent over the years, but the vast majority remain the same.
Enough of a majority to computerise the verification.
Unfortunately all of the on-line services have one problem or another - most either charge for large number of access, or throttle the number of look-ups.
Even my modest tree, just over 2000 people, reaches those limits.

There are, however, a number of free databases that can be used, including MaxMind, GeoNames, OpenAddresses and WhosOnFirst.
The objective of Geo::Coder::Free (L<https://github.com/nigelhorne/Geo-Coder-Free>)
is to create a database of those databases and to create a search engine either through a local copy of the database or through an on-line website.
Both are in their early days, but I have examples which do surprisingly well.

The local copy of the database is built using the createdatabase.PL script which is bundled with G:C:F.
That script creates a single SQLite file from downloaded copies of the databases listed above, to create the database you will need
to first install L<App::csv2sqlite>.
Running 'make' will download GeoNames and MaxMind, but OpenAddresses and WhosOnFirst need to be downloaded manually if you decide to use them - they are treated as optional by G:C:F.

There is a sample website at L<https://geocode.nigelhorne.com/>.  The source code for that site is included in the G:C:F distribution.

=head1 BUGS

Some lookups fail at the moments, if you find one please file a bug report.

Doesn't include results from
L<Geo::Coder::Free::Local>.

The MaxMind data only contains cities.
The OpenAddresses data doesn't cover the globe.

Can't parse and handle "London, England".

=head1 SEE ALSO

VWF, OpenAddresses, MaxMind and geonames.

See L<Geo::Coder::Free::OpenAddresses> for instructions creating the SQLite database from
L<http://results.openaddresses.io/>.

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2019 Nigel Horne.

The program code is released under the following licence: GPL for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at `<njh at nigelhorne.com>`.

This product uses GeoLite2 data created by MaxMind, available from
L<https://www.maxmind.com/en/home>. See their website for licensing information.

This product uses data from Who's on First.
See L<https://github.com/whosonfirst-data/whosonfirst-data/blob/master/LICENSE.md> for licensing information.

=cut

1;

# Common mappings allowing looser lookups
# Would be nice to read this from somewhere on-line
# See also lib/Geo/Coder/Free/Local.pm
__DATA__
St Lawrence, Thanet, Kent = Ramsgate, Kent
St Peters, Thanet, Kent = St Peters, Kent
Minster, Thanet, Kent = Ramsgate, Kent
