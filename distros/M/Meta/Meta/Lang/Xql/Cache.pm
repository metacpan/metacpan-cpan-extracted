#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Xql::Cache;

use strict qw(vars refs subs);
use Meta::Ds::Map qw();
use Meta::Lang::Xql::Query qw();
use Meta::Utils::System qw();
use Meta::Utils::Output qw();
use Meta::Class::MethodMaker qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw();

#sub BEGIN();
#sub init($);
#sub insert($$$);
#sub get_by_name($$);
#sub get_by_xql($$);
#sub remove_by_name($$);
#sub remove_by_xql($$);
#sub size($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new_with_init("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_query_number",
		-java=>"_map_name",
		-java=>"_map_xql",
	);
}

sub init($) {
	my($self)=@_;
	$self->set_map_name(Meta::Ds::Map->new());
	$self->set_map_xql(Meta::Ds::Map->new());
	$self->set_query_number(0);
}

sub insert($$$) {
	my($self,$name,$xql)=@_;
	my($query);
	if($self->get_map_name()->has_a($name)) {
		throw Meta::Error::Simple("name [".$name."] already exists");
	}
	if($self->get_map_xql()->has_a($xql)) {
		$query=$self->get_map_xql()->get($xql);
	} else {
		$query=Meta::Lang::Xql::Query->new(Expr=>$xql);
		$self->set_query_number($self->get_query_number()+1);
	}
	$self->get_map_name()->insert($name,$query);
	$self->get_map_xql()->insert($xql,$query);
}

sub get_by_name($$) {
	my($self,$val)=@_;
	return($self->get_map_name()->get_b($val));
}

sub get_by_xql($$) {
	my($self,$val)=@_;
	return($self->get_map_xql()->get_b($val));
}

sub remove_by_name($$) {
	my($self,$val)=@_;
	my($query)=$self->get_by_name($val);
	my($xql)=$self->get_map_xql()->get_a($query);
	$self->get_map_name()->remove($val,$query);
	$self->get_map_xql()->remove($xql,$query);
}

sub remove_by_xql($$) {
	my($self,$val)=@_;
	my($query)=$self->get_by_xql($val);
	my($name)=$self->get_map_name()->get_a($query);
	$self->get_map_name()->remove($name,$query);
	$self->get_map_xql()->remove($val,$query);
}

sub size($) {
	my($self)=@_;
	return($self->get_map_name()->size());
}

sub TEST($) {
	my($context)=@_;
	my($obj)=__PACKAGE__->new();
	$obj->insert("first","a");
	$obj->insert("second","b");
	Meta::Utils::Output::print("size is [".$obj->size()."]\n");
	$obj->remove_by_name("first");
	Meta::Utils::Output::print("size is [".$obj->size()."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Xql::Cache - cache XML::XQL::Query objects according to name or content.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Cache.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Xql::Cache qw();
	my($object)=Meta::Lang::Xql::Cache->new();
	my($result)=$object->method();

=head1 DESCRIPTION

The idea of this module is to ease development of code which does heavy
use of XML::XQL::Query objects and let the programmer stop worrying about
allocating the same XML::XQL::Query object twice and wasting resources.

The developer allocates a single object of type Meta::Lang::Xql::Cache
and asks it to create XML::XQL::Query objects. If you ask it to create
an object with the same XQL code then it returns the object already
created. In addition you can give each object a symbolic name and then
retrieve each query object (or code) using that symbolic name.

Have fun!

=head1 FUNCTIONS

	BEGIN()
	init($)
	insert($$$)
	get_by_name($$)
	get_by_xql($$)
	remove_by_name($$)
	remove_by_xql($$)
	size($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<insert($$$)>

This method receives a name and a content of an XQL statement.
The return is an XML::XQL::Query object to be used. Create all your
XML::XQL::Query objects using this method. This is a static method.

=item B<get_by_name($$)>

This method will retrieve an XML::XQL::Query according to it's name.

=item B<get_by_xql($$)>

This method will retrieve an XML::XQL::Query according to it's code.

=item B<remove_by_name($$)>

This will remove an XML::XQL::Query from the cache according to name.

=item B<remove_by_xql($$)>

This will remove an XML::XQL::Query from the cache according to code.

=item B<size($)>

This method will return the size of the XQL cache. This means number
of entries in the name caches and NOT number of queries.

=item B<TEST($)>

This is a testing suite for the Meta::Lang::Xql::Cache module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

The tests creats a cache, puts some stuff into it, prints the size, removes
an element and prints the size again. Pretty simple but should catch most
people breaking the code (unless they are clever).

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Class::MethodMaker(3), Meta::Ds::Map(3), Meta::Lang::Xql::Query(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-add method which retrieves number of objects of type XML::XQL::Query which are held.
