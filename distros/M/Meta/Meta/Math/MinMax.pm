#!/bin/echo This is a perl module and should not be run

package Meta::Math::MinMax;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.08";
@ISA=qw();

#sub BEGIN();
#sub add($$);
#sub reset($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_min",
		-java=>"_max",
	);
}

sub add($$) {
	my($self,$value)=@_;
	my($min)=$self->get_min();
	if(defined($min)) {
		if($min>$value) {
			$self->set_min($value);
		}
	} else {
		$self->set_min($value);
	}
	my($max)=$self->get_max();
	if(defined($max)) {
		if($max<$value) {
			$self->set_max($value);
		}
	} else {
		$self->set_max($value);
	}
}

sub reset($) {
	my($self)=@_;
	$self->set_min(undef);
	$self->set_max(undef);
}

sub TEST($) {
	my($context)=@_;
	my($object)=Meta::Math::MinMax->new();
	$object->add(5);
	$object->add(2);
	$object->add(9);
	if($object->get_min()!=2) {
		return(0);
	}
	if($object->get_max()!=9) {
		return(0);
	}
	return(1);
}

1;

__END__

=head1 NAME

Meta::Math::MinMax - save minimum and maximum values for sets of numbers.

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

	MANIFEST: MinMax.pm
	PROJECT: meta
	VERSION: 0.08

=head1 SYNOPSIS

	package foo;
	use Meta::Math::MinMax qw();
	my($object)=Meta::Math::MinMax->new();
	$object->add(5);
	$object->add(4);
	$object->add(11.5);
	my($min)=$object->get_min();#should be 4
	my($max)=$object->get_max();#should be 11.5

=head1 DESCRIPTION

This is a simple Min/Max collector. Meaning - while you are in some
kind of process, and would like to get some infomation on sets of
numbers you are working with, create an instance of this object, throw
numbers it's way and at the end of your process it will tell you what
the minimum and maximum values were. This saves you the code to do it
in your object.

The memory consumption of this object is quite low since it only
remembers the min and max values.

Another advantage of using this kind of object is that you can supply
yet other objects with the same interface which do other things like
keep the mean value, the variation and other statistics.

If no values are thrown then the get_min and get_max methods will
return "undef".

=head1 FUNCTIONS

	BEGIN()
	add($$)
	reset($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This block sets up the constructor and attribute methods
for this object which are "min" and "max".

=item B<add($$)>

Throws another value into the pot. The minimum and maximum
values get updated accordingly.

=item B<reset($)>

This method will reset the MinMax object so that it could be used
for a new set of numbers.

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

	0.00 MV md5 progress
	0.01 MV thumbnail project basics
	0.02 MV thumbnail user interface
	0.03 MV more thumbnail issues
	0.04 MV website construction
	0.05 MV web site development
	0.06 MV web site automation
	0.07 MV SEE ALSO section fix
	0.08 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), strict(3)

=head1 TODO

-add more things to be save: mean value, variance, sum etc...
