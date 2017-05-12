# $Id: Serial.pm,v 1.7 2008-04-02 13:01:21 mike Exp $

package Keystone::Resolver::DB::Serial;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


sub table { "serial" }

sub fields { (id => undef,
	      name => undef,
	      issn => undef,
	      aliases => [ id => "SerialAlias", "serial_id", "alias" ],
	      ) }

sub search_fields { (name => "t25",
		     issn => "t12",
		     ) }

sub sort_fields { ("name") }

sub display_fields { (name => "Lt",
		      issn => "t",
		      ) }

sub fulldisplay_fields { (shift()->display_fields(),
			  aliases => "t",
			  ) }

sub field_map { {
    issn => "ISSN",
} }

1;
