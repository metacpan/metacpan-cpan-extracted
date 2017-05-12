#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Stack;

use strict qw(vars refs subs);
use Meta::Ds::Set qw();
use Meta::Utils::Arg qw();
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.36";
@ISA=qw();

#sub new($);

#sub top($);
#sub push($$);
#sub push_set($$);
#sub pop($);

#sub size($);

#sub empty($);
#sub notempty($);

#sub join($$);

#sub foreach($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	$self->{NUMB}=0;
	$self->{ARRA}=[];
	return($self);
}

sub top($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Stack");
	my($coun)=$self->size();
	if($coun>0) {
		my($arra)=$self->{ARRA};
		return($$arra[$#$arra]);
	} else {
		throw Meta::Error::Simple("no elements in the stack for top operation");
		return(-1);
	}
}

sub push($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Stack");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	my($arra)=$self->{ARRA};
	push(@$arra,$elem);
	$self->{NUMB}++;
}

sub push_set($$) {
	my($self,$setx)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Stack");
#	Meta::Utils::Arg::check_arg($setx,"Meta::Ds::Set");
	$setx->reset();
	while(!$setx->over()) {
		$self->push($setx->curr());
		$setx->next();
	}
}

sub pop($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Stack");
	my($coun)=$self->size();
	if($coun>0) {
		my($arra)=$self->{ARRA};
		return(pop(@$arra));
	} else {
		throw Meta::Error::Simple("no more elements to pop in stack");
		return(-1);
	}
}

sub size($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Stack");
	my($arra)=$self->{ARRA};
	return($#$arra+1);
}

sub empty($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Stack");
	return($self->size()==0);
}

sub notempty($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Stack");
	return($self->size()>0);
}

sub join($$) {
	my($self,$string)=@_;
	my($array)=$self->{ARRA};
	return(CORE::join($string,@$array));
}

sub foreach($$) {
	my($self,$code)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Stack");
#	Meta::Utils::Arg::check_arg($file,"ANY");
	my($coun)=$self->size();
	my($arra)=$self->{ARRA};
	for(my($i)=0;$i<$coun;$i++) {
		my($curr)=$arra->[$i];
		&$code($curr);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Stack - data structure that represents a stack.

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

	MANIFEST: Stack.pm
	PROJECT: meta
	VERSION: 0.36

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Stack qw();
	my($stack)=Meta::Ds::Stack->new();
	$stack->push("mark");
	my($poped)=$stack->pop();

=head1 DESCRIPTION

This is a library to let you create a stack like data structure.
The internal representation is that of an array.
Why should you want this ?
Well - its not very nice to write $#$stack when you want the size of the
stack... This is mainly a OO wraper for a stack...

The current array implementation is not very good and should be replaced
with a better 1-1 mapping with minimum and maximum and that way pushing
and poping on either side would be very efficient. Also iteration on
the elements would be possible. The transformation is left as an exercise
to the reader (just kidding).

=head1 FUNCTIONS

	new($)
	top($)
	push($$)
	push_set($$)
	pop($)
	size($)
	empty($)
	notempty($)
	join($$)
	foreach($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

Gives you a new Stack object. The input is the type of the class.

=item B<top($)>

Gives you the element at the top of the stack.

=item B<push($$)>

Pushes an item onto the stack.

=item B<push_set($$)>

Pushes a whole set onto the stack.

=item B<pop($)>

Pops an element off the stack.
Return the element poped and dies if there is no element to pop.

=item B<size($)>

Returns the size of the stack.

=item B<empty($)>

Tell me if the stack is empty or not.

=item B<notempty($)>

Tell me if the stack is notempty or not.

=item B<join($$)>

This method will return the result of join on the elements of the stack.

=item B<foreach($$)>

This method will iterate over all elements of the stack and will run a subroutine
supplied to it on them. The subroutine should only accept a single argument
which is the current element. Currently no guarantees on the order of traversal
of the elements is given.

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

	0.00 MV initial code brought in
	0.01 MV bring databases on line
	0.02 MV ok. This is for real
	0.03 MV make quality checks on perl code
	0.04 MV more perl checks
	0.05 MV make Meta::Utils::Opts object oriented
	0.06 MV check that all uses have qw
	0.07 MV fix todo items look in pod documentation
	0.08 MV more on tests/more checks to perl
	0.09 MV correct die usage
	0.10 MV perl code quality
	0.11 MV more perl quality
	0.12 MV more perl quality
	0.13 MV perl documentation
	0.14 MV more perl quality
	0.15 MV perl qulity code
	0.16 MV more perl code quality
	0.17 MV more perl quality
	0.18 MV revision change
	0.19 MV languages.pl test online
	0.20 MV PDMT/SWIG support
	0.21 MV perl packaging
	0.22 MV more perl packaging
	0.23 MV md5 project
	0.24 MV database
	0.25 MV perl module versions in files
	0.26 MV movies and small fixes
	0.27 MV movie stuff
	0.28 MV more thumbnail code
	0.29 MV thumbnail user interface
	0.30 MV more thumbnail issues
	0.31 MV website construction
	0.32 MV web site automation
	0.33 MV SEE ALSO section fix
	0.34 MV move tests to modules
	0.35 MV more pdmt stuff
	0.36 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Set(3), Meta::Error::Simple(3), Meta::Utils::Arg(3), strict(3)

=head1 TODO

-make a method to empty the stack.
