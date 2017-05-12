# $Id: ServiceType.pm,v 1.9 2008-02-07 14:28:44 mike Exp $

package Keystone::Resolver::DB::ServiceType;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


sub table { "service_type" }

sub fields { (id => undef,
	      tag => undef,
	      name => undef,
	      plugin => undef,
	      priority => undef,
	      services => [ id => "Service", "service_type_id", "name" ],
	      ) }

sub search_fields { (tag => "t10",
		     name => "t25",
		     plugin => "t25",
		     priority => "n5",
		     ) }

sub sort_fields { ("priority asc", "name") }

sub display_fields { (id => "n",
		      tag => "c",
		      name => "Lt",
		      priority => "n",
		      ) }

sub fulldisplay_fields { (tag => "c",
			  name => "t",
			  plugin => "t",
			  priority => "n",
			  services => "t",
			  ) }

1;
