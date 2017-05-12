#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::BuildInfo;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.13";
@ISA=qw();

#sub BEGIN();
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_srcx",
		-java=>"_modu",
		-java=>"_targ",
		-java=>"_path",
	);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::BuildInfo - object to store information needed to build a target.

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

	MANIFEST: BuildInfo.pm
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::BuildInfo qw();
	my($object)=Meta::Pdmt::BuildInfo->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This object is the one which is passed to Pdmt nodes to build stuff.

=head1 FUNCTIONS

	BEGIN()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method will set the accessors for the following attributes:
1. "srcx" - source file path.
2. "modu" - module name used to access the module.
3. "targ" - target of the build.
4. "path" - ??.

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

	0.00 MV BuildInfo object change
	0.01 MV PDMT
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV more thumbnail stuff
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site development
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), strict(3)

=head1 TODO

-add multiple sources for build.

-add service to give only new files for the target.

-support multiple build targets.
