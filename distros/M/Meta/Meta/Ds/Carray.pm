#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Carray;

use strict qw(vars refs subs);
use Meta::Utils::Arg qw();
use Meta::Utils::Output qw();
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.13";
@ISA=qw();

#sub new($);
#sub push($$);
#sub getx($$);
#sub setx($$$);
#sub remove($$);
#sub remove_first($$);
#sub size($);
#sub print($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	$self->{LIST}=[];
	return($self);
}

sub push($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Carray");
	my($arra)=$self->{LIST};
	CORE::push(@$arra,$elem);
	$elem->set_container($self);
}

sub getx($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Carray");
	my($arra)=$self->{LIST};
	return($arra->[$elem]);
}

sub setx($$$) {
	my($self,$loca,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Carray");
#	Meta::Utils::Arg::check_arg($loca,"ANY");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	my($arra)=$self->{LIST};
	$arra->[$loca]=$elem;
}

sub remove($$) {
	my($self,$loca)=@_;
#	Meta::Utils::Output::print("loca is [".$loca."]\n");
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Carray");
#	Meta::Utils::Arg::check_arg($loca,"ANY");
	my($arra)=$self->{LIST};
	for(my($i)=$loca;$i<$self->size()-1;$i++) {
#		Meta::Utils::Output::print("removing\n");
#		$arra->[$loca]->print(Meta::Utils::Output::get_file());
#		Meta::Utils::Output::print("and putting\n");
#		$arra->[$loca+1]->print(Meta::Utils::Output::get_file());
		$arra->[$loca]=$arra->[$loca+1];
	}
	$#$arra-=1;
}

sub remove_first($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Carray");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	for(my($i)=0;$i<$self->size();$i++) {
		if($self->getx($i) eq $elem) {
			$self->remove($i);
			return;
		}
	}
	throw Meta::Error::Simple("unable to find element [".$elem."]");
}

sub size($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Carray");
	my($arra)=$self->{LIST};
	return($#$arra+1);
}

sub print($$) {
	my($self,$file)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Carray");
#	Meta::Utils::Arg::check_arg($file,"ANY");
	my($arra)=$self->{LIST};
	my($size)=$#$arra+1;
	print $file "size of array is [".$size."]\n";
	for(my($i)=0;$i<$size;$i++) {
		$arra->[$i]->print($file);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Carray - data structure that represents a array table connected.

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

	MANIFEST: Carray.pm
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Carray qw();
	my($array)=Meta::Ds::Carray->new();
	$array->push("mark");
	$array->setx(5,"mark");
	Meta::Utils::Output::print($array->getx(0));
	Meta::Utils::Output::print($array->size()."\n");

=head1 DESCRIPTION

This is a library to let you create an array like data structure.
"Why should I have such a data strcuture ?" you rightly ask...
Perl already supports arrays as built in structures.
But the usage of the perl array is cryptic and non object oriented
(try to inherit from an array..:)
This will give you a clean object.

=head1 FUNCTIONS

	new($)
	push($$)
	getx($$)
	setx($$$)
	remove($$)
	remove_first($$)
	size($)
	print($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

Gives you a new Carray object.

=item B<push($$)>

Inserts an element into the array.
This receives:
0. Carray object.
1. Element to insert.

=item B<getx($$)>

Get an element from a certain location in the array.
This receives:
0. Carray object.
1. Element number to get.
This returns the n'th elemnt from the array.

=item B<setx($$$)>

This receives:
0. Carray object.
1. Location.
2. Element to put.

=item B<remove($$)>

This method receives:
0. Carray object.
1. Location at which to remove an element.
And remove the element at that location.

=item B<remove_first($$)>

This method receives:
0. Carray object.
1. Elemet to remove.
And it removes the first occurance of the element from the array.

=item B<size($$)>

This returs the size of the array.
This receives:
0. Carray object.

=item B<print($$)>

This will print an array of printable objects.

=item B<TEST($)>

Test suite for this module.

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

	0.00 MV db stuff
	0.01 MV PDMT/SWIG support
	0.02 MV perl packaging
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV more thumbnail stuff
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV website construction
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV md5 issues

=head1 SEE ALSO

Meta::Error::Simple(3), Meta::Utils::Arg(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.
