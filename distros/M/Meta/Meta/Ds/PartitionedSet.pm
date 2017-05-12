#!/bin/echo This is a perl module and should not be run

package Meta::Ds::PartitionedSet;

use strict qw(vars refs subs);
use Meta::Ds::Oset qw();
#use Meta::Ds::Ohash qw();
use Meta::Ds::Hash qw();
use Meta::Utils::Output qw();
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Ds::Oset);

#sub BEGIN();
#sub new($);
#sub insert($$);
#sub remove_value($$$);
#sub remove($$);
#sub get_set($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_value_hash",
		-java=>"_attribute_hash",
	);
}

sub new($) {
	my($class)=@_;
	my($self)=Meta::Ds::Oset::new($class);
	$self->set_value_hash(Meta::Ds::Hash->new());
	$self->set_attribute_hash(Meta::Ds::Hash->new());
	return($self);
}

sub insert($$$) {
	my($self,$node,$value)=@_;
	$self->SUPER::insert($node);
	$self->get_value_hash()->insert($node,$value);
	if($self->get_attribute_hash()->hasnt($value)) {
		$self->get_attribute_hash()->insert($value,Meta::Ds::Oset->new());
	}
	$self->get_attribute_hash()->get($value)->insert($node);
}

sub remove_value($$$) {
	my($self,$node,$value)=@_;
	$self->get_value_hash()->remove($node);
	$self->get_attribute_hash()->get_val($value)->remove($node);
	if($self->get_attribute_hash()->get_val($value)->is_empty()) {
		$self->get_attribute_hash()->remove($value);
	}
	$self->SUPER::remove($node);
}

sub remove($$) {
	my($self,$node)=@_;
	my($value)=$self->get_value_hash()->get_val($node);
	return($self->remove_value($self,$node,$value));
}

sub get_set($$) {
	my($self,$value)=@_;
	return($self->get_attribute_hash()->get($value));
}

sub TEST($) {
	my($context)=@_;
	my($object)=__PACKAGE__->new();
	$object->insert("abcde",5);
	$object->insert("abcd",4);
	$object->insert("mark",4);
	my($set)=$object->get_set(4);
	Meta::Utils::Output::dump($set);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::PartitionedSet - A set which is partitioned according to an attribute value.

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

	MANIFEST: PartitionedSet.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::PartitionedSet qw();
	my($object)=Meta::Ds::PartitionedSet->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class is a partitioned set. Let say that you have set of objects
but each object has an attribute (say a color). You want to maintain
This set so that:
1. You could iterate over all its elements.
2. You could easily get from an object to it's attribute.
3. You could easily iterate over all object where the attribute
	has a certain value.
This is what this partitioned set is all about.

Have fun!

=head1 FUNCTIONS

	BEGIN()
	new($)
	insert($$$)
	remove_value($$$)
	remove($$)
	get_set($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap function to set the following attributes:
0. value_hash - hash of values stored in the partition.
1. attribute_hash - hash of attributes stored in the partition.

=item B<new($)>

constructor for this object.

=item B<insert($$$)>

This is the basic insertion method. Insert an object and it's attribute.

=item B<remove_value($$$)>

This method removes an element for which the attribute value is known.

=item B<remove($$)>

This method removes an element for which the attribute value is unknown.

=item B<get_set($$)>

This method returns the set of members which have a certain value.

=item B<TEST($)>

This is a testing suite for the Meta::Ds::PartitionedSet module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

Currently this test just creates an object, inserts a few things and then
dumps the resulting object.

=back

=head1 SUPER CLASSES

Meta::Ds::Oset(3)

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

Meta::Class::MethodMaker(3), Meta::Ds::Hash(3), Meta::Ds::Oset(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.
