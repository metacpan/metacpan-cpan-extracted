# $Id: Rule.pm,v 1.2 2007-09-21 08:58:50 mike Exp $

# Abstract base class for ServiceTypeRule and ServiceRule

package Keystone::Resolver::DB::Rule;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


sub fields { (id => undef,
	      fieldname => undef,
	      value => undef,
	      deny => undef,
	      tags => undef,
	      ) }

sub name {
    my $this = shift();
    return $this->fieldname() . "=" . $this->value();
}

sub search_fields { (fieldname => "t40",
		     value => "t40",
		     deny => [ qw(Include Exclude) ],
		     tags => "t40",
		     ) }

sub sort_fields { qw(fieldname value deny) }

sub display_fields { (fieldname => "Lt",
		      value => "Lt",
		      deny => [ qw(Include Exclude) ],
		      tags => "t",
		      ) }

sub field_map { {
    deny => "Action",
} }

1;
