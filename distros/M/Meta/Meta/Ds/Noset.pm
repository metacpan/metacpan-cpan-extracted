#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Noset;

use strict qw(vars refs subs);
use Meta::Ds::Map qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::File qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw(Meta::Ds::Map);

#sub insert($$);
#sub remove($$);
#sub has($$);
#sub hasnt($$);
#sub check_has($$);
#sub check_hasnt($$);
#sub elem($$);
#sub add_prefix($$);
#sub foreach($$);
#sub clone($);
#sub add_set($$);
#sub remove_set($$);
#sub filter($$);
#sub TEST($);

#__DATA__

sub insert($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Noset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	$self->SUPER::insert($self->size(),$elem);
}

sub remove($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Noset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->has($elem)) {
		my($size)=$self->size();
		my($index)=$self->get_a($elem);
		if($index!=$size-1) {
			my($last)=$self->get_b($size-1);
			$self->SUPER::remove($size-1,$last);
			$self->SUPER::remove($index,$elem);
			$self->SUPER::insert($index,$last);
		} else {
			$self->SUPER::remove($index,$elem);
		}
	}
}

sub has($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Noset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	return($self->has_b($elem));
}

sub hasnt($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Noset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	return(!$self->has($elem));
}

sub check_has($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Noset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->hasnt($elem)) {
		throw Meta::Error::Simple("elem [".$elem."] is not an element");
	}
}

sub check_hasnt($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Noset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->has($elem)) {
		throw Meta::Error::Simple("elem [".$elem."] is an element");
	}
}

sub elem($$) {
	my($self,$index)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Noset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	return($self->get_b($index));
}

sub add_prefix($$) {
	my($self,$prefix)=@_;
	my($ret)=ref($self)->new();
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		$ret->insert($prefix.$curr);
	}
	return($ret);
}

sub foreach($$) {
	my($self,$code)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		&$code($curr);
	}
}

sub clone($) {
	my($self)=@_;
	my($ret)=ref($self)->new();
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		$ret->insert($curr);
	}
	return($ret);
}

sub add_set($$) {
	my($self,$set)=@_;
	for(my($i)=0;$i<$set->size();$i++) {
		my($curr)=$set->elem($i);
		$self->insert($curr);
	}
}

sub remove_set($$) {
	my($self,$set)=@_;
	for(my($i)=0;$i<$set->size();$i++) {
		my($curr)=$set->elem($i);
		$self->remove($curr);
	}
}

sub filter($$) {
	my($self,$code)=@_;
	my($ret)=ref($self)->new();
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		if(&$code($curr)) {
			$ret->insert($curr);
		}
	}
	return($ret);
}

sub filter_regexp($$) {
	my($self,$re)=@_;
	my($ret)=ref($self)->new();
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		if($curr=~/$re/) {
			$ret->insert($curr);
		}
	}
	return($ret);
}

sub filter_content($$) {
	my($self,$re)=@_;
	my($ret)=ref($self)->new();
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		if(Meta::Utils::File::File::check_sing_regexp($curr,$re,1)) {
			$ret->insert($curr);
		}
	}
	return($ret);
}

sub TEST($) {
	my($context)=@_;
	my($set)=__PACKAGE__->new();
	$set->insert("el2");
	$set->insert("el1");
	$set->insert("el3");
	Meta::Utils::Output::dump($set);
	$set->remove("el2");
	Meta::Utils::Output::dump($set);
	#$set->sort();
	#Meta::Utils::Output::dump($set);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Noset - Ordered hash data structure.

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

	MANIFEST: Noset.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Noset qw();
	my($oset)=Meta::Ds::Noset->new();
	$oset->insert("mark");

=head1 DESCRIPTION

This is a set object which is also ordered (meaning you can find
the ordinal number of each element and also the reverse - move from
an ordinal number to the element). The structure is able to hold
any perl object or scalar as element. Duplicates are not allowed (this
is a set after all...). The structure uses a 1-1 mapping to do its
thing by mapping numbers to the elements that you put in. This means
that you can iterate over all elements of the set quite easily with
little performance penalty (except the hash function lookup every
loop). The set also supports the remove operation by changing
the ordinal of the last element to the element which is removed. This
means that removing elements while traversing the ordinals is not
supported. The removal is, however, O(1). All other standard operations
are O(1).

The methods which just work out of the box from the parent class are:
0. clear - clears the data structure.

=head1 FUNCTIONS

	insert($$)
	remove($$)
	has($$)
	hasnt($$)
	check_has($$)
	check_hasnt($$)
	elem($$)
	add_prefix($$)
	foreach($$)
	clone($)
	add_set($$);
	remove_set($$);
	filter($$);
	filter_regexp($$);
	filter_content($$);
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<insert($$)>

This inserts a new element into the Set.
If the element is already an element it is not an error.

=item B<remove($$)>

This removes an element from the Set.
If the element is not an element of the set it is not an error.

=item B<has($$)>

This returns whether a specific element is a member of the set.

=item B<hasnt($$)>

This returns whether a specific element is not a member of the set.

=item B<check_has($$)>

Thie method receives:
0. An Noset object.
1. An element to check fore.
This method makes sure that the element is a member of the set and
dies if it is not.

=item B<check_hasnt($$)>

Thie method receives:
0. An Noset object.
1. An element to check fore.
This method makes sure that the element is a member of the set and
dies if it is not.

=item B<elem($$)>

This method receives:
0. An Noset object.
1. A location.
And retrieves the element at that location.

=item B<add_prefix($$)>

This method receives:
0. An Noset object.
1. A prefix.
It returns a new set which has all the elements in the old with the specified prefix.

=item B<foreach($$)>

This method receives:
0. An Noset object.
1. A code reference.
The method will iterate through the container and call the code on each element. The code
reference should receive a single argument which is the current element.

=item B<clone($)>

This method receives:
0. An Noset object.
This method will return a clone of the current data structure.

=item B<add_set($$)>

This method receives:
0. An Noset object.
1. Another set object.
The method will add all the elements in the recieved set to the current set.

=item B<remove_set($$)>

This method receives:
0. An Noset object.
1. Another set object.
The method will remove all the elements in the recieved set from the current set.

=item B<filter($$)>

This method receives:
0. An Noset object.
1. A code reference.
The method will return a new set which will have all the elements for which the code
evaluated to true.

=item B<filter_regexp($$)>

This method receives:
0. An Noset object.
1. A regular expression.
The method will return a new set which will have all the elements which matched the
regular expression.

=item B<filter_content($$)>

This method receives:
0. An Noset object.
1. A regular expression.
The method will return a new set which will have all the elements for which the
content as files matched the regular expression.

=item B<TEST($)>

Test suite for this module.

Currently creates a set and manipulates it a little.

=back

=head1 SUPER CLASSES

Meta::Ds::Map(3)

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

Meta::Ds::Map(3), Meta::Utils::File::File(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-add a sort operation.
