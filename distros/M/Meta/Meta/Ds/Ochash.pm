#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Ochash;

use strict qw(vars refs subs);
use Meta::Ds::Hash qw();

our($VERSION,@ISA);
$VERSION="0.15";
@ISA=qw(Meta::Ds::Hash);

#sub new($);
#sub insert($$$);
#sub remove($$);
#sub elem($$);
#sub key($$);
#sub val($$);
#sub print($$);
#sub get_elem_number($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Ds::Hash->new();
	bless($self,$class);
	$self->{KEYX}=[];
	$self->{VALX}=[];
	$self->{OHASH}={};
	return($self);
}

sub insert($$$) {
	my($self,$key,$val)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Ochash");
	if($self->Meta::Ds::Hash::insert($key,$val)) {
		my($list)=$self->{KEYX};
		my($num1)=push(@$list,$key);
		my($tsil)=$self->{VALX};
		my($num2)=push(@$tsil,$val);
		$val->set_container($self);
		my($numb)=$num1-1;#arbitrary
		$self->{OHASH}->{$key}=$numb;
		return(1);
	} else {
		return(0);
	}
}

sub remove($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Ochash");
	if($self->remove($elem)) {
		# FIXME
		# remove it from the list.
		return(1);
	} else {
		return(0);
	}
}

sub elem($$) {
	my($self,$elem)=@_;
	return($self->{VALX}->[$elem]);
}

sub key($$) {
	my($self,$elem)=@_;
	return($self->{KEYX}->[$elem]);
}

sub val($$) {
	my($self,$elem)=@_;
	return($self->{VALX}->[$elem]);
}

sub print($$) {
	my($self,$file)=@_;
	my($list)=$self->{LIST};
	my($size)=$self->size();
	for(my($i)=0;$i<$size;$i++) {
		my($key)=$self->key($i);
		my($val)=$self->val($i);
		print $file "[".$key."]\n";
		$val->print($file);
	}
}

sub get_elem_number($$) {
	my($self,$elem)=@_;
	return($self->{OHASH}->{$elem});
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Ochash - Ordered hash data structure with parent conectivity.

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

	MANIFEST: Ochash.pm
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Ochash qw();

=head1 DESCRIPTION

This is an object which is a hash table which can also give you a random
element. Any child must inherit from Meta::Ds::Connected and thus be able
to retrieve its parent.

=head1 FUNCTIONS

	new($)
	insert($$$)
	remove($$)
	elem($$)
	key($$)
	val($$)
	print($$)
	get_elem_number($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

Gives you a new Ochash object.

=item B<insert($$$)>

Inserts an element into the hash.
This just does a Hash insert and updates the list if the hash was actually
inserted.

=item B<remove($$)>

Remove an element from the hash.
This just calls the Meta::Ds::Hash remove and removes the element from the
list if it was successful.

=item B<elem($$)>

This returns a specific element in the hash.

=item B<key($$)>

This returns the key with the specified number.

=item B<val($$)>

This returns the value with the specified number.

=item B<print($$)>

This will print the Ochash object to the specified file for you.

=item B<get_elem_number($$)>

This method will retrieve the sequential number of an element.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Ds::Hash(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV db stuff
	0.01 MV finish db export
	0.02 MV PDMT/SWIG support
	0.03 MV perl packaging
	0.04 MV md5 project
	0.05 MV database
	0.06 MV perl module versions in files
	0.07 MV movies and small fixes
	0.08 MV graph visualization
	0.09 MV more thumbnail stuff
	0.10 MV thumbnail user interface
	0.11 MV more thumbnail issues
	0.12 MV website construction
	0.13 MV web site automation
	0.14 MV SEE ALSO section fix
	0.15 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Hash(3), strict(3)

=head1 TODO

-add/subtract a hash.

-read/write a hash from a file.

-get a list from a hash.

-get a set from a hash.

-get a hash from a list.

-get a hash from a set.

-insert an element and make sure that he wasnt there.

-remove an element and make sure that he was there.

-add a limitation on the types of objects going into the hash (they must be inheritors from some kind of object).
