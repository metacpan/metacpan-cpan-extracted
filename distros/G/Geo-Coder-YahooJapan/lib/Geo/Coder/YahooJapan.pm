package Geo::Coder::YahooJapan;

use 5.008004;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use Location::GeoTool;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Geo::Coder::YahooJapan ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	lookup
);

our $VERSION = '0.04';

# Preloaded methods go here.

my $entry_point = 'http://api.map.yahoo.co.jp/MapsService/V1/search';

my $ua = undef;

sub lookup {
	my $address = shift;
	my $opts = shift;

	$address or return undef;

	$ua or $ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");

	my $datum = $opts->{datum} || 'wgs84';

	defined $opts->{num} or $opts->{num} = 10;
	defined $opts->{prop} or $opts->{prop} = 'widget';
	$address =~ s/([\W])/ sprintf "%%%02X", ord($1) /ge;

	my $params = {
		prop => $opts->{prop},
		b => 1,
		n => int $opts->{num},
		ac => "",
		st => "",
		p => $address
	};
	
	my $q = join "&", ( map { "$_=" . $params->{$_} } (keys %$params) );
	my $url = "$entry_point?$q";
	my $response = $ua->get( $url );

	$response or return undef;
	my $content = $response->content;
	
	my @items = ();
	@_ = split m|<item>|, $content;
	scalar @_ == 0 and return undef;

	while ( $content =~ m|<item>(.+?)</item>|sg ) {
		my $item_content = $1;

		my $result = {};
		while ( $item_content =~ m|<(\w+)>(.+?)</\1>|g ) {
			$result->{$1} = $2;
		}
		if ( $datum !~ /^tokyo$/i ) {
			my $tokyo = Location::GeoTool->create_coord(
				$result->{latitude}, $result->{longitude}, 'tokyo', 'degree');
			my $wgs = $tokyo->datum_wgs84;
			$wgs->format_degree;
			$result->{latitude}  = $wgs->lat;
			$result->{longitude} = $wgs->long;
		}
		push @items, $result;
	}


	return {
		datum => $datum,
		latitude => $items[0]->{latitude},
		longitude => $items[0]->{longitude},
		hits => scalar @items,
		items => \@items
	};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Geo::Coder::YahooJapan - a simple wrapper for Yahoo Japan Geocoder API

=head1 SYNOPSIS

  use Geo::Coder::YahooJapan;
  $r = lookup( $address_in_japanese_characters );
  my ($lat, $lng) = ( $r->{latitude}, $r->{longitude} ); # coordinate in WGS87.

  # if you want to get result in TOKYO datum, specify it in option.
  $r = lookup( $address_in_japanese_characters, { datum => 'tokyo' } );

  # if address is ambiguous and the server returns multiple items
  $r = lookup( $address_in_japanese_characters );
  # $r->{latitude} and $r->{longitude} contains coordinate of first item.
  ($lat, $lng) = ( $r->{latitude}, $r->{longitude} );

  # $r->{hits} has the number of candidates.
  if ( $r->{hits} > 1 ) {
  	# and $r->{items} contains each candidates infomation.
  	foreach ( $r->{items} ) {
		print join "\t", ( $_->{title}, $_->{latitude}, $_->{longitude} );
		print "\n";
	}
  }

=head1 DESCRIPTION

Geo::Coder::YahooJapan is a wrapper for Yahoo Japan Geocoder API that is used by the
official Yahoo Japan's local search widget
L<http://widgets.yahoo.co.jp/gallery/detail.html?wid=10> .
This module converts the coordinate into WGS84 from TOKYO datum which is returned by API server.

=head3 lookup(address, opts)

Lookup is an only method in this package that returns coordinate information
in an hash reference. When address is not enough precise, the server returns multiple candidates.
These candidatse are found in $response->{items}. You can determine geocoding result has multiple candidates or not by seeing $response->{hits}.

You can specify the address in UTF8, SHIFT_JIS, EUC_JP. But the API server does not understand ISO-2022-JP, so you need convert into other character set if your address is written in ISO-2022-JP.
In $opts->{num}, you can specify the number of candidates you want to receive when multiple items are found. Default value is 10.
If you want to get results in other datum, not in WGS84, set the datum name in $opts->{datum}. the value is passed to Location::GeoTool and it converts them properly.

=head1 DEPENDENCIES

L<HTTP::Request>
L<LWP::UserAgent>
L<Location::GeoTool>

=head1 AUTHOR

KUMAGAI Kentaro E<lt>ku0522a+cpan@gmail.comE<gt>

=cut
