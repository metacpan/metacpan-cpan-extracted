#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Oset;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Meta::Ds::Array qw();
use Meta::Types::String qw();
use Meta::Utils::Output qw();
use Meta::Utils::String qw();
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.33";
@ISA=qw();

#sub BEGIN();
#sub new($);
#sub clear($);
#sub insert($$);
#sub remove($$);
#sub has($$);
#sub hasnt($$);
#sub check_has($$);
#sub check_hasnt($$);
#sub size($);
#sub elem($$);
#sub sort($$);
#sub filter($$);
#sub clone($);
#sub add_set($$);
#sub remove_set($$);
#sub foreach($$);
#sub add_prefix($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_description",
		-java=>"_default",
	);
}

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	$self->{HASH}={};
	$self->{LIST}=Meta::Ds::Array->new();
	return($self);
}

sub clear($) {
	my($self)=@_;
	my($hash)=$self->{HASH};
	while(my($key,$val)=each(%$hash)) {
		$self->remove($key);
	}
	$self->{LIST}=Meta::Ds::Array->new();
}

sub insert($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Oset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->hasnt($elem)) {
		my($hash)=$self->{HASH};
		$hash->{$elem}=defined;
		my($list)=$self->{LIST};
		$list->push($elem);
	}
}

sub remove($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Oset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->has($elem)) {
		my($hash)=$self->{HASH};
		$hash->{$elem}=undef;#remove the element
		my($list)=$self->{LIST};
		$list->remove_first($elem);
	}
}

sub has($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Oset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	my($hash)=$self->{HASH};
	if(exists($hash->{$elem})) {
		return(1);
	} else {
		return(0);
	}
}

sub hasnt($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Oset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	my($hash)=$self->{HASH};
	if(exists($hash->{$elem})) {
		return(0);
	} else {
		return(1);
	}
}

sub check_has($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Oset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->hasnt($elem)) {
		throw Meta::Error::Simple("elem [".$elem."] is not an element");
	}
}

sub check_hasnt($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Oset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->has($elem)) {
		throw Meta::Error::Simple("elem [".$elem."] is an element");
	}
}

sub size($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Oset");
	return($self->{LIST}->size());
}

sub elem($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Oset");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	return($self->{LIST}->getx($elem));
}

sub sort($$) {
	my($self,$ref)=@_;
	$self->{LIST}->sort($ref);
}

sub filter($$) {
	my($self,$code)=@_;
	# next line clones the input type
	my($ret)=ref($self)->new();
	my($hash)=$self->{HASH};
	while(my($key,$val)=each(%$hash)) {
		if(&$code($key)) {
			$ret->insert($key);
		}
	}
	return($ret);
}

sub clone($) {
	my($self)=@_;
	my($ret)=ref($self)->new();
	my($hash)=$self->{HASH};
	while(my($key,$val)=each(%$hash)) {
		$ret->insert($key);
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

sub foreach($$) {
	my($self,$code)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		&$code($curr);
	}
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

sub TEST($) {
	my($context)=@_;
	my($setx)=__PACKAGE__->new();
	my($string_mark)=Meta::Types::String->new_stri("mark");
	my($string_velt)=Meta::Types::String->new_stri("velt");
	my($string_abra)=Meta::Types::String->new_stri("abra");
	$setx->insert($string_mark);
	$setx->insert($string_velt);
	$setx->insert($string_abra);
	$setx->sort(\&Meta::Types::String::cmp);
	Meta::Utils::Output::dump($setx);

	my($setx)=Meta::Ds::Oset->new();
	$setx->insert("mark");
	$setx->insert("velt");
	$setx->insert("abra");
	$setx->sort(\&Meta::Utils::String::compare);
	Meta::Utils::Output::dump($setx);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Oset - Ordered hash data structure.

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

	MANIFEST: Oset.pm
	PROJECT: meta
	VERSION: 0.33

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Oset qw();
	my($oset)=Meta::Ds::Oset->new();
	$oset->insert("mark");

=head1 DESCRIPTION

This is a set object which is also ordered. This means you can access the
n'th element. You get performance penalties in this implementation (especially
upon removal of elements) so if you dont need the ordered feature please use
the Meta::Ds::Set class.

=head1 FUNCTIONS

	BEGIN()
	new($)
	clear($)
	insert($$)
	remove($$)
	has($$)
	hasnt($$)
	check_has($$)
	check_hasnt($$)
	size($)
	elem($$)
	sort($$)
	filter($$)
	clone($)
	add_set($$)
	remove_set($$)
	foreach($$)
	add_prefix($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method for "name", "description" and "default" atrributes.

=item B<new($)>

Gives you a new Oset object.

=item B<clear($)>

Clears out the set so that it is empty.

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
0. An Oset object.
1. An element to check fore.
This method makes sure that the element is a member of the set and
dies if it is not.

=item B<check_hasnt($$)>

Thie method receives:
0. An Oset object.
1. An element to check fore.
This method makes sure that the element is a member of the set and
dies if it is not.

=item B<size($)>

This method returns the size of the set.

=item B<elem($$)>

This method receives:
0. An Oset object.
1. A location.
And retrieves the element at that location.

=item B<sort($$)>

This method receives:
0. An Oset object.
1. A comparison function.
And sorts the set according to the comparison function.

=item B<filter($$)>

This method receives:
0. An Oset object.
1. A code reference.
The method will run the code reference on each element of the
set and will return a new set which only has the elements for
which the code reference returned a value which evaluated to
true.

=item B<clone($)>

This metho clones the current object.

=item B<add_set($$)>

This method will add a set to the current set.

=item B<remove_set($$)>

This method will remove a set from the current set.

=item B<foreach($$)>

This method will run a piece of code given to it on every element in the set.

=item B<add_prefix($$)>

This method creates and returns a new set which has all the elements of the old
set with some prefix added.

=item B<TEST($)>

Test suite for this module.
currently it just constructs a Oset object and prints it out.

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

	0.00 MV add enumerated types to options
	0.01 MV more on tests/more checks to perl
	0.02 MV fix all tests change
	0.03 MV change new methods to have prototypes
	0.04 MV UI for Opts.pm
	0.05 MV perl code quality
	0.06 MV more perl quality
	0.07 MV more perl quality
	0.08 MV get basic Simul up and running
	0.09 MV perl documentation
	0.10 MV more perl quality
	0.11 MV perl qulity code
	0.12 MV more perl code quality
	0.13 MV revision change
	0.14 MV better general cook schemes
	0.15 MV languages.pl test online
	0.16 MV PDMT/SWIG support
	0.17 MV Pdmt stuff
	0.18 MV perl packaging
	0.19 MV PDMT
	0.20 MV md5 project
	0.21 MV database
	0.22 MV perl module versions in files
	0.23 MV movies and small fixes
	0.24 MV more thumbnail code
	0.25 MV thumbnail user interface
	0.26 MV more thumbnail issues
	0.27 MV website construction
	0.28 MV web site automation
	0.29 MV SEE ALSO section fix
	0.30 MV download scripts
	0.31 MV finish papers
	0.32 MV more pdmt stuff
	0.33 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Ds::Array(3), Meta::Error::Simple(3), Meta::Types::String(3), Meta::Utils::Output(3), Meta::Utils::String(3), strict(3)

=head1 TODO

-implement this as a two way map and get much better performance. The sort method may have difficulties.
