# $Id: Service.pm,v 1.20 2008-04-02 13:01:52 mike Exp $

package Keystone::Resolver::DB::Service;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


# The name of the physical table in which objects of this type are
# held.
#
sub table { "service" }

# Unordered list of fields, both physical and virtual, that exist
# within records of this type.  This function is used extensively
# within DB::Object, but there is no good reason for application code
# ever to use it directly.
#
# The LHS is the field name.  The RHS for physical fields is
# undefined; for virtual fields, it is an array of three, four or five
# elements, the first three of which are always the same: the physical
# field that provides the link, the class of the kind of object that
# it links to, and the field within that class that acts as the link.
# When the fourth element is absent, the link is a dependent one to a
# single "parent" object; when the fourth element is present, the link
# is to a list of associated objects, and the fourth element is the
# order in which they should be sorted.  Non-dependent-link virtual fields
# usually return the name of the parent object, but if a fifth element
# is specified it is the name of a parent-object field to return.
#
# The keys in the hashes returned by the display_fields(),
# fulldisplay_fields() and field_map() methods below must be drawn
# from those returned by fields().  Those returned by search_fields()
# and sort_fields() must, further, be physical fields rather than
# virtual.
#
sub fields { (id => undef,
	      service_type_id => undef,
	      service_type => [ service_type_id => "ServiceType", "id" ],
	      service_type_tag => [ service_type_id => "ServiceType", "id",
				    undef, "tag" ],
	      service_type_plugin => [ service_type_id => "ServiceType", "id",
				       undef, "plugin" ],
	      provider_id => undef,
	      provider => [ provider_id => "Provider", "id" ],
	      tag => undef,
	      name => undef,
	      priority => undef,
	      url_recipe => undef,
	      need_auth => undef,
	      auth_recipe => undef,
	      disabled => undef,
	      ) }

# Ordered list of fields for searching.  RHS is one of:
#	t<n> = text field of <n> characters
#	n<n> = numeric field of <n> characters
#	b = boolean
#	s = separator (fieldname is ignored)
#
sub search_fields { (tag => "t10",
		     name => "t25",
		     priority => "n5",
		     url_recipe => "t25",
		     need_auth => "b",
		     disabled => "b",
		     ) }

sub sort_fields { ("priority asc", "name") }

# display_fields() and fulldisplay_fields() are ordered list of fields
# for display -- the former in single-line record summaries in search
# result lists, the latter in single-whole-record displays.  LHS is
# fieldname.  RHS is one of:
#	t = text
#	c = code-fragment (text in a fixed-width font)
#	n = number
#	b = boolean
#	ARRAY reference = strings for enumeration
# An RHS other than an ARRAY may be preceded by one or more of the
# following, in any order:
#	R: readonly (e.g. "Rt" = readonly text)
#	X: exclude when creating a new object
#	L: link through to full record
#
sub display_fields { (tag => "c",
		      name => "Lt",
		      priority => "n",
		      need_auth => "b",
		      disabled => "b",
		      ) }

sub fulldisplay_fields { (service_type => "Rt",
			  provider => "Rt",
			  tag => "Rc",
			  name => "t",
			  priority => "n",
			  url_recipe => "t",
			  need_auth => "b",
			  auth_recipe => "t",
			  disabled => "b",
			  ) }

sub uneditable_fields { qw(service_type_tag service_type_plugin) }

sub field_map { {
    url_recipe => "URL recipe",
    need_auth => "Needs authentication?",
    auth_recipe => "Authentication recipe",
    disabled => "Disabled?",
} }

1;
