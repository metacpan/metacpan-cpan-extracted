#!/usr/bin/perl -w
# Copyright 2005 Jean-Michel Fayard jmfayard_at_gmail.com
# Put into the public domain.
#
# Example on how to use the Image::Kimdaba.pm module
# to parse & update the image database made by the beautiful
# Kimdaba available on http://ktown.kde.org/kimdaba
# Copy paste from this to start your own script.
#
# To use it, run $ kimdaba -demo, 
# or launch the demo from the Kimdaba help menu
# and run it as
#	./kim_example_modifyb.pl /tmp/kimdaba-demo-$user
# (or whereever the pictures of the demo are stored )

# This example shows how to make change in the database
# Instead of modifying directly the database (which could easily be dangerous
# for your data), you write a kimdaba export file (*.kim)
# then you use the import fonction in kimdaba (no dangerous, you are in control)
#
# A .kim file is a zip archive containning an index.xml file, and
# a Thumbnail directory. You just have to create the index.xml file 
# (say in '/tmp') then you call :
#
#   makeKimFile( "/tmp", "perl_output.kim", @ListOfPictures );
# where /tmp/index.xml is the file created by you
#	/tmp/perl_output.kim	is the resulting kimdaba import ile
#	@ListOfPictures		is a list of urls present in /tmp/index.xml


use strict;
use diagnostics;
use Image::Kimdaba;
use English qw( -no_match_vars ) ;

my @ListOfPictures;

my $folder=getRootFolder();
parseDB( "$folder" );

print "\n\n== Drag&Drop pictures from Kimdaba  ==\n";
@ListOfPictures=letMeDraganddropPictures();
print join("\n", sort(@ListOfPictures));
print "--\n";

my $destdir="/tmp";
open( EXPORT, "> ${destdir}/index.xml");
print EXPORT <<FIN
<?xml version="1.0" encoding="UTF-8"?>
<KimDaBa-export location="external" >
FIN
;

for my $url (@ListOfPictures)
{
    my $description="yeah! I changed the description";
    my $md5sum="";
    if (
	(exists $imageattributes{$url})
	&&
	(exists $imageattributes{$url}{'md5sum'})
	&&
	(! $imageattributes{$url}{'md5sum'} eq "")
       )
    {
	$md5sum="md5sum=\"$imageattributes{$url}{'md5sum'}\" ";
    }
	
    
    my $value="Test Add Another Keyword";
    print EXPORT <<FIN
 <image description="$description" $md5sum file="$url" >
  <options>
   <option name="Keywords" >
    <value value="Test Add a keyword" />
    <value value="$value" />
   </option>
  </options>
 </image>
FIN
    ;
}

print EXPORT <<FIN
</KimDaBa-export>
FIN
;
close( EXPORT );


makeKimFile( $destdir, "perl_export.kim", @ListOfPictures);
