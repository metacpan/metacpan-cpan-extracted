#!/usr/bin/perl -w
# Copyright 2005 Jean-Michel Fayard jmfayard_at_gmail.com
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public
#   License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; see the file COPYING.  If not, write to
#   the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#   Boston, MA 02111-1307, USA.

# Changelog:
#	17/01/2005  Initial version

use strict;
use Image::Kimdaba;

my $folder=getRootFolder();
parseDB( "$folder" );
    # parse the xml file and create two hashes:
    # %imageattributes	: HASH OF (url of the picture, REF. HASH OF (attribute, value) )
    # %imageoptions	: HASH of (url, REF. HASH OF (optoin, REF. LIST OF value) )
my $notest = scalar grep { /--notest/ } @ARGV;
	    
chdir $folder;
my $i=0;
for my $url (keys %imageattributes)
{
    $i++;
    unless( $url =~ m/.jpe?g$/i ) {
	next;
    }
    next unless (-e $url);
   my $angle=$imageattributes{$url}{"angle"};
   if ( ($angle eq "180" ) or ( $angle eq "90" ) or ($angle eq "270") ){
	print "jpegtran -trim -rotate $angle $url "; 
       if ($notest) {
	   my @args=(  "jpegtran", "-outfile", "temp.jpg", "-trim", "-rotate" , $angle, $url  );
	   my $err = system @args;
	   if ($err != 0) 
	   {
		print "... FAILED\n";
	   } else {
	       $err = rename( "temp.jpg", $url );
	       print ($err!=0?"... FAILED\n":"... OK\n");
	   }
       } else {
	   print "\n";
       }
   }
}
if ($notest) {
    symlink "${folder}/index.xml", "${folder}/.index.xml.old" ;
    print STDERR <<FIN
All jpeg pictures rotated. If you already quit Image::Kimdaba,
you can manually update your database with following command :
  \$ perl -pi -e 's/ angle="\\d+/ angle="0/' ${folder}/index.xml
FIN
;

} else {
    print STDERR "Now run this script with --notest to really rotate your pictures\n"; 
}
