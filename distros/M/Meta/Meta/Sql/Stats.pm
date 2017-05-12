#!/bin/echo This is a perl module and should not be run

package Meta::Sql::Stats;

use strict qw(vars refs subs);
use Meta::Ds::Array qw();

our($VERSION,@ISA);
$VERSION="0.18";
@ISA=qw(Meta::Ds::Array);

#sub execute($$);
#sub check($);
#sub TEST($);

#__DATA__

sub execute($$) {
	my($self,$connection)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		$self->elem($i)->execute($connection);
	}
}

sub check($) {
	my($self)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		$self->elem($i)->check();
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Sql::Stats - a module which encapsulates a set of SQL statements.

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

	MANIFEST: Stats.pm
	PROJECT: meta
	VERSION: 0.18

=head1 SYNOPSIS

	package foo;
	use Meta::Sql::Stats qw();
	my($object)=Meta::Sql::Stats->new();
	my($result)=$object->execute([params]);

=head1 DESCRIPTION

This is a collection of SQL statements. It is basically a container that
you can add statements too.
The container lets you do things like exeucte all the statements etc...

=head1 FUNCTIONS

	execute($$)
	check($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<execute($$)>

This method will execute all statements in this collection.
The method receives a Dbi reference as a second argument.

=item B<check($)>

This method will check all statements in this collection.
The method receives only the statements object.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Ds::Array(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV get graph stuff going
	0.01 MV more perl quality
	0.02 MV perl qulity code
	0.03 MV more perl code quality
	0.04 MV revision change
	0.05 MV languages.pl test online
	0.06 MV db stuff
	0.07 MV perl packaging
	0.08 MV fix database problems
	0.09 MV md5 project
	0.10 MV database
	0.11 MV perl module versions in files
	0.12 MV movies and small fixes
	0.13 MV thumbnail user interface
	0.14 MV more thumbnail issues
	0.15 MV website construction
	0.16 MV web site automation
	0.17 MV SEE ALSO section fix
	0.18 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Array(3), strict(3)

=head1 TODO

Nothing.
