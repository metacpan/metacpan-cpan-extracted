#!/bin/echo This is a perl module and should not be run

package Meta::Db::Function;

use strict qw(vars refs subs);
use Meta::Types::Enumerated qw();
use Meta::Info::Enum qw();

our($VERSION,@ISA);
$VERSION="0.28";
@ISA=qw(Meta::Types::Enumerated);

#sub BEGIN();
#sub get_enum();
#sub TEST($);

#__DATA__

our($enum);

sub BEGIN() {
	$enum=Meta::Info::Enum->new();
	$enum->insert("read");
	$enum->insert("write");
	$enum->insert("update");
	$enum->insert("delete");
	$enum->insert("insert");
	$enum->insert("create_table");
	$enum->insert("drop_table");
	$enum->insert("alter_table");
	$enum->insert("create_database");
	$enum->insert("drop_database");
}

sub get_enum() {
	my($self)=@_;
	return($enum);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Function - Handle basic operations that can be done on a database.

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

	MANIFEST: Function.pm
	PROJECT: meta
	VERSION: 0.28

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Function qw();
	my($is_my_function_a_real_function)=Meta::Db::Function::verify("delete");

=head1 DESCRIPTION

This object handle the opcodes for the basic operations on a database.

=head1 FUNCTIONS

	BEGIN()
	get_enum()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Initialization method for this class. This method creates an enum object with
all the functions which have permissions in a modern RDBMS system.

=item B<get_enum()>

This overriden get_enum function which returns the pre-prepared enumeation
object.

=item B<TEST($)>

Test suite for this object.

=back

=head1 SUPER CLASSES

Meta::Types::Enumerated(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV get the databases to work
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV check that all uses have qw
	0.04 MV fix todo items look in pod documentation
	0.05 MV more on tests/more checks to perl
	0.06 MV perl code quality
	0.07 MV more perl quality
	0.08 MV more perl quality
	0.09 MV perl documentation
	0.10 MV more perl quality
	0.11 MV perl qulity code
	0.12 MV more perl code quality
	0.13 MV revision change
	0.14 MV languages.pl test online
	0.15 MV perl packaging
	0.16 MV some chess work
	0.17 MV md5 project
	0.18 MV database
	0.19 MV perl module versions in files
	0.20 MV movies and small fixes
	0.21 MV more thumbnail code
	0.22 MV thumbnail user interface
	0.23 MV more thumbnail issues
	0.24 MV website construction
	0.25 MV web site automation
	0.26 MV SEE ALSO section fix
	0.27 MV teachers project
	0.28 MV md5 issues

=head1 SEE ALSO

Meta::Info::Enum(3), Meta::Types::Enumerated(3), strict(3)

=head1 TODO

-make subsets of functions which could be referred to ?
