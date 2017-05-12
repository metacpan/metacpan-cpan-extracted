#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Ohash;

use strict qw(vars refs subs);
use Meta::Ds::Hash qw();

our($VERSION,@ISA);
$VERSION="0.36";
@ISA=qw(Meta::Ds::Hash);

#sub new($);
#sub insert($$$);
#sub put($$$);
#sub overwrite($$$);
#sub remove($$);
#sub elem($$);
#sub key($$);
#sub val($$);
#sub get_elem_number($$);
#sub bash($$);
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
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Ohash");
	return($self->SUPER::insert($key,$val));
#	if($self->SUPER::insert($key,$val)) {
#		my($list)=$self->{KEYX};
#		my($num1)=push(@$list,$key);
#		my($tsil)=$self->{VALX};
#		my($num2)=push(@$tsil,$val);
#		my($numb)=$num1-1;#arbitrary
#		$self->{OHASH}->{$key}=$numb;
#		return(1);
#	} else {
#		return(0);
#	}
}

sub put($$$) {
	my($self,$key,$val)=@_;
	$self->SUPER::put($key,$val);
	my($list)=$self->{KEYX};
	my($num1)=push(@$list,$key);
	my($tsil)=$self->{VALX};
	my($num2)=push(@$tsil,$val);
	my($numb)=$num1-1;#arbitrary
	$self->{OHASH}->{$key}=$numb;
}

sub overwrite($$$) {
	my($self,$key,$val)=@_;
	$self->SUPER::overwrite($key,$val);
	my($num)=$self->get_elem_number($key);
	my($tsil)=$self->{VALX};
	$tsil->[$num]=$val;
}

sub remove($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Ohash");
	if($self->SUPER::remove($elem)) {
		my($numb)=$self->{OHASH}->{$elem};
		#now remove the element number $numb from both list and tsil
		#and update ohash accordingly.
		#mind that ->size is already less by 1 because we are after
		#the remove
		my($list)=$self->{KEYX};
		my($tsil)=$self->{VALX};
		for(my($i)=$numb+1;$i<=$self->size();$i++) {
			$list->[$i]=$list->[$i+1];
			$tsil->[$i]=$tsil->[$i+1];
			$self->{OHASH}->{$list->[$i]}--;
		}
		$#$list--;
		$#$tsil--;
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

sub get_elem_number($$) {
	my($self,$elem)=@_;
	return($self->{OHASH}->{$elem});
}

sub bash($$) {
	my($self,$file)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($key)=$self->key($i);
		my($val)=$self->val($i);
		print $file "export \$".$key."=\"".$val."\"\n";
	}
}

sub TEST($) {
	my($context)=@_;
	my($ohash)=__PACKAGE__->new();
	$ohash->insert("mark","veltzer");
	$ohash->insert("linus","torvalds");
	$ohash->bash(Meta::Utils::Output::get_file());
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Ohash - Ordered hash data structure.

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

	MANIFEST: Ohash.pm
	PROJECT: meta
	VERSION: 0.36

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Ohash qw();

=head1 DESCRIPTION

This is an object which is a hash table which can also give you a random
element.

=head1 FUNCTIONS

	new($)
	insert($$$)
	put($$$)
	overwrite($$$)
	remove($$)
	elem($$)
	key($$)
	val($$)
	get_elem_number($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

Gives you a new Ohash object.

=item B<insert($$$)>

Inserts an element into the hash.
This just does a Hash insert and updates the list if the hash was actually
inserted.

=item B<put($$$)>

Overriden put method so that we could do our own accounting. Refer to the SUPER
implementation.

=item B<overwrite($$$)>

Overriden overwrite method so that we could do our own accounting. Refer to the SUPER
implementation.

=item B<remove($$)>

Remove an element from the hash.
This just calls the SUPER remove and removes the element from the
list if it was successful.

=item B<elem($$)>

This returns a specific element in the hash.

=item B<key($$)>

This returns the key with the specified number.

=item B<val($$)>

This returns the value with the specified number.

=item B<get_elem_number($$)>

This method will give you the sequential number of an element in the ordered hash.

=item B<TEST($)>

Test suite for this module.
Currently this tests creates an object, puts some data in it and then writes
it out in bash format.

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

	0.00 MV initial code brought in
	0.01 MV bring databases on line
	0.02 MV ok. This is for real
	0.03 MV make quality checks on perl code
	0.04 MV more perl checks
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV add enumerated types to options
	0.08 MV more on tests/more checks to perl
	0.09 MV fix all tests change
	0.10 MV change new methods to have prototypes
	0.11 MV perl code quality
	0.12 MV more perl quality
	0.13 MV more perl quality
	0.14 MV perl documentation
	0.15 MV more perl quality
	0.16 MV perl qulity code
	0.17 MV more perl code quality
	0.18 MV revision change
	0.19 MV languages.pl test online
	0.20 MV finish db export
	0.21 MV upload system revamp
	0.22 MV PDMT/SWIG support
	0.23 MV perl packaging
	0.24 MV md5 project
	0.25 MV database
	0.26 MV perl module versions in files
	0.27 MV movies and small fixes
	0.28 MV graph visualization
	0.29 MV more thumbnail code
	0.30 MV thumbnail user interface
	0.31 MV more thumbnail issues
	0.32 MV website construction
	0.33 MV web site automation
	0.34 MV SEE ALSO section fix
	0.35 MV move tests to modules
	0.36 MV md5 issues

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
