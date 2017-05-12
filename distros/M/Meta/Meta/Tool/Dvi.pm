#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Dvi;

use strict qw(vars refs subs);
use Meta::Utils::System qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw();

#sub chec($);
#sub c2psxx($);
#sub TEST($);

#__DATA__

sub chec($) {
	my($buil)=@_;
	return(1);
}

sub c2psxx($) {
	my($buil)=@_;
	return(Meta::Utils::System::system_err_silent_nodie("dvips",["-o",$buil->get_targ(),$buil->get_srcx()]));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Dvi - this module will help you deal with dvi files.

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

	MANIFEST: Dvi.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Dvi qw();
	my($object)=Meta::Tool::Dvi->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module helps you deal with DVI: Device Independant graphics format.
It can:
0. Check that a certain DVI file is correct.
1. Convert the DVI file to postscript format.

=head1 FUNCTIONS

	chec($)
	c2psxx($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<chec($)>

This method will check a DVI file given to it for validity.
Currently it uses the dvitype utility from the tetex package to do this.

=item B<c2psxx($)>

This method will convert a DVI file given to it to Postscript format.

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

	0.00 MV spelling and papers
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

Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
