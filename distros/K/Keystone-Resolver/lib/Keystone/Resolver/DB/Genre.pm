# $Id: Genre.pm,v 1.8 2007-09-13 09:42:33 mike Exp $

package Keystone::Resolver::DB::Genre;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


sub table { "genre" }

sub fields { (id => undef,
	      tag => undef,
	      name => undef,
	      metadata_formats =>
		[ id => "MetadataFormat", "genre_id", "name" ],
	      ) }

sub search_fields { (tag => "t10",
		     name => "t25",
		     ) }

sub sort_fields { ("name") }

sub display_fields { (tag => "c",
		      name => "Lt",
		      ) }

sub fulldisplay_fields { (tag => "c",
			  name => "Lt",
			  metadata_formats => "t",
			  ) }

1;
