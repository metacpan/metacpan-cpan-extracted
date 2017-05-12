

package Google::GeoCoder::Smart;

require Exporter;

use LWP::Simple qw(!head);

use JSON;

our @ISA = qw(Exporter);

our @EXPORT = qw(geocode parse);

our $VERSION = 1.18;

=head1 NAME

Smart - Google Maps Api HTTP geocoder

=head1 SYNOPSIS

 use Google::GeoCoder::Smart;
  
 $geo = Google::GeoCoder::Smart->new();

 my ($resultnum, $error, @results, $returncontent) = $geo->geocode("address" => "your address here");

 $resultnum--;

 for $num(0 .. $resultnum) {

 $lat = $results[$num]{geometry}{location}{lat};

 $lng = $results[$num]{geometry}{location}{lng};

 };

=head1 DESCRIPTION

This module provides a simple and "Smart" interface to the Google Maps geocoding API. 

It is compatible with the google maps http geocoder v3.

If Google changes their format, it might stop working. 

This module only depends on LWP::Simple and JSON. 

This version removes the depriciated homemade xml parsing and goes completely with the JSON format. 

If you need the old xml version, the older module versions still have it, but it does have a few problems. 

#################################################

MAKE SURE TO READ GOOGLE's TERMS OF USE

they can be found at http://code.google.com/apis/maps/terms.html#section_10_12

#################################################

If you find any bugs, please let me know. 

=head1 METHODS

=head2 new

	$geo = Google::GeoCoder::Smart->new("key" => "your api key here", "host" => "host here");

the new function normally is called with no parameters.

however, If you would like to, you can pass it your Google Maps api key and a host name.

the api key parameter is useful for the api premium service.

the host paramater is only necessary if you use a different google host than googleapis.com, 

such as google.com.eu or something like that.http://code.google.com/apis/maps/terms.html#section_10_12

=head2 geocode

	my ($num, $error, @results, $returntext) = $geo->geocode(

	"address" => "address *or street number and name* here", 

	"city" => "city here", 

	"state" => "state here", 

	"zip" => "zipcode here"

	);

This function brings back the number of results found for the address and 

the results in an array. This is the case because Google will sometimes return

many different results for one address.

It also returns the result text for debugging purposes.

The geocode method will work if you pass the whole address as the "address" tag.
 
However, it also supports breaking it down into parts.

It will return one of the following error messages if an error is encountered

	connection         #something went wrong with the download

	OVER_QUERY_LIMIT   #the google query limit has been exceeded. Try again 24 hours from when you started geocoding

	ZERO_RESULTS       #no results were found for the address entered

If no errors were encountered it returns the value "OK"

You can get the returned parameters easily through refferences. 

	$lat = $results[0]{geometry}{location}{lat};

	$lng = $results[0]{geometry}{location}{lng};

It is helpful to know the format of the json returns of the api. 

A good example can be found at http://www.googleapis.com/maps/apis/geocode/json?address=1600+Amphitheatre+Parkway+Mountain+View,+CA+94043&sensor=false

=head1 AUTHOR

TTG, ttg@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by TTG

This library is free software; you can redistribute it and/or modify

it under the same terms as Perl itself, either Perl version 5.10.0 or,

at your option, any later version of Perl 5 you may have available.


=cut

sub new {

my ($junk, %params) = @_;

my $host = delete $params{host} || "maps.googleapis.com";

my $key = delete $params{key};

bless {"key" => $key, "host" => $host};

}

sub geocode {

my ($self, %params) = @_;

$addr = delete $params{'address'};

$CITY = delete $params{'city'};

$STATE = delete $params{'state'};

$ZIP = delete $params{'zip'};

my $keyVar = "";

if($self->{key}) {

	$keyVar = "&key=$self->{key}";

}

my $content = get("http://$self->{host}/maps/api/geocode/json?address=$addr $CITY $STATE $ZIP&sensor=false");

undef $err;

undef $error;

unless($content) {

	$error = "ERROR_GETTING_PAGE";

}

if($content =~ m/ZERO_RESULTS/) {

$error = "ZERO_RESULTS";

};

if($content =~ m/OVER_QUERY_LIMIT/) {

$error = "OVER_QUERY_LIMIT";

};

unless(defined $content) {

$error = "connection";

};

unless(defined $error) {

$error = "OK";

};

undef @results;

unless($error eq "OK") {

	@results = [];
	$length = 0;
	return $length, $error, @results, $content;

}

$results_json  = decode_json $content;

#$error = $results_json->{results}[0];

#@results = \$results_json->{results};

$error = $results_json->{status};

foreach $res($results_json->{results}[0]) {

@push = ($res);



push @results, @push;


};



my $length = @results;

return $length, $error, @results, $content;

}




1;


