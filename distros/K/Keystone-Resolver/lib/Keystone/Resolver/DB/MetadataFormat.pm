# $Id: MetadataFormat.pm,v 1.1 2007-07-12 13:10:56 mike Exp $

package Keystone::Resolver::DB::MetadataFormat;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);

sub table { "mformat" }

sub fields { (id => undef,
	      genre_id => undef,
	      genre => [ genre_id => "Genre", "id" ],
	      name => undef,
	      uri => undef,
	      ) }

sub search_fields { (name => "t20",
		     uri => "t40",
		     ) }

sub sort_fields { ("name") }

sub display_fields { (name  => "t",
		      uri => "Lt",
		      ) }

sub fulldisplay_fields { (name  => "t",
			  uri => "t",
			  genre => "t",
			  ) }

sub field_map { {
    uri => "URI",
} }

1;
