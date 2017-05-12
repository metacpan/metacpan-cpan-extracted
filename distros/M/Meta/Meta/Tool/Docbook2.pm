#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Docbook2;

use strict qw(vars refs subs);
use Meta::Baseline::Utils qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw();

#sub c2manx($);
#sub TEST($);

#__DATA__

sub c2manx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Docbook2 - run docbook2 tool.

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

	MANIFEST: Docbook2.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Docbook2 qw();
	my($object)=Meta::Tool::Docbook2->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This job will make it easier to run the Docbook2 type tool.

=head1 FUNCTIONS

	c2manx($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2manx($)>

This routine will convert sgml DocBook files to manual page format.

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

	0.00 MV fix docbook and other various stuff
	0.01 MV perl packaging
	0.02 MV BuildInfo object change
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Utils(3), strict(3)

=head1 TODO

Nothing.
