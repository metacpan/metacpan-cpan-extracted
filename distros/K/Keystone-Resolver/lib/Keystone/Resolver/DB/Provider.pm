# $Id: Provider.pm,v 1.5 2007-09-13 09:42:47 mike Exp $

package Keystone::Resolver::DB::Provider;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


sub table { "provider" }

sub fields { (id => undef,
	      name => undef,
	      priority => undef,
	      contact => undef,
	      services => [ id => "Service", "provider_id", "name" ],
	      ) }

sub search_fields { (name => "t25",
		     priority => "n5",
		     ) }

sub sort_fields { ("priority", "name") }

sub display_fields { (name => "Lt",
		      priority => "n",
		      contact => "t",
		      ) }

sub fulldisplay_fields { (name => "Lt",
			  priority => "n",
			  contact => "t",
			  services => "t",
			  ) }

1;
