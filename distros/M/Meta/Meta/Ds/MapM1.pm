#!/bin/echo This is a perl module and should not be run

package Meta::Ds::MapM1;

use strict qw(vars refs subs);
use Meta::Ds::Noset qw();
use Meta::Ds::Ohash qw();
use Meta::Class::MethodMaker qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw();

#sbu BEGIN();
#sub new($);
#sub insert($$$);
#sub has_a($$);
#sub has_b($$);
#sub get_a($$);
#sub get_b($$);
#sub remove($$$);
#sub remove_a($$);
#sub remove_b($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_hash_a",
		-java=>"_hash_b",
	);
}

sub new($) {
	my($class)=@_;
	my($self)={};
	CORE::bless($self,$class);
	$self->set_hash_a(Meta::Ds::Ohash->new());
	$self->set_hash_b(Meta::Ds::Ohash->new());
	return($self);
}

sub insert($$$) {
	my($self,$elem_a,$elem_b)=@_;
	$self->get_hash_a()->insert($elem_a);
	my($hash_b)=$self->get_hash_b();
	if($hash_b->has($elem_b)) {
		$hash_b->get($elem_b)->insert($elem_a);
	} else {
		my($set)=Meta::Ds::Noset->new();
		$set->insert($elem_a);
		$hash_b->insert($elem_b,$set);
	}
}

sub has_a($$) {
	my($self,$elem_a)=@_;
	return($self->get_hash_a()->has($elem_a));
}

sub has_b($$) {
	my($self,$elem_b)=@_;
	return($self->get_hash_b()->has($elem_b));
}

sub get_a($$) {
	my($self,$elem_b)=@_;
	return($self->get_hash_b()->get($elem_b));
}

sub get_b($$) {
	my($self,$elem_a)=@_;
	return($self->get_hash_a()->get($elem_a));
}

sub remove($$$) {
	my($self,$elem_a,$elem_b)=@_;
	$self->get_hash_a()->remove($elem_a);
	my($hash_b)=$self->get_hash_b();
	my($set)=$hash_b->get($elem_b);
	$set->remove($elem_a);
	if($set->size()==0) {
		$hash_b->remove($set);
	}
}

sub remove_a($$) {
	my($self,$elem_a)=@_;
	my($elem_b)=$self->get_b($elem_a);
	$self->remove($elem_a,$elem_b);
}

sub remove_b($$) {
	my($self,$elem_b)=@_;
	my($set)=$self->get_a($elem_b);
	my($hash_a)=$self->get_hash_a();
	for(my($i)=0;$i<$set->size();$i++) {
		my($curr)=$set->elem($i);
		$hash_a->remove($curr);
	}
	$self->get_hash_b()->remove($elem_b);
}

sub TEST($) {
	my($context)=@_;
	my($map)=__PACKAGE__->new();
	$map->insert("mark","31");
	$map->insert("ofir","31");
	$map->insert("doron","26");
	my($set)=$map->get_a("31");
	Meta::Utils::Output::dump($set);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::MapM1 - Many to 1 map data structure.

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

	MANIFEST: MapM1.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::MapM1 qw();
	my($object)=Meta::Ds::MapM1->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This object is a many to 1 data structure. It allows you store, for instance
, a mapping between social id numbers and age. You can efficiently retrieve
the set of all social ids which have the same age as an ordered set. Any
types of objects can be stored here.

The implementation stores two ordered hashes where the first stores the
actual values while the other stores sets.

Have fun!

=head1 FUNCTIONS

	BEGIN()
	new($)
	insert($$$)
	has_a($$)
	has_b($$)
	get_a($$)
	get_b($$)
	remove($$$)
	remove_a($$)
	remove_b($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method which makes the attributes "hash_a" and "hash_b". 
This means you can get them using "get_hash_a" and "get_hash_b". Be careful
with what you do with those. The best way is use them on a read only basis
(if you are using them at all).

=item B<new($)>

This is a constructor for the Meta::Ds::MapM1 object.

=item B<insert($$$)>

This method inserts a new element. An exception will be raised if the first
element is already present.

=item B<has_a($$)>

Returns whether the map has a specific a type element.

=item B<has_b($$)>

Returns whether the map has a specific b type element.

=item B<get_a($$)>

Use this method to retrive the set of values which have a specific value
in the b set. The result is a Meta::Ds::Noset type object which you can
iterate or whatever. Use it as read only or be accountable.

=item B<get_b($$)>

This method will retrive the single value associated with the given value.
The result is a single value (unlike in get_a).

=item B<remove($$$)>

Supply this method with an a side element and a b side element and it
will be removed from the map.

=item B<remove_a($)>

Supply this method with an a side element and it will be removed from the map.
The method simply finds the b element associated with this a element and
calls the above mentioned "remove" method.

=item B<remove_b($)>

This method will remove *** ALL *** elements which map to a certain b
element. Take heed.

=item B<TEST($)>

This is a testing suite for the Meta::Ds::MapM1 module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

This test currently creates a map and toys with it.

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

	0.00 MV more pdmt stuff
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Ds::Noset(3), Meta::Ds::Ohash(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.
