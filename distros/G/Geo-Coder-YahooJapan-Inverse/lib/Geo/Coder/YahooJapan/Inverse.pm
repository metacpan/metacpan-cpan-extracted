package Geo::Coder::YahooJapan::Inverse;

use 5.008004;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use Location::GeoTool;
use XML::Simple;
use utf8;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Geo::Coder::YahooJapan::Inverse ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    invlookup
);

our $VERSION = '0.02';

# Preloaded methods go here.

my $entry_point = 'http://map.yahoo.co.jp/geo/lonlat2address';

my $ua = undef;

sub invlookup {
    my ($lat,$long,$opts) = @_;

    ($lat && $long) or return undef;

    $ua or $ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");

    my $datum = $opts->{datum} || 'wgs84';

    die "Format of coordinate is wrong" if (($lat !~ /^[\-\+]?\d{1,2}(\.\d*)?$/) && ($long !~ /^[\-\+]?\d{1,2}(\.\d*)?$/));
    die "Datum is wrong" if (($datum ne 'wgs84') && ($datum ne 'tokyo'));

    my $loc = eval { Location::GeoTool->create_coord($lat, $long, $datum, 'degree')};

    ($lat,$long) = $loc->datum_tokyo->format_mapion->array;

    my $req = HTTP::Request->new('POST',$entry_point);
    $req->content("<query><coordinates>$lat,$long</coordinates></query>");

    my $res = $ua->request( $req );

    $res or return undef;
    my $cont = $res->content;
    die "API error occured: maybe specified coordinate is out of Japan area" if ($cont =~ /<error/);

    my $result = XMLin($cont)->{'gxml:spatialLocator'};
    utf8::decode($result->{'gxml:AddressString'}->{'gxml:unstructuredAddressString'});
    my @aditem = map { utf8::decode($_->{'content'}); $_->{'content'} } 
                 sort { $a->{'level'} <=> $b->{'level'} } 
                 @{$result->{'gxml:AddressString'}->{'gxml:AddressItem'}};

    return {
        address => $result->{'gxml:AddressString'}->{'gxml:unstructuredAddressString'},
        addressitem => \@aditem,
        code => $result->{'GovernmentCode'},
    };
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Geo::Coder::YahooJapan::Inverse - a simple wrapper for Yahoo Japan Inverse Geocoder API

=head1 SYNOPSIS

  use Geo::Coder::YahooJapan::Inverse;
  $r = invlookup( $latitude, $longitude ); # coordinate in WGS84, format in degree.
  my $address = $r->{address}; # Return address in string with utf-8 flag.

  # if you want to give coordinate in TOKYO datum, specify it in option.
  $r = invlookup( $latitude, $longitude, { datum => 'tokyo' } );

  # $r->{addressitem} has structure of address, devided by prefecture, city, town, and so on.
  my $address = join("",@{$r->{addressitem}}); # Same as $r->{address}.

  # $r->{code} has Japanese government's address code.
  my $code = $r->{code};

=head1 DESCRIPTION

Geo::Coder::YahooJapan::Inverse is a wrapper for Yahoo Japan Inverse Geocoder API.
This API is unofficial, so you should use this module at your own risk.

=head3 invlookup(latitude, longitude, opts)

Invlookup is an only method in this package that returns address information in an hash reference. 
You can give coordinate in WGS84(default) or TOKYO(set datum option) datum, and in degree format.

=head1 DEPENDENCIES

L<HTTP::Request>
L<LWP::UserAgent>
L<Location::GeoTool>
L<XML::Simple>

=head1 SEE ALSO

L<Geo::Coder::YahooJapan>

=head1 AUTHOR

OHTSUKA Ko-hei E<lt>nene@kokogiko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by OHTSUKA Ko-hei

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
