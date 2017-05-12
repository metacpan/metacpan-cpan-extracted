#!/bin/echo This is a perl module and should not be run

package Meta::Distrib::Machine;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.31";
@ISA=qw();

#sub BEGIN();
#sub print($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_user",
		-java=>"_password",
	);
}

sub print($$) {
	my($self,$file)=@_;
	print $file "name=[".$self->get_name()."]\n";
	print $file "user=[".$self->get_user()."]\n";
	print $file "pass=[".$self->get_password()."]\n";
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Distrib::Machine - Object to store a definition of a machine in the network.

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

	MANIFEST: Machine.pm
	PROJECT: meta
	VERSION: 0.31

=head1 SYNOPSIS

	package foo;
	use Meta::Distrib::Machine qw();
	my($machine)=Meta::Distrib::Machine->new();
	$machine->set_name("moria");
	$machine->set_user("gandalf");
	$machine->set_password("mellon");

=head1 DESCRIPTION

This object will store information about a machine in the network for whom
distribution should work.

=head1 FUNCTIONS

	BEGIN()
	print($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method will set accessors for the following methods:
"name", "user", "pass".

=item B<print($$)>

This will print the current machine stats for you.

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
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV more on tests/more checks to perl
	0.08 MV change new methods to have prototypes
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV perl documentation
	0.13 MV more perl quality
	0.14 MV perl qulity code
	0.15 MV more perl code quality
	0.16 MV revision change
	0.17 MV languages.pl test online
	0.18 MV perl packaging
	0.19 MV PDMT
	0.20 MV md5 project
	0.21 MV database
	0.22 MV perl module versions in files
	0.23 MV movies and small fixes
	0.24 MV more thumbnail stuff
	0.25 MV thumbnail user interface
	0.26 MV more thumbnail issues
	0.27 MV website construction
	0.28 MV web site development
	0.29 MV web site automation
	0.30 MV SEE ALSO section fix
	0.31 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), strict(3)

=head1 TODO

Nothing.
