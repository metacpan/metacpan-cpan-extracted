package Geo::Coder::Free;

# TODO: Don't have Maxmind as a separate database
# TODO: Rename openaddresses.sql as geo_coder_free.sql
# TODO: Consider Data::Dumper::Names instead of Data::Dumper
# TODO: use the cache to store common queries

use strict;
use warnings;

# use lib '.';

use Array::Iterator;
use Config::Auto;
use Data::Dumper;
use Geo::Coder::Abbreviations;
use Geo::Coder::Free::MaxMind;
use Geo::Coder::Free::OpenAddresses;
use List::MoreUtils;
use Locale::US;
use Carp;
use Scalar::Util;

=head1 NAME

Geo::Coder::Free - Provides a Geo-Coding functionality using free databases

=head1 VERSION

Version 0.38

=cut

our $VERSION = '0.38';

our $alternatives;
our $abbreviations;

sub _abbreviate($);
sub _normalize($);

=head1 SYNOPSIS

    use Geo::Coder::Free;

    my $geo_coder = Geo::Coder::Free->new();
    my $location = $geo_coder->geocode(location => 'Ramsgate, Kent, UK');

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

    # Use a local download of http://results.openaddresses.io/ and https://www.whosonfirst.org/
    my $openaddr_geo_coder = Geo::Coder::Free->new(openaddr => $ENV{'OPENADDR_HOME'});
    $location = $openaddr_geo_coder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

=head1 DESCRIPTION

Geo::Coder::Free provides an interface
to translate addresses into latitude and longitude
by using to free databases such as
L<Geo::Coder::Free::MaxMind> and L<Geo::Coder::Free::OpenAddresses>.

The cgi-bin directory contains a simple DIY Geo-Coding website.

    cgi-bin/page.fcgi page=query q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA

The sample website is down at the moment while I look for a new host.
When it's back up you will be able to use this to test it.

    curl 'https://geocode.nigelhorne.com/cgi-bin/page.fcgi?page=query&q=1600+Pennsylvania+Avenue+NW+Washington+DC+USA'

Includes functionality for running the module via the command line for testing or ad-hoc geocoding tasks.

=head1 METHODS

=head2 new

    $geo_coder = Geo::Coder::Free->new();

Takes one optional parameter, openaddr, which is the base directory of
the OpenAddresses data from L<http://results.openaddresses.io>,
and Who's On First data from L<https://whosonfirst.org>.

Takes one optional parameter, directory,
which tells the object where to find the MaxMind and GeoNames files admin1db,
admin2.db and cities.[sql|csv.gz].
If that parameter isn't given,
the module will attempt to find the databases,
but that can't be guaranteed to work.

=cut

sub new {
	my $class = shift;

	# Handle hash or hashref arguments
	my %args;
	if((@_ == 1) && (ref $_[0] eq 'HASH')) {
		%args = %{$_[0]};
	} elsif((@_ % 2) == 0) {
		%args = @_;
	} else {
		carp(__PACKAGE__, ': Invalid arguments passed to new()');
		return;
	}

	if(!defined($class)) {
		if((scalar keys %args) > 0) {
			# Using Geo::Coder::Free->new not Geo::Coder::Free::new
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	if(!$alternatives) {
		my $keep = $/;
		local $/ = undef;
		my $data = <DATA>;
		$/ = $keep;

		$alternatives = Config::Auto->new(source => $data)->parse();
		while(my ($key, $value) = (each %{$alternatives})) {
			$alternatives->{$key} = join(', ', @{$value});
		}
	}
	my $rc = {
		%args,
		maxmind => Geo::Coder::Free::MaxMind->new(%args),
		alternatives => $alternatives
	};

	if((!defined $args{'openaddr'}) && $ENV{'OPENADDR_HOME'}) {
		$args{'openaddr'} = $ENV{'OPENADDR_HOME'};
	}

	if($args{'openaddr'}) {
		$rc->{'openaddr'} = Geo::Coder::Free::OpenAddresses->new(%args);
	}
	if(my $cache = $args{'cache'}) {
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

    @matches = $geo_coder->geocode(scantext => 'arbitrary text', region => 'GB', ignore_words => [ 'foo', 'bar' ]);

=cut

# List of words that scantext should ignore
my %common_words = (
	'the' => 1,
	'and' => 1,
	'at' => 1,
	'be' => 1,
	'by' => 1,
	'how' => 1,
	'over' => 1,
	'she' => 1,
	'of' => 1,
	'for' => 1,
	'on' => 1,
	'pm' => 1,
	'in' => 1,
	'an' => 1,
	'more' => 1,
	'to' => 1,
	'road' => 1,
	'is' => 1,
	'was' => 1
);

sub geocode {
	my $self = shift;
	my %params;

	# Try hard to support whatever API that the user wants to use
	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->geocode(@_));
		} elsif(!defined($self)) {
			# Geo::Coder::Free->geocode()
			Carp::croak('Usage: ', __PACKAGE__, '::geocode(location => $location|scantext => $text)');
		} elsif($self eq __PACKAGE__) {
			Carp::croak("Usage: $self", '::geocode(location => $location|scantext => $text)');
		}
		return(__PACKAGE__->new()->geocode($self));
	} elsif(ref($self) eq 'HASH') {
		return(__PACKAGE__->new()->geocode($self));
	} elsif(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	# } elsif(ref($_[0]) && (ref($_[0] !~ /::/))) {
	} elsif(ref($_[0])) {
		Carp::croak('Usage: ', __PACKAGE__, '::geocode(location => $location|scantext => $text)');
	} elsif(scalar(@_) && (scalar(@_) % 2 == 0)) {
		%params = @_;
	} else {
		$params{'location'} = shift;
	}

	# Fail when the input is just a set of numbers
	if(defined($params{'location'}) && ($params{'location'} !~ /\D/)) {
		Carp::croak('Usage: ', __PACKAGE__, ": invalid location to geocode(), $params{location}") if(length($params{'location'}));
		return undef;
	} elsif(defined($params{'scantext'}) && ($params{'scantext'} !~ /\D/)) {
		Carp::croak('Usage: ', __PACKAGE__, ": invalid scantext to geocode(), $params{scantext}") if(length($params{'scantext'}));
		return undef;
	}

	if($self->{'openaddr'}) {
		if(wantarray) {
			my @rc = $self->{'openaddr'}->geocode(\%params);
			if((my $scantext = $params{'scantext'}) && (my $region = $params{'region'})) {
				my %ignore_words;
				if($params{'ignore_words'}) {
					%ignore_words = map { lc($_) => 1 } @{$params{'ignore_words'}};
				}
				# ::diag(Data::Dumper->new([\%ignore_words])->Dump());
				$region = uc($region);
				if($region eq 'US') {
					my @candidates = _find_us_addresses($scantext);
					if(scalar(@candidates)) {
						if(wantarray) {
							my @us;
							foreach my $candidate(@candidates) {
								my @res = $self->{'maxmind'}->geocode("$candidate, USA");
								push @us, @res;
							}
							return @us if(scalar(@us));
						}
						if(my $rc = $self->{'maxmind'}->geocode($candidates[0] . ', USA')) {
							return $rc;
						}
					}
				}
				$scantext =~ s/[^\w']+/ /g;
				my @a = List::MoreUtils::uniq(split(/\s/, $scantext));
				my $iterator = Array::Iterator->new({ __array__ => \@a });
				# TODO
				# while(my $w = $iterator->get_next()) {
				my $w;
				if($w) {
					next if(exists($common_words{lc($w)}));
					next if(exists($ignore_words{lc($w)}));
					if($w =~ /^[a-z]{2,}$/i) {
						my $peek = $iterator->peek();
						last if(!defined($peek));
						my $offset;
						if(exists($common_words{lc($peek)})) {
							$peek = $iterator->peek(2);
							last if(!defined($peek));
							$offset = 3;
						} else {
							$offset = 2;
						}
						my $s;
						if((length($peek) == 2) && (Locale::US->new()->{code2state}{uc($peek)})) {
							$s = "$w $peek US";
						} else {
							my $peekpeek = $iterator->peek($offset);
							last if(!defined($peekpeek));
							$s = "$w $peek $peekpeek";
						}
						# ::diag($s);
					}
				}

				foreach my $word(List::MoreUtils::uniq(split(/\s/, $scantext))) {
					# Ignore numbers
					next if($word !~ /\D/);
					# FIXME:  There are a *lot* of false positives
					next if(exists($common_words{lc($word)}));
					next if(exists($ignore_words{lc($word)}));
					if($word =~ /^[a-z]{2,}$/i) {
						my $key = "$word/$region";
						my @matches;
						if(my $hits = $self->{'scantext'}->{$key}) {
							# ::diag("$key: HIT: ", Data::Dumper->new([$hits])->Dump());
							@matches = @{$hits} if(scalar(@{$hits}));
						} else {
							# ::diag("$key: MISS");
							@matches = $self->{'maxmind'}->geocode({ location => $word, region => $region });
						}
						# ::diag(__LINE__, Data::Dumper->new([\@matches])->Dump());
						my @m;
						foreach my $match(@matches) {
							if(ref($match) eq 'HASH') {
								$match->{'location'} = "$word, $region";
								push @m, $match;
							} elsif(ref($match) eq 'ARRAY') {
								warn __PACKAGE__, ': TODO: handle array: ', Data::Dumper->new([$match])->Dump();
							} else {
								push @m, {
									confidence => $match->confidence(),
									location => $match->as_string(),
									latitude => $match->lat(),
									longitude => $match->long(),
									lat => $match->lat(),
									long => $match->long(),
									database => $match->database(),
									country => $match->country(),
									city => $match->city()
								}
							}
						}
						$self->{'scantext'}->{$key} = \@m;
						@rc = (@rc, @m);
					}
				}
			}
			return @rc if(scalar(@rc) && $rc[0]);
		} elsif(my $rc = $self->{'openaddr'}->geocode(\%params)) {
			return $rc;
		}
		if((!$params{'scantext'}) && (my $alternatives = $self->{'alternatives'})) {
			# Try some alternatives, would be nice to read this from somewhere on line
			my $location = $params{'location'};
			while (my($key, $value) = each %{$alternatives}) {
				if($location =~ $key) {
					# ::diag("$key=>$value");
					my $keep = $location;
					$location =~ s/$key/$value/;
					$params{'location'} = $location;
					if(my $rc = $self->geocode(\%params)) {
						return $rc;
					}
					# Try without the commas, for "Tyne and Wear"
					if($value =~ /, /) {
						my $string = $value;
						$string =~ s/,//g;
						$location = $keep;
						$location =~ s/$key/$string/;
						$params{'location'} = $location;
						if(my $rc = $self->geocode(\%params)) {
							return $rc;
						}
					}
				}
			}
		}
	}

	# FIXME:  scantext only works if OPENADDR_HOME is set
	if($params{'location'}) {
		if(wantarray) {
			my @rc = $self->{'maxmind'}->geocode(\%params);
			return @rc;
		}
		return $self->{'maxmind'}->geocode(\%params);
	}
	if(!$params{'scantext'}) {
		Carp::croak('Usage: geocode(location => $location|scantext => $text)');
	}
}

# Function to find all possible US addresses in a string
sub _find_us_addresses {
	my ($text) = @_;
	my @addresses;

	# Regular expression to match U.S.-style addresses
	my $address_regex = qr/
		\b                 # Word boundary
		(\d{1,5})          # Street number: 1 to 5 digits
		\s+                # Space
		([A-Za-z0-9\s]+?)  # Street name (alphanumeric, allows spaces)
		\s+                # Space
		(Street|St\.?|Avenue|Ave\.?|Boulevard|Blvd\.?|Road|Rd\.?|Lane|Ln\.?|Drive|Dr\.?) # Street type
		(,\s+[A-Za-z\s]+)? # Optional city name
		\s*                # Optional spaces
		(,\s*[A-Z]{2})?    # Optional state abbreviation
		\s*                # Optional spaces
		(\d{5}(-\d{4})?)?  # Optional ZIP code
		\b                 # Word boundary
	/x;

	# Find all matches
	while ($text =~ /$address_regex/g) {
		push @addresses, $&;	# Capture the full match
	}

	return @addresses;
}
=head2 reverse_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

To be done.

=cut

sub reverse_geocode {
	my $self = shift;
	my %params;

	# Try hard to support whatever API that the user wants to use
	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->reverse_geocode(@_));
		} elsif(!defined($self)) {
			# Geo::Coder::Free->reverse_geocode()
			Carp::croak('Usage: ', __PACKAGE__, '::reverse_geocode(latlng => "$lat,$long")');
		} elsif($self eq __PACKAGE__) {
			Carp::croak("Usage: $self", '::reverse_geocode(latlng => "$lat,$long")');
		}
		return(__PACKAGE__->new()->reverse_geocode($self));
	} elsif(ref($self) eq 'HASH') {
		return(__PACKAGE__->new()->reverse_geocode($self));
	} elsif(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	# } elsif(ref($_[0]) && (ref($_[0] !~ /::/))) {
	} elsif(ref($_[0])) {
		Carp::croak('Usage: ', __PACKAGE__, '::reverse_geocode(latlng => "$lat,$long")');
	} elsif(scalar(@_) && (scalar(@_) % 2 == 0)) {
		%params = @_;
	} else {
		$params{'latlng'} = shift;
	}

	# The drivers don't yet support it
	if($self->{'openaddr'}) {
		if(wantarray) {
			my @rc = $self->{'openaddr'}->reverse_geocode(\%params);
			return @rc;
		} elsif(my $rc = $self->{'openaddr'}->reverse_geocode(\%params)) {
			return $rc;
		}
	}

	if($params{'latlng'}) {
		if(wantarray) {
			my @rc = $self->{'maxmind'}->reverse_geocode(\%params);
			return @rc;
		}
		return $self->{'maxmind'}->reverse_geocode(\%params);
	}

	Carp::croak('Reverse lookup is not yet supported');
}

=head2	ua

Does nothing, here for compatibility with other Geo-Coders

=cut

sub ua
{
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
		@rc = $class->new(directory => $ENV{'OPENADDR_HOME'})->geocode($location);
	} else {
		@rc = $class->new()->geocode($location);
	}

	die "$0: geocoding failed" unless(scalar(@rc));

	print Data::Dumper->new([\@rc])->Dump();
}

sub _normalize($) {
	my $street = shift;

	$abbreviations ||= Geo::Coder::Abbreviations->new();

	$street = uc($street);
	if($street =~ /(.+)\s+(.+)\s+(.+)/) {
		my $a;
		if((lc($2) ne 'cross') && ($a = $abbreviations->abbreviate($2))) {
			$street = "$1 $a $3";
		} elsif($a = $abbreviations->abbreviate($3)) {
			$street = "$1 $2 $a";
		}
	} elsif($street =~ /(.+)\s(.+)$/) {
		if(my $a = $abbreviations->abbreviate($2)) {
			$street = "$1 $a";
		}
	}
	$street =~ s/^0+//;	# Turn 04th St into 4th St
	return $street;
}

sub _abbreviate($) {
	my $type = uc(shift);

	$abbreviations ||= Geo::Coder::Abbreviations->new();

	if(my $rc = $abbreviations->abbreviate($type)) {
		return $rc;
	}
	return $type;
}

=head1 GETTING STARTED

Before running "make", but after running "perl Makefile.PL", run these instructions.

Optionally set the environment variable OPENADDR_HOME to point to an empty directory and download the data from L<http://results.openaddresses.io> into that directory; and
optionally set the environment variable WHOSONFIRST_HOME to point to an empty directory and download the data using L<https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-clone>.
The script bin/download_databases (see below) will do those for you.
You do not need to download the MaxMind data, that will be downloaded automatically.

You will need to create the database used by Geo::Coder::Free.

Install L<App::csv2sqlite> and L<https://github.com/nigelhorne/NJH-Snippets>.
Run bin/create_sqlite - converts the Maxmind "cities" database from CSV to SQLite.

To use with MariaDB,
set MARIADB_SERVER="$hostname;$port" and
MARIADB_USER="$user;$password" (TODO: username/password should be asked for)
The code will use a database called geo_code_free which will be deleted
if it exists.
$user should only need to privileges to DROP, CREATE, SELECT, INSERT, CREATE and INDEX
on that database. If you've set DEBUG mode in createdatabase.PL, or are playing
with REPLACE instead of INSERT, you'll also need DELETE privileges - but non-developers
don't need to have that.

Optional steps to download and install large databases.
This will take a long time and use a lot of disc space, be clear that this is what you want.
In the bin directory there are some helper scripts to do this.
You will need to tailor them to your set up, but that's not that hard as the
scripts are trivial.

=over 4

=item 1

C<mkdir $WHOSONFIRST_HOME; cd $WHOSONFIRST_HOME> run wof-clone from NJH-Snippets.

This can take a long time because it contains lots of directories which filesystem drivers
seem to take a long time to navigate (at least my EXT4 and ZFS systems do).

=item 2

Install L<https://github.com/dr5hn/countries-states-cities-database.git> into $DR5HN_HOME.
This data contains cities only,
so it's not used if OSM_HOME is set,
since the latter is much more comprehensive.
Also, only Australia, Canada and the US is imported, as the UK data is difficult to parse.

=item 3

Run bin/download_databases - this will download the WhosOnFirst, Openaddr,
Open Street Map and dr5hn databases.
Check the values of OSM_HOME, OPENADDR_HOME,
DR5HN_HOME and WHOSONFIRST_HOME within that script,
you may wish to change them.
The Makefile.PL file will download the MaxMind database for you, as that is not optional.

=item 4

Run bin/create_db - this creates the database used by G:C:F using the data you've just downloaded
The database is called openaddr.sql,
even though it does include all of the above data.
That's historical before I added the WhosOnFirst database.
The names are a bit of a mess because of that.
I should rename it to geo-coder-free.sql, even though it doesn't contain the Maxmind data.

=back

Now you're ready to run "make"
(note that the download_databases script may have done that for you,
but you'll want to check).

See the comment at the start of createdatabase.PL for further reading.

=head1 MORE INFORMATION

I've written a few Perl related Genealogy programs including gedcom (L<https://github.com/nigelhorne/gedcom>)
and ged2site (L<https://github.com/nigelhorne/ged2site>).
One of the things that these do is to check the validity of your family tree, and one of those tasks is to verify place-names.
Of course places do change names and spelling becomes more consistent over the years, but the vast majority remain the same.
Enough of a majority to computerise the verification.
Unfortunately all of the on-line services have one problem or another - most either charge for large number of access, or throttle the number of look-ups.
Even my modest tree, just over 2000 people, reaches those limits.

There are, however, a number of free databases that can be used, including MaxMind, GeoNames, OpenAddresses and WhosOnFirst.
The objective of L<Geo::Coder::Free> (L<https://github.com/nigelhorne/Geo-Coder-Free>)
is to create a database of those databases and to create a search engine either through a local copy of the database or through an on-line website.
Both are in their early days, but I have examples which do surprisingly well.

The local copy of the database is built using the createdatabase.PL script which is bundled with G:C:F.
That script creates a single SQLite file from downloaded copies of the databases listed above, to create the database you will need
to first install L<App::csv2sqlite>.
If REDIS_SERVER is set, the data are also stored on a Redis Server.
Running 'make' will download GeoNames and MaxMind, but OpenAddresses and WhosOnFirst need to be downloaded manually if you decide to use them - they are treated as optional by G:C:F.

The sample website at L<https://geocode.nigelhorne.com/> is down at the moment while I look for a new host.
The source code for that site is included in the G:C:F distribution.

=head1 BUGS

Some lookups fail at the moments, if you find one please file a bug report.

Doesn't include results from
L<Geo::Coder::Free::Local>.

The MaxMind data only contains cities.
The OpenAddresses data doesn't cover the globe.

Can't parse and handle "London, England".

It would be great to have a set-up wizard to create the database.

The various scripts in NJH-Snippets ought to be in this module.

=head1 SEE ALSO

L<https://openaddresses.io/>,
L<https://www.maxmind.com/en/home>,
L<https://www.geonames.org/>,
L<https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/countries%2Bstates%2Bcities.json>,
L<https://www.whosonfirst.org/> and
L<https://github.com/nigelhorne/vwf>.

L<Geo::Coder::Free::Local>,
L<Geo::Coder::Free::Maxmind>,
L<Geo::Coder::Free::OpenAddresses>.

See L<Geo::Coder::Free::OpenAddresses> for instructions creating the SQLite database from
L<http://results.openaddresses.io/>.

=head1 AUTHOR

Nigel Horne, C<< <njh@bandsman.co.uk> >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Free

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Geo-Coder-Free>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Free>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Geo-Coder-Free>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Geo-Coder-Free>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Geo::Coder::Free>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Free/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2025 Nigel Horne.

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
St Peters, Thanet, Kent = Broadstairs, Kent
Minster, Thanet, Kent = Ramsgate, Kent
Tyne and Wear = Borough of North Tyneside
