#!/usr/bin/perl -w
# Copyright 2005 Jean-Michel Fayard jmfayard_at_gmail.com
# Put into the public domain.
#
# Example on how to use the Image::Kimdaba.pm module
# to parse the image database made by the beautiful
# Image::Kimdaba available on http://ktown.kde.org/kimdaba
# Copy paste from this to start your own script.
#
# To use it, run $ kimdaba -demo, 
# or launch the demo from the Image::Kimdaba help menu
# and run it as
#	./kim_example.pl /tmp/kimdaba-demo-$user
# (or whereever the pictures of the demo are stored )

use strict;
use diagnostics;
use Image::Kimdaba;
push @INC,"/mandrakelinux/usr/lib/perl5/site_perl/5.8.4";
use Gimp;

my @ListOfPictures;
my $folder=getRootFolder();
parseDB( "$folder" );
    # parse the xml file and create three hashes:
    # %imageattributes	: HASH OF (url of the picture, REF. HASH OF (attribute, value) )
    # %imageoptions	: HASH of (url, REF. HASH OF (optoin, REF. LIST OF value) )
    # %alloptions	: HASH of (option, REF. LIST of values)

my $nb1= scalar keys %imageattributes;
my $nb2= scalar keys %imageoptions;

print "Following options were present in your $nb1 pictures :\n";
while( my ($option,$r_values) = (each %alloptions) )
{
    my $nb = scalar @$r_values;
    print "\t$nb $option\n";
}
print "\n";

printImage( (keys %imageattributes)[0] );
printImage( (keys %imageattributes)[$nb2-1] );

print "\n\n== NO Keywords  ==\n";
@ListOfPictures=matchAnyOption( "Keywords" => [] );
print join("\n", sort @ListOfPictures);

print "\n\n== Holiday  ==\n";
@ListOfPictures=matchAnyOption( "Keywords" => [ "holiday" ] );
print join("\n", sort @ListOfPictures);

print "\n\n== ANNE HELENE ==\n";
@ListOfPictures=matchAnyOption( "Persons" => [ "Anne Helene" ] );
print join("\n", sort @ListOfPictures);

print "\n\n== ANY OF (JESPER, ANNE HELEN) ==\n";
@ListOfPictures=matchAnyOption( "Persons" => [ "Jesper" , "Anne Helene" ] );
print $_,"\n" foreach (sort @ListOfPictures);

print "\n\n== ALL OF (JESPER, ANNE HELEN) ==\n";
@ListOfPictures=matchAllOptions( "Persons" => [ "Jesper" , "Anne Helene" ] );
print join("\n", sort @ListOfPictures);

print "\n\n== PERSONS=Jesper, Locations=Mallorca ==\n";
@ListOfPictures=matchAllOptions( 
	"Persons" => [ "Jesper" ],
	"Locations" => [ "Mallorca" ]
	);
print join("\n", sort @ListOfPictures);
