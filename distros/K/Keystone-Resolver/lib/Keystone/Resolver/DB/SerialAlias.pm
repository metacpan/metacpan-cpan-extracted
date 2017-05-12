# $Id: SerialAlias.pm,v 1.2 2008-04-02 13:00:47 mike Exp $

package Keystone::Resolver::DB::SerialAlias;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


sub table { "serial_alias" }

sub fields { (id => undef,
	      serial_id => undef,
	      alias => undef,
	      canonical_title => [ serial_id => "Serial", "id" ],
	      ) }

sub name { shift()->alias() }

sub search_fields { (alias => "t25",
		     ) }

sub sort_fields { ("alias") }

sub display_fields { (alias => "Lt",
		      canonical_title => "t",
		      ) }

1;
