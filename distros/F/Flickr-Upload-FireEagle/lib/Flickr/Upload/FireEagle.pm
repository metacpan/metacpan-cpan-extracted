# $Id: FireEagle.pm,v 1.19 2008/04/22 07:01:19 asc Exp $

use strict;

package FUFEException;
use base qw (Error);

# http://www.perl.com/lpt/a/690

use overload ('""' => 'stringify');

sub new {
    my $self = shift;
    my $text = shift;
    my $prev = shift;

    if (UNIVERSAL::can($prev, "stacktrace")){
            $text .= "\n";
            $text .= $prev->stacktrace();
    }

    local $Error::Depth = $Error::Depth + 1;
    local $Error::Debug = 1;  # Enables storing of stacktrace

    $self->SUPER::new(-text => $text);
}

sub stringify {
        my $self = shift;
        my $pkg = ref($self) || $self;
        return sprintf("[%s] %s", $pkg, $self->stacktrace());
}

package FlickrUploadException;
use base qw (FUFEException);

package FlickrAPIException;
use base qw (FUFEException);

sub new {
        my $pkg = shift;
        my $text = shift;
        my $prev = shift;
        my $code = shift;
        my $msg = shift;

        $text .= " Error code $code";

        my $self = $pkg->SUPER::new($text, $prev);

        $self->{'api_error_code'} = $code;
        $self->{'api_error_message'} = $msg;
        return $self;
}

sub error_code {
        my $self = shift;
        return $self->{'api_error_code'};
}

sub error_message {
        my $self = shift;
        return $self->{'api_error_message'};
}

package NetFireEagleException;
use base qw (FUFEException);

package Flickr::Upload::FireEagle;
use base qw (Flickr::Upload);

$Flickr::Upload::FireEagle::VERSION = '0.1';

=head1 NAME

Flickr::Upload::FireEagle - Flickr::Upload subclass to assign location information using FireEagle

=head1 SYNOPSIS

 use Getopt::Std;
 use Config::Simple;
 use Flickr::Upload::FireEagle;

 # c: path to a config file
 # p: path to a photo

 my %opts = ();
 getopts('c:p:', \%opts);
        
 my $cfg = Config::Simple->new($opts{'c'});

 my %fireeagle_args = ('consumer_key' => $cfg->param('fireeagle.consumer_key'), 
                       'consumer_secret' => $cfg->param('fireeagle.consumer_secret'), 
                       'access_token' => $cfg->param('fireeagle.access_token'), 
                       'access_token_secret' => $cfg->param('fireeagle.access_token_secret'));

 my %flickr_args = ('key' => $cfg->param('flickr.api_key'), 
                    'secret' => $cfg->param('flickr.api_secret'), 
                    'fireeagle' => \%fireeagle_args);

 my $uploadr = Flickr::Upload::FireEagle->new(\%flickr_args);

 my $photo_id = $uploadr->upload('photo' => $opts{'p'},
                                 'auth_token' => $cfg->param('flickr.auth_token'));
                                        
 print "photo : $photo_id\n";

=head1 DESCRIPTION

Flickr::Upload subclass to assign location information using FireEagle and if
a photo contains relevant GPS information in its EXIF headers update your 
location as well.

=head1 HOW DOES IT WORK?

Well. It's a bit involved.

The first thing that happens is the photo you're trying to upload is poked for EXIF data,
specifically any GPS information and when it was taken (the using I<DateTimeOrginal> field).

If there is no date information, the current time is assumed.

If there is GPS data then the date is tested to see if the photo was taken falls within an
allowable window of time. By default, this is (1) hour from "right now". An alternate value
may be set by passing an I<offset_gps> argument, measured in seconds, to the I<upload> method.

If the GPS information was added recently enough then FireEagle is queried for your
most recent location hierarchy. If the GPS information is more recent than the data
stored in the hierarchy (the location with the "best guess" of being correct) then FireEagle
is updated with the latitude and longitude recorded in the photo.

Moving right along, whether or not we've just updated FireEagle the service is queried
for your current location (again).

Once the hierarchy has been retrieved, the next step is to try and retrieve a "context" node.
Whereas when testing GPS information the "best guess" node is assumed this is not necessarily
the case when trying to use FireEagle to add tags.

The context node is determined by comparing the photo's date against the I<located-at> (or
date recorded) attribute for specific items in the FireEagle hierarchy. Since most cameras
still don't record GPS information it is necessary to do some work to gues^H^H^H I mean 
infer how "close" you are to the last recorded location.

For example, if it's been more than a couple of hours since you last updated FireEagle you
might still be in the same neighbourhood but if it's been more than half a day chances are
good that you're been on the move but are still in the same city.

(It goes without saying that there are lots of edge cases some of which will try to be addressed
in the as-yet unwritten Flickr::Upload::FireDopplr.)

The following tests are applied : 

=over 4

=item * First a "best guess" location is queried

If it is present and its I<located-at> date is less than or equal to an hour, it is the
context node.

An alternate value may be set by passing a I<offset_fireeagle_exact> argument, measured in
seconds, to the I<upload> method.

=item * Next a location of type "neighborhood" is queried

If it is present and its I<located-at> date is less than or equal to two hours, it is the
context node.

An alternate value may be set by passing a I<offset_fireeagle_neighbourhood> (or neighborhood) 
argument, measured in seconds, to the I<upload> method.

=item * Next a location of type "locality" is queried

If it is present and its I<located-at> date is less than or equal to twelve hours, it is the
context node.

An alternate value may be set by passing a I<offset_fireeagle_locality> argument, measured
in seconds, to the I<upload> method.

=item * If none of those tests pass then...

...there is no context node.

=back

Assuming that a context node has been identified I<and> there is GPS information stored in the
photo, the I<flickr.places.findByLatLon> method is called (passing the photo's latitude and
longitude) to ensure that the (Flickr) places IDs for both the response and the context node match.

If they I<don't> match then the context node is destroyed and the following tags are added :
places:PLACETYPE=PLACEID; woe:id=WOEID; the name of the location (formatted according to the
object's "tagify" rules). 

On the other hand, if the context node is still around, after all that, then it is used to add tags.

At a minimum a fireeagle:id=CONTEXTNODEID tag is added. If the place type for the context node is
equal to or more precise than a neighbourhood, the neighbourhood's name is added as a tag. If the
place type for the context node is equal to or more precise than a locality, the locality's name
is added as a tag as well as fireeagle:id=ID, places:locality=PLACEID and woe:id=WOEID tags.

We're almost done : Assuming a context node and no GPS information in the photo, the nodes latitude
and longitude are calculated to use as arguments when calling the I<flickr.photos.geo.setLocation>
method.

The coordinates are "calculated" because not every location in the FireEagle hierarchy has a centroid.
If no centroid is present then the node's bounding box is used and the centroid is assumed to be
the center of the box. The photo's "accuracy" (in Flickr terms) is determined according to the node's
place type.

Finally, the photo is uploaded (and geotagged if necessary).

No really.

=head1 ERROR HANDLING

Flickr::Upload::FireEagle subclasses Error.pm to catch and throw exceptions. Although
this is still a mostly un-Perl-ish way of doing things, it seemed like the most sensible
way to handle the variety of error cases. I don't love it but we'll see.

This means that the library B<will throw fatal exceptions> and you will need to
code around it using either I<eval> or - even better - I<try> and I<catch> blocks.

There are four package specific exception handlers :

=over 4

=item * B<FUFEException>

An error condition specific to I<Flickr::Upload::FireEagle> was triggered.

=item * B<FlickrUploadException>

An error condition specific to I<Flickr::Upload> was triggered.

=item * B<FlickrAPIException>

An error condition specific to calling the Flickr API (read : I<Flickr::API>)
was triggered.

This is the only exception handler that defines its own additional methods. They
are :

=over 4

=item * B<error_code>

The numeric error code returned by the Flickr API.

=item * B<error_message>

The textual error message returned by the Flickr API.

=back

=item * B<NetFireEagleException>

An error condition specific to I<Net::FireEagle> was triggered.

=back

=head1 CAVEATS

=over 4

=item *

Asynchronous uploads are not support and will trigger an exception.

=back

=cut

use Net::FireEagle;
use Image::Info qw (image_info);
use Date::Parse;
use Error qw(:try);
use XML::XPath;
use Readonly;
use Geo::Coordinates::DecimalDegrees;

$Error::Debug = 1;

Readonly::Scalar my $OFFSET_GPS => 60 * 60 * 1;
Readonly::Scalar my $OFFSET_FIREEAGLE_EXACT => 60 * 60 * 1;
Readonly::Scalar my $OFFSET_FIREEAGLE_NEIGHBOURHOOD => 60 * 60 * 2;
Readonly::Scalar my $OFFSET_FIREEAGLE_LOCALITY => 60 * 60 * 12;

Readonly::Hash my %PLACEMAP => (
                                0 => 16,		# exact
                                1 => 13,		# postal
                                2 => 14,		# neighbourhood
                                3 => 11,		# city
                                4 => 9,			# county
                                5 => 5,			# state
                                6 => 1,			# country
                               );

=head1 PACKAGE METHODS

=head2 __PACKAGE__->new(\%args)

All the same arguments required by the I<Flickr::Upload> constructor plus the
following :

=over 4

=item * B<fireeagle>

A hash reference containing the following keys :

=over 4

=item * B<consumer_key>

String. I<required>

A valid FireEagle consumer key.

=item * B<consumer_secret>

String. I<required>

A valid FireEagle consumer secret.

=item * B<access_token>

String. I<required>

A valid FireEagle access token.

=item * B<access_token_secret>

String. I<required>

A valid FireEagle access token secret.

=item * B<tagify>

String.

An optional flag to format tags for cities, specific to a service. Valid
services are :

=over 4 

=item * B<delicious>

City names are lower-cased and spaces are removed.

=item * B<flickr>

City names are wrapped in double-quotes if they contain spaces.

=back

The default value is I<flickr>

=back

=back

Returns a I<Flickr::Upload::FireEagle> object.

=cut

sub new {
        my $pkg = shift;
        my $args = shift;

        my $fe_args = $args->{'fireeagle'};
        delete($args->{'fireeagle'});

        # First try to become Flickr::Upload

        my $self = undef;

        try {
                $self = $pkg->SUPER::new($args);
        }
        
        catch Error with {
                my $e = shift;
                throw FlickrUploadException("Failed to instantiate Flickr::Upload", $e);
        };

        # Next, load up the FireEagle love

        try {
                $self->{'__fireeagle'} = Net::FireEagle->new(%{$fe_args});
        }
         
        catch Error with {
                my $e = shift;
                throw NetFireEagleException("Failed to instantiate Net::FireEagle", $e);
        };

        $self->{'__fireeagle_args'} = $fe_args;
        return $self;
}

# A secret ("secret") for now...

sub new_from_config {
        my $pkg = shift;
        my $path = shift;

        my $cfg = (ref($path) eq "Config::Simple") ? $path : Config::Simple->new($path);

        my %fireeagle_args = ('consumer_key' => $cfg->param('fireeagle.consumer_key'), 
                              'consumer_secret' => $cfg->param('fireeagle.consumer_secret'), 
                              'access_token' => $cfg->param('fireeagle.access_token'), 
                              'access_token_secret' => $cfg->param('fireeagle.access_token_secret'));
        
        my %flickr_args = ('key' => $cfg->param('flickr.api_key'), 
                           'secret' => $cfg->param('flickr.api_secret'), 
                           'fireeagle' => \%fireeagle_args);

        return $pkg->new(\%flickr_args);
}

=head1 OBJECT METHODS YOU SHOULD CARE ABOUT

=head2 $obj->upload(%args)

Valid arguments are anything you would pass the Flickr::Upload I<upload> method B<except>
the I<async> flag which is not honoured yet. I'm working on it.

In additional, you may pass the following optional parameters : 

=over 4 

=item * B<geo>

This must be a hash reference with the following keys :

=over 4

=item * B<perms>

Hash reference.

A hash reference containing is_public, is_contact, is_family and is_friend
keys and their boolean values to set the geo permissions on your uploaded photo.

If this is not defined then your default viewing settings for geo data will be left
in place.

=back

=item * B<offset_gps>

Int.

The maximum amount of time (in seconds) between the time of your last FireEagle update
and the date on which the photo was taken in which a photo can be considered reliable
for updating your location in FireEagle.

The default is 3600 (seconds, or 1 hour).

=item * B<offset_fireeagle_exact>

The maximum amount of time (in seconds) between the time of your last FireEagle update
and the date on which the photo was taken in which FireEagle can be considered reliable
for updating your location in FireEagle at street level.

The default is 3600 (seconds, or 1 hour).

=item * B<offset_fireeagle_neighbourhood> (or offset_fireeagle_neighborhood)

The maximum amount of time (in seconds) between the time of your last FireEagle update
and the date on which the photo was taken in which FireEagle can be considered reliable
for updating your location in FireEagle at the neighbourhood level.

The default is 7200 (seconds, or 2 hours).

=item * B<offset_fireeagle_locality>

The maximum amount of time (in seconds) between the time of your last FireEagle update
and the date on which the photo was taken in which FireEagle can be considered reliable
for updating your location in FireEagle at the locality (city) level.

The default is 43200 (seconds, or 12 hours).

=back

Returns a photo ID!

=cut

sub upload {
        my $self = shift;
        my %args = @_;

        if ($args{'async'}){
                throw FUFEException("Asynchronous uploads are not supported yet");
        }
        
        #
        # As in geo perms, etc. Store for later.
        # 

        my $geo = undef;

        if (ref($args{'geo'}) eq "HASH"){
                $geo = $args{'geo'};
                delete($args{'geo'});
        }

        #
        # Check to see if the photo has GPS info
        # (this will be picked up by the Flickr upload wah-wah)
        #

        my $info = undef;
        my $has_gps = 0;
        my $ph_date = time();

        my $fresh_loc = 0;

        eval {
                $info = image_info($args{'photo'});

                if (($info) && (ref($info->{'GPSLatitude'}))){
                        $has_gps = 1;
                }

                if (exists($info->{'DateTimeOriginal'})){
                        $ph_date = str2time($info->{'DateTimeOriginal'});
                }
        };

        if ($@){
                warn "EXIF parsing failed : $@, carrying on anyway";
        }

        # 
        #
        #

        if ($has_gps){

                my $offset = $args{'offset_gps'} || $OFFSET_GPS;
                my $test = (time() - $ph_date);

                # If we have GPS data see if we can update FireEagle
                # while we're at it. First ensure that the photo's
                # date falls within some allowable window in "now"
                
                # print "[GPS] TEST : $test ($offset)\n";
                # print "[GPS] date : $ph_date\n";

                if ($test < $offset){

                        # Assuming it does then make sure that FireEagle
                        # doesn't already have a more recent location update

                        if (my $hier = $self->fetch_fireeagle_hierarchy()){
                        
                                my $best = str2time($hier->findvalue("/rsp/user/location-hierarchy/location[\@best-guess='true']/located-at"));
                        
                                # Make sure FireEagle doesn't already have
                                # a more recent update.
                                
                                # To do, maybe : try to figure out which of the two
                                # locations is more precise....

                                # print "[GPS] BEST : $best\n";
                                # print "[GPS] date : $ph_date\n";

                                if ($ph_date > $best){
                                        
                                        my ($lat, $lon) = $self->gps_exif_to_latlon($info);
                                        my %update = ('lat' => $lat, 'lon' => $lon);
                                        
                                        if ($self->{'__fireeagle'}->update_location(\%update)){
                                                $fresh_loc = 1;
                                        }
                                        
                                        else {
                                                warn "Failed to update location in FireEagle, chugging along anyway";
                                        }
                                }
                        }
                }
        }

        #
        # Now ask FireEagle where we are and do some sanity checking on
        # the date of the last update also trying to sync it up with any
        # date information that comes out of the EXIF stored above in $ph_date
        #

        if (! exists($args{'tags'})){
                $args{'tags'} = '';
        }

        my $hier = $self->fetch_fireeagle_hierarchy();
        my $ctx = undef;
                
        if ($hier){
                
                $ctx = $self->get_fireeagle_context_node($hier, $ph_date, \%args);
                
                if (! $ctx){
                        warn "Too much time has passed between your photo and FireEagle to feel comfortable saying";
                }

                # Do some final sanity checking if we know what our lat, lon is

                elsif ($has_gps){

                        # please cache me...
                        my ($lat, $lon) = $self->gps_exif_to_latlon($info);
                        
                        try {
                                my $res = $self->flickr_api_call('flickr.places.findByLatLon', {'lat' => $lat, 'lon' => $lon});
                                my $xml = XML::XPath->new('xml' => $res->decoded_content());

                                my $fe_placeid = $ctx->findvalue("place-id");
                                my $fl_placeid = $xml->findvalue("/rsp/places/place/\@place_id")->string_value();;

                                if ($fe_placeid ne $fl_placeid){

                                        warn "Mismatch between Flickr and FireEagle place IDs ($fl_placeid, $fe_placeid) based on lat/lon, deferring to Flickr";

                                        my $fe_id = $ctx->findvalue("id")->string_value();
                                        $ctx = undef;

                                        my $placetype = $xml->findvalue("/rsp/places/place/\@place_type");
                                        my $woeid = $xml->findvalue("/rsp/places/place/\@woeid");
                                        
                                        my @tags = (
                                                    "fireeagle:id=$fe_id",
                                                    "places:$placetype=$fl_placeid",
                                                    "woe:id=$woeid",
                                                   );
                                        
                                        if (my $name = $self->fetch_places_name($fl_placeid)){
                                                my $model = $self->{'__fireeagle_args'}->{'tagify'} || "flickr";
                                                push @tags, $self->tagify(lc($name), $model);
                                        }
                                        
                                        $args{'tags'} .= ' ';
                                        $args{'tags'} .= join(' ', @tags);
                                }
                }
                        
        	catch Error with {
                        # pass
                };         
        }

        }

        #
        # Okay - now add tags 
        #

        if ($ctx){
                $args{'tags'} .= ' ';
                $args{'tags'} .= $self->generate_location_tags($hier, $ctx);
        }

        # 
        # If we don't have EXIF data and we have something useful from
        # FireEagle try to use that to update the geo information for
        # the photo
        # 

        my %extra = ();

        if ((! $has_gps) && ($ctx)){

                my ($lat, $lon) = split(" ", $ctx->findvalue("georss:point"));

                # FireEagle doesn't always return a centroid....grrr!

                if (! $lat){

                        my ($swlat, $swlon, $nelat, $nelon) = split(" ", $ctx->findvalue("georss:box"));     

                        my $diff_lat = ($nelat - $swlat) / 2;
                        my $diff_lon = ($nelon - $swlon) / 2;

                        $lat = $swlat + $diff_lat;
                        $lon = $swlon + $diff_lon;
                }

                my $placetype = $ctx->findvalue("level")->string_value();
                my $acc = (exists($PLACEMAP{$placetype})) ? $PLACEMAP{$placetype} : 16;

                $extra{'lat'} = $lat;
                $extra{'lon'} = $lon;
                $extra{'acc'} = $acc;
        }

        if (exists($geo->{'perms'})){
                $extra{'geo_perms'} = $geo->{'perms'};
        }

        #
        # Finally, upload
        #

        # use Data::Dumper;
        # print Dumper(\%args);
        # print Dumper(\%extra);

        my $id = $self->please_to_upload_for_real_now(\%args, \%extra);
        
        #

        return $id;
}

sub get_fireeagle_context_node {
        my $self = shift;
        my $hier = shift;
        my $ph_date = shift;
        my $args = shift;

        # right here, right now

        if (my $best = ($hier->findnodes("/rsp/user/location-hierarchy/location[\@best-guess='true']"))[0]){

                my $last_date = str2time($best->findvalue("located-at"));
                my $offset = $args->{'offset_fireeagle_exact'} || $OFFSET_FIREEAGLE_EXACT;

                if ($self->test_fireeagle_context_date($last_date, $ph_date, $offset)){
                        return $best;
                }
        }
        
        # neighbourhoods

        if (my $hood = ($hier->findnodes("/rsp/user/location-hierarchy/location[level=2]"))[0]){

                my $last_date = str2time($hood->findvalue("located-at"));
                my $offset = $args->{'offset_fireeagle_neighbourhood'} || $args->{'offset_fireeagle_neighborhood'} || $OFFSET_FIREEAGLE_NEIGHBOURHOOD;

                if ($self->test_fireeagle_context_date($last_date, $ph_date, $offset)){
                        return $hood;
                }
        }

        # 

        if (my $city = ($hier->findnodes("/rsp/user/location-hierarchy/location[level=3]"))[0]){

                my $last_date = str2time($city->findvalue("located-at"));
                my $offset = $args->{'offset_fireeagle_locality'} || $OFFSET_FIREEAGLE_LOCALITY;

                if ($self->test_fireeagle_context_date($last_date, $ph_date, $offset)){
                        return $city;
                }
        }

        return undef;
}

sub test_fireeagle_context_date {
        my $self = shift;
        my $fe_date = shift;
        my $ph_date = shift;
        my $offset = shift;

        # print "FE DATE : $fe_date\n";
        # print "PH DATE : $ph_date\n";
        # print "OFFSET : $offset\n";

        # FireEagle has a more recent update date than 
        # the photo's DateTaken time

        if ($fe_date > $ph_date){

                my $test = ($fe_date - $ph_date);

                if ($test <= $offset){
                        return 1;
                }

                return 0;
        }

        # Photo is more recent than FireEagle

        my $test = ($ph_date - $fe_date);

        if ($test <= $offset){
                return 1;
        }

        return 0;
}

sub generate_location_tags {
        my $self = shift;
        my $hier = shift;
        my $ctx = shift;

        my $id = $ctx->findvalue("id");
        my $ctx_level = $ctx->findvalue("level")->string_value();
        
        my @tags = ("fireeagle:id=$id");

        foreach my $node ($hier->findnodes("/rsp/user/location-hierarchy/location")){

                my $placeid = $node->findvalue("place-id");
                my $node_level = $node->findvalue("level")->string_value();

                if ($node_level < $ctx_level){
                        next;
                }

                if ($node_level == 2){
                        if (my $name = $self->fetch_places_name($placeid)){
                                my $model = $self->{'__fireeagle_args'}->{'tagify'} || "flickr";
                                push @tags, $self->tagify(lc($name), $model);
                        }
                        
                        next;
                }

                if ($node_level == 3){
                        
                        my $woeid = $node->findvalue("woeid");

                        push @tags, "places:locality=$placeid";
                        push @tags, "woe:id=$woeid";

                        if (my $name = $self->fetch_places_name($placeid)){
                                my $model = $self->{'__fireeagle_args'}->{'tagify'} || "flickr";
                                push @tags, $self->tagify(lc($name), $model);
                        }

                        last;
                }
        }

        return join(" ", @tags);
}

sub fetch_places_name {
        my $self = shift;
        my $placeid = shift;

        try {
                my $res = $self->flickr_api_call('flickr.places.resolvePlaceId', {'place_id' => $placeid});
                my $xml = XML::XPath->new('xml' => $res->decoded_content());
                
                return $xml->findvalue("/rsp/location/\@name");
        }
                
        catch Error with {
                # pass
        };
}

#
# All of the code to follow needs to be moved into
# Flickr::Upload::Localitify and merged with Flickr::Upload::Dopplr
#

sub gps_exif_to_latlon {
        my $self = shift;
        my $info = shift;

        my $parts_lat = $info->{'GPSLatitude'};
        my $parts_lon = $info->{'GPSLongitude'};

        my $ref_lat = uc($info->{'GPSLatitudeRef'});
        my $ref_lon = uc($info->{'GPSLongitudeRef'});

        my $lat = dms2decimal($parts_lat->[0], $parts_lat->[2], ($parts_lat->[4] / 100));
        my $lon = dms2decimal($parts_lon->[0], $parts_lon->[2], ($parts_lon->[4] / 100));

        if ($ref_lat eq 'S'){
                $lat = - $lat;
        }

        if ($ref_lon eq 'W'){
                $lon = - $lon;
        }

        return ($lat, $lon);
}

sub please_to_upload_for_real_now(){
        my $self = shift;
        my $args = shift;
        my $extra = shift;

        my $id = 0;

        try {
                $id = $self->SUPER::upload(%$args);
        }

        catch Error with {
                throw FlickrUploadException("Failed to upload photo to Flickr", shift);                
        };

        if (! $id){
                throw FlickrUploadException("Flickr::Upload did not return a photo ID");
        }

        # 
        # set lat/lon
        #

        if (exists($extra->{'lat'})){
                my %set = ('accuracy' => $args->{'acc'},
                           'lat' => $args->{'lat'},
                           'lon' => $args->{'lon'},
                           'auth_token' => $args->{'auth_token'},
                           'photo_id' => $id);
                
                $self->flickr_api_call('flickr.photos.geo.setLocation', \%set);
        }
        
        # 
        # set geo perms
        # 

        if (exists($extra->{'geo_perms'})){

                my %perms = %{$extra->{'geo_perms'}};

                $perms{'auth_token'} = $args->{'auth_token'};
                $perms{'photo_id'} = $id;

                if ($perms{'is_public'}){
                        foreach my $other ('is_contact', 'is_family', 'is_friend'){
                                if (! exists($perms{$other})){
                                        $perms{$other} = 1;
                                }
                        }
                }

                $self->flickr_api_call('flickr.photos.geo.setPerms', \%perms);
        }

        # 

        return $id;
}

sub fetch_fireeagle_hierarchy {
        my $self = shift;

        my $loc = undef;

        try {
                my $xml = $self->{'__fireeagle'}->location();
                $loc = XML::XPath->new('xml' => $xml);
                # print $xml . "\n";
        }

        catch Error with {
                warn "Failed to get current location from FireEagle, chugging along anyway";
        };

        return $loc;
}

sub flickr_api_call {
        my $self = shift;
        my $meth = shift;
        my $args = shift;

        my $res;

        try {
                $res = $self->execute_method($meth, $args);
        }
                
        catch Error with {
                my $e = shift;
                throw FlickrAPIException("API call $meth failed", 999, "Unknown API error");
        };

        if (! $res->{success}){
                my $e = shift;
                throw FlickrAPIException("API call $meth failed", $e, $res->{error_code}, $res->{error_message});
        }

        return $res;
}


#
# Please for someone to write Text::Tagify...
#

sub tagify {
	my $self = shift;
        my $tag = shift;
        my $model = shift;

        if (($model) && ($model eq "delicious")){
                return $self->tagify_like_delicious($tag);
        }

        return $self->tagify_like_flickr($tag);
}

sub tagify_like_flickr {
        my $self = shift;
        my $tag = shift;

        if ($tag =~ /\s/){
                $tag = "\"$tag\"";
        }

        return $tag;
}

sub tagify_like_delicious {
        my $self = shift;
        my $tag = shift;

        $tag =~ s/\s//g;
        return lc($tag);
}

#
# Just so so so wrong...but necessary until Flickr::Upload
# is updated to call $res->decoded_content()
#

sub upload_request($$) {
        my $self = shift;
        die "$self is not a LWP::UserAgent" unless $self->isa('LWP::UserAgent');
        my $req = shift;
        die "expecting a HTTP::Request" unless $req->isa('HTTP::Request');

        my $res = $self->request( $req );

        my $tree = XML::Parser::Lite::Tree::instance()->parse($res->decoded_content());
        return () unless defined $tree;

        my $photoid = response_tag($tree, 'rsp', 'photoid');
        my $ticketid = response_tag($tree, 'rsp', 'ticketid');
        unless( defined $photoid or defined $ticketid ) {
                print STDERR "upload failed:\n", $res->content(), "\n";
                return undef;
        }

        return (defined $photoid) ? $photoid : $ticketid;
}

sub response_tag {
        my $t = shift;
        my $node = shift;
        my $tag = shift;

        return undef unless defined $t and exists $t->{'children'};

        for my $n ( @{$t->{'children'}} ) {
                next unless defined $n and exists $n->{'name'} and exists $n->{'children'};
                next unless $n->{'name'} eq $node;

                for my $m (@{$n->{'children'}} ) {
                        next unless exists $m->{'name'}
                                and $m->{'name'} eq $tag
                                and exists $m->{'children'};

                        return $m->{'children'}->[0]->{'content'};
                }
        }
        return undef;
}

=head1 VERSION

0.1

=head1 DATE

$Date: 2008/04/22 07:01:19 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 NOTES

Aside from requiring your own Flickr API key, secret and authentication token
you will also need similar FireEagle (OAuth) credentials. Since Flickr::Upload::FireEagle
already requires that you install the excellent I<Net::FireEagle> you should just
use the command line I<fireeagle> client for authorizing yourself with FireEagle.

=head1 SEE ALSO

L<Net::FireEagle>

L<Flickr::Upload>

L<Flickr::Upload::Dopplr>

L<Flickr::API>

L<Error>

L<http://www.fireeagle.com/>

L<http://fireeagle.yahoo.net/developer>

L<http://laughingmeme.org/2008/01/18/flickr-place-ids/>

L<http://oauth.net/>

=head1 BUGS

Sure, why not.

Please report all bugs via http://rt.cpan.org/

=head1 LICENSE

Copyright (c) 2007-2008 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;
