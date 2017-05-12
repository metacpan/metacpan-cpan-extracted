#!/usr/bin/perl -w
use strict;
use Flickr::Photo;
use Flickr::License;
use Data::Dumper;

# id of one of my photos
my $photo_id="726927470";

# my apikey
my $APIKEY="eca139188e928544ffa9c8593f81cb2d";

# create a new empty License object
my $license=Flickr::License->new({api_key=>$APIKEY});

# create a new photo
my $photo= Flickr::Photo->new({api_key=>$APIKEY});

# grab photo details
if ($photo->id({id => $photo_id})) {

    # set license id
    $license->id($photo->license);

}

# print license details if license is valid
if ($license->valid) {
    print "License Details:\n";
    print $license->name."\n";
    print $license->url."\n";
}
