#!/bin/echo This is a perl module and should not be run

package Meta::Utils::String;

use strict qw(vars refs subs);
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.10";
@ISA=qw();

#sub compare($$);
#sub lower_case($);
#sub has_space($);
#sub is_alnum_u($);
#sub check_isalnum_u($);
#sub separate($);
#sub blow_to_size($$$);
#sub TEST($);

#__DATA__

sub compare($$) {
	my($a,$b)=@_;
	return($a cmp $b);
}

sub lower_case($) {
	my($string)=@_;
	return($string);
}

sub has_space($) {
	my($string)=@_;
	return($string=~/ /);
}

sub is_alnum_u($) {
	my($string)=@_;
	return($string=~/^[a-b0-9_]*$/);
}

sub check_alnum_u($) {
	my($string)=@_;
	if(!is_alnum_u($string)) {
		throw Meta::Error::Simple("string [".$string."] is not alpha numeric with underscores");
	}
}

sub separate($) {
	my($string)=@_;
	return($string);
}

sub blow_to_size($$$) {
	my($string,$length,$add)=@_;
	while(length($string)<$length) {
		$string.=$add;
	}
	return($string);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::String - string related methods.

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

	MANIFEST: String.pm
	PROJECT: meta
	VERSION: 0.10

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::String qw();
	my($object)=Meta::Utils::String->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module will give you various methods that you may need
for handling strings. It is true that most of those have
equivalent perl builtin operators or functions but these have
different problems:
0. bad names.
1. weird calling conventions (not regular functions).
2. not object oriented.

Methods in this library include:
1. comparison functions.
2. transformation functions.
3. checking string which are filenames for common pitfalls.

=head1 FUNCTIONS

	compare($$)
	lower_case($)
	has_space($)
	is_alnum_u($)
	check_alnum_u($)
	separate($)
	blow_to_size($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<compare($$)>

This method uses the built it cmp functions to compare two strings
and return the result. You can use this function in sorting or just
for regular comparisons.

=item B<lower_case($)>

This method receives a string and returns the lower case version of
the string.

=item B<has_space($)>

This method will return true/false value according to whether the
string received has a space inside it.

=item B<is_alnum_u($)>

This method will return true/false value according to whether the
string received is an alpha numeric string with possible underscores.

=item B<check_alnum_u($)>

This method receives a string and throws an exception if the string
received is not an alpha numeric string with possible underscores.

=item B<separate($)>

This method receives a string in ThisForm and returns it in
this_form.

=item B<blow_to_size($$$)>

This method will add a specfied string to another many times until it
exceeds a certain length.

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

	0.00 MV md5 project
	0.01 MV database
	0.02 MV perl module versions in files
	0.03 MV movies and small fixes
	0.04 MV thumbnail user interface
	0.05 MV more thumbnail issues
	0.06 MV md5 project
	0.07 MV website construction
	0.08 MV web site automation
	0.09 MV SEE ALSO section fix
	0.10 MV md5 issues

=head1 SEE ALSO

Meta::Error::Simple(3), strict(3)

=head1 TODO

Nothing.
