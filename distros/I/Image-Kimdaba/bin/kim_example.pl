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
use English qw( -no_match_vars ) ;

my @ListOfPictures;

my $folder=getRootFolder();
parseDB( "$folder" );
    # parse the xml file and create three hashes:
    # %imageattributes	: HASH OF (url of the picture, REF. HASH OF (attribute, value) )
    # %imageoptions	: HASH of (url, REF. HASH OF (optoin, REF. LIST OF value) )
    # %alloptions	: HASH of (option, REF. LIST of values)
    # %kimdabaconfig	: HASH of (attributes, values) 
    #			[attributes of the config element in index.xml]
    # %membergroups	: HASH : (Locations => REF (HASH : USA => [ Chicago, Los Angeles ] ) )
    #
    # note :  the reading of man:/perllol is highly recommended


print "Your actual Kimdaba settings are :\n";
while( my ($attr, $value) = each %kimdabaconfig)
{
    print "\t$attr => $value\n";
}
print "\n";

my $nb1= scalar keys %imageattributes;
my $nb2= scalar keys %imageoptions;
print "Following options were present in your $nb1 pictures :\n";
while( my ($option,$r_values) = each %alloptions )
{
    my $nb = scalar @$r_values;
    print "\t$nb $option\n";
}
print "\n";

local $, = "\n" ; # print bla,bla prints "bla\nbla"

print "\n\n== NO Keywords  (ten first) ==\n";
@ListOfPictures=matchAnyOption( "Keywords" => [] );
print sort(@ListOfPictures[0..9]);

print "\n\n== Holiday  ==\n";
@ListOfPictures=matchAnyOption( "Keywords" => [ "holiday" ] );
print sort(@ListOfPictures);

print "\n\n== ANNE HELENE ==\n";
@ListOfPictures=matchAnyOption( "Persons" => [ "Anne Helene" ] );
print sort(@ListOfPictures);

print "\n\n== ANY OF (JESPER, ANNE HELEN) ==\n";
@ListOfPictures=matchAnyOption( "Persons" => [ "Jesper" , "Anne Helene" ] );
print sort(@ListOfPictures);

print "\n\n== ALL OF (JESPER, ANNE HELEN) ==\n";
@ListOfPictures=matchAllOptions( "Persons" => [ "Jesper" , "Anne Helene" ] );
print sort(@ListOfPictures);

print "\n\n== PERSONS=Jesper, Locations=Mallorca ==\n";
@ListOfPictures=matchAllOptions( 
	"Persons" => [ "Jesper" ],
	"Locations" => [ "Mallorca" ]
	);
print sort(@ListOfPictures);



$, = "" ; # print bla,bla prints "blabla"

print "\n\nMember-groups\n";
my %loop;
&print_membergroup;	# Note this is not part of the API, 
			# it's a sub defined at the bottom that show how to use the %membergroups hash

print "\n\n==Print all infos known about specific pictures\n";
print "\n\n== Drag&Drop pictures from Kimdaba  ==\n";
@ListOfPictures=letMeDraganddropPictures();
printImage( $_ ) foreach @ListOfPictures;





# For the fun, print recursively the member-groups,
# But remember to avoid loops ;-)
sub print_membergroup
{
    while( my ($category, $r_hash) = each %membergroups )
    {
	print "|-- $category\n";
	while( my ($groupname, $r_members) = each %$r_hash )
	{
	    %loop = ( $groupname => 1);
	    my $prefix="|   ";
	    continue_print_membergroup($prefix, $category, $groupname, $r_members);
	}
    }
    print "\n";

}

sub continue_print_membergroup 
{
    my ($prefix, $category,$groupname,$r_members) = @_;
    print "$prefix|-- $groupname\n";
    for my $member (@$r_members)
    {
	print "$prefix|   |-- $member\n";
	if (
		exists( $membergroups{$category}{$member} ) 
	   )
	{
	    if ( exists( $loop{$member} ))
	    {
		print "$prefix|   |   |-- <LOOP AVOIDED>\n";
	    } else {
		$loop{$member} = 1;
		continue_print_membergroup( "|   ".$prefix, $category, $member, $membergroups{$category}{$member}  );
	    }
	}
    }
}




