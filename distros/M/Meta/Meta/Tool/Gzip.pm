#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Gzip;

use strict qw(vars refs subs);
use Meta::Utils::System qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw();

#sub c2gzxx($);
#sub TEST($);

#__DATA__

sub c2gzxx($) {
	my($buil)=@_;
	return(Meta::Utils::System::system_shell_nodie("gzip --stdout ".$buil->get_srcx()." > ".$buil->get_targ()));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Gzip - call gzip for you.

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

	MANIFEST: Gzip.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Gzip qw();
	my($object)=Meta::Tool::Gzip->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class hides the complexity of calling gzip from you.
Currently the implementation calls the command line gzip to do
the work but more advanced implementations will call a module
to do it.

=head1 FUNCTIONS

	c2gzxx($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2gzxx($)>

This method gets a source file and compresses it into the target.
The method returns a success code.
We use the system_shell_nodie function here with the shell as
a mediator because gzip doesnt have a -o flag.

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

	0.00 MV add zipping subsystem
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

-stop using the shell in the gzip execution (waste of resources).

-start using a real compression module (much cheaper in resources).
