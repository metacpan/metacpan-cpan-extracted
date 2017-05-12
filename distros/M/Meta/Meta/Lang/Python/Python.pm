#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Python::Python;

use strict qw(vars refs subs);

our($VERSION,@ISA);
$VERSION="0.08";
@ISA=qw();

#sub is_bin($);
#sub TEST($);

#__DATA__

sub is_bin($) {
	my($file)=@_;
	return($file=~/^.*\.py$/);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Python::Python - handle Python related tasks in the baseline.

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

	MANIFEST: Python.pm
	PROJECT: meta
	VERSION: 0.08

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Python::Python qw();
	my($object)=Meta::Lang::Python::Python->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module will ease the work with the Python intepreter. It will run
it, run debugging etc... It will also answer questions regarding Python
in the development environment which will be encapsulated in this module.

=head1 FUNCTIONS

	is_bin($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<is_bin($)>

This method gets a single file arguments and returns true iff
the file is a python script (not library mind you).

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

	0.00 MV database
	0.01 MV perl module versions in files
	0.02 MV movies and small fixes
	0.03 MV thumbnail user interface
	0.04 MV more thumbnail issues
	0.05 MV website construction
	0.06 MV web site automation
	0.07 MV SEE ALSO section fix
	0.08 MV md5 issues

=head1 SEE ALSO

strict(3)

=head1 TODO

-add more methods here (is_lib, is_test and much more).
