#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Map;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Meta::Utils::Output qw();
use Meta::Ds::Hash qw();
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw();

#sub BEGIN();
#sub new($);
#sub insert($$$);
#sub has_a($$);
#sub has_b($$);
#sub get_a($$);
#sub get_b($$);
#sub remove_a($$);
#sub remove_b($$);
#sub remove($$$);
#sub size($);
#sub clear($);
#sub foreach($$);
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
	$self->set_hash_a(Meta::Ds::Hash->new());
	$self->set_hash_b(Meta::Ds::Hash->new());
	return($self);
}

sub insert($$$) {
	my($self,$elem_a,$elem_b)=@_;
	my($hash_a)=$self->get_hash_a();
	my($hash_b)=$self->get_hash_b();
	# check needs to be done in order to not contaminate the first
	# hash and then error on the second thus leaving the data
	# structure in a non coherent state
	$hash_a->check_hasnt($elem_a);
	$hash_b->check_hasnt($elem_b);
	$hash_a->insert($elem_a,$elem_b);
	$hash_b->insert($elem_b,$elem_a);
}

sub has_a($$) {
	my($self,$elem)=@_;
	return($self->get_hash_a()->has($elem));
}

sub has_b($$) {
	my($self,$elem)=@_;
	return($self->get_hash_b()->has($elem));
}

sub get_a($$) {
	my($self,$elem)=@_;
	return($self->get_hash_b()->get($elem));
}

sub get_b($$) {
	my($self,$elem)=@_;
	return($self->get_hash_a()->get($elem));
}

sub remove_a($$) {
	my($self,$elem_a)=@_;
	my($elem_b)=$self->get_b($elem_a);
	return($self->remove($elem_a,$elem_b));
}

sub remove_b($$) {
	my($self,$elem_b)=@_;
	my($elem_a)=$self->get_a($elem_b);
	return($self->remove($elem_a,$elem_b));
}

sub remove($$$) {
	my($self,$elem_a,$elem_b)=@_;
	# checks have to be made before removal so that
	# the data structure is not left in a contaminated
	# state if the first removal succeeds and the second
	# doesnt
	$self->get_hash_a()->check_has($elem_a);
	$self->get_hash_b()->check_has($elem_b);
	$self->get_hash_a()->remove($elem_a);
	$self->get_hash_b()->remove($elem_b);
	return(1);
}

sub size($) {
	my($self)=@_;
	return($self->get_hash_a()->size());
}

sub clear($) {
	my($self)=@_;
	$self->get_hash_a()->clear();
	$self->get_hash_b()->clear();
}

sub foreach($$) {
	my($self,$code)=@_;
	$self->get_hash_a()->foreach($code);
}

sub TEST($) {
	my($context)=@_;
	my($obj)=__PACKAGE__->new();
	$obj->insert("foo","bar");
	$obj->insert("mark","veltzer");
	Meta::Utils::Output::print("size is [".$obj->size()."]\n");
	Meta::Utils::Output::dump($obj);
	Meta::Utils::Output::print("removing\n");
	$obj->remove_a("foo");
	Meta::Utils::Output::dump($obj);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Map - a 1-1 map object.

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

	MANIFEST: Map.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Map qw();
	my($object)=Meta::Ds::Map->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This data structure is a 1-1 map. This means that you can for instance,
store a social id to driver id mapping (since no two people have the
same social id or driver id). Trying to insert a value which already
exists (in either of the hashes) will cause an exception.

This class is implemented using a pair of Hash structures. This means
that querying in each direction (A to B or B to A) is quite efficient.

Removal is also quite efficient (O(1) on both sides).

Size is implemented as size of one of the hashes (they are always the
same size).

=head1 FUNCTIONS

	BEGIN()
	new($)
	insert($$$)
	has_a($$)
	has_b($$)
	get_a($$)
	get_b($$)
	remove_a($$)
	remove_b($$)
	remove($$$)
	size($)
	clear($)
	foreach($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method for this class which creates the accessors for hash_a and hash_b.
This means that you can access the actual hashes using get_hash_a and get_hash_b.
Just be careful to do it for read only access becuase toying with these without
knowing what you are doing may render this class unusable.

=item B<new($)>

This is a constructor for the Meta::Ds::Map object.

=item B<insert($$$)>

This inserts an pair into the map object.

=item B<has_a($$)>

Returns whether the map has the element in side A.

=item B<has_b($$)>

Returns whether the map has the element in side B.

=item B<get_a($$)>

This retrieves the pair of element on side A.

=item B<get_b($$)>

This retrieves the pair of element on side B.

=item B<remove_a($$)>

This removes a pair according to element on side A.

=item B<remove_b($$)>

This removes a pair according to element on side B.

=item B<remove($$$)>

This method removes a pair from the map.

=item B<size($)>

This method will give you the size of the map.

=item B<clear($)>

This method will clear the map. It is quick.

=item B<foreach($$)>

This method will run a piece of code given to it on every pair of elements
in the map. The code should be a subroutine which accepts two arguments. The
arguments are a and then b.

=item B<TEST($)>

This is a testing suite for the Meta::Ds::Map module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

Currently this test creates the object, does some manipulation and dumps it.

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
	0.01 MV more pdmt stuff
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Ds::Hash(3), Meta::Error::Simple(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-stop using ordered hashes for this class - it does not make use of them.

-idea: store another hash with all pairs joined by $;. This could be used for fast iteration on all elements.
