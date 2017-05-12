#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Time;

use strict qw(vars refs subs);
use File::stat qw();

our($VERSION,@ISA);
$VERSION="0.13";
@ISA=qw();

#sub time($);
#sub mtime($);
#sub TEST($);

#__DATA__

sub time($) {
	my($file)=@_;
	my($st)=File::stat::stat($file);
	return($st->mtime());
}

sub mtime($) {
	my($file)=@_;
	my($st)=File::stat::stat($file);
	if(!defined($st)) {
		return(0);
	} else {
		return($st->mtime());
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Time - library to help you with file time stamps.

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

	MANIFEST: Time.pm
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Time qw();
	my($ok)=Meta::Utils::File::Time::now($file1);

=head1 DESCRIPTION

This module eases the case for getting and setting file modification times.

=head1 FUNCTIONS

	time($)
	mtime($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<time($)>

This routine receives:
0. file - file for which the modification time is required.
The routine then proceeds to use the stat function to find
the files modification time and returns it.

=item B<mtime($)>

This function receives:
0. file - file for which the modification time is required.
This method proceeds to use the File::stat module to get
the info for this file and get the modification time for
the file. If the file does not exist the method returns 0
(very old file 1/1/1970).

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

	0.00 MV html site update
	0.01 MV perl packaging
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV bring movie data
	0.12 MV teachers project
	0.13 MV md5 issues

=head1 SEE ALSO

File::stat(3), strict(3)

=head1 TODO

Nothing.
