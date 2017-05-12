# $Id: Domain.pm,v 1.9 2007-09-12 22:14:11 mike Exp $

package Keystone::Resolver::DB::Domain;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


sub table { "domain" }

sub fields { (id => undef,
	      domain => undef,
	      status => undef,
	      ) }

sub name { shift()->domain() }

sub search_fields { (domain => "t40",
		     status => [ qw(Fetch DontFetch Try) ],
		     ) }

sub sort_fields { ("domain") }

sub display_fields { (domain => "Lt",
		      status => [ "Fetch; abort on failure",
				  "Do not even try to fetch",
				  "Try to fetch; ignore failure" ],
		      ) }

1;
