# $Id: User.pm,v 1.7 2007-09-12 22:14:52 mike Exp $

package Keystone::Resolver::DB::User;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);

sub table { "user" }

sub fields { (id => undef,
	      site_id => undef,
	      admin => undef,
	      name => undef,
	      email_address => undef,
	      password => undef,
	      ) }

sub mandatory_fields { qw(name email_address password) }

sub search_fields { (admin => [ qw(User Administrator Wizard) ],
		     name => "t30",
		     email_address => "t50",
		     ) }

sub sort_fields { ("email_address") }

# It doesn't seem right that we have to define the "admin" enumeration
# in two different places, but it can't easily fit into fields()
# because that as to encapsulate recipes, too.
#
sub display_fields { (admin => [ qw(User Administrator Wizard) ],
		      name => "Lt",
		      email_address => "t",
		      password => "t",
		      ) }

1;
