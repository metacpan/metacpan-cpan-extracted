#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Move;

use strict qw(vars refs subs);
use File::Copy qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.32";
@ISA=qw();

#sub mv($$);
#sub mv_noov($$);
#sub TEST($);

#__DATA__

sub mv($$) {
	my($fil1,$fil2)=@_;
	if(!File::Copy::move($fil1,$fil2)) {
		throw Meta::Error::Simple("unable to move [".$fil1."] to [".$fil2."]");
	}
}

sub mv_noov($$) {
	my($fil1,$fil2)=@_;
	if(-f $fil2) {
		throw Meta::Error::Simple("file [".$fil2."] exists");
	}
	mv($fil1,$fil2);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Move - library to help you move files.

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

	MANIFEST: Move.pm
	PROJECT: meta
	VERSION: 0.32

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Move qw();
	Meta::Utils::File::Move::mv($file1,$file2);

=head1 DESCRIPTION

This module eases moving files around. Why should you need this ? You
already have File::Copy (which this module uses). Well - what if you don't
want to overwrite anything ? What if you want to throw an exception in
case the move fails ? What if you don't want to do that in your code ?

=head1 FUNCTIONS

	mv($$)
	mv_noov($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<mv($$)>

This function moves a file to another and dies if it fails.

=item B<mv_noov($$)>

This function moves a file to another and dies if it fails or the target
file already exists.

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
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV make Meta::Utils::Opts object oriented
	0.04 MV check that all uses have qw
	0.05 MV fix todo items look in pod documentation
	0.06 MV introduce docbook into the baseline
	0.07 MV spelling change
	0.08 MV make lilypond work
	0.09 MV correct die usage
	0.10 MV perl code quality
	0.11 MV more perl quality
	0.12 MV more perl quality
	0.13 MV perl documentation
	0.14 MV more perl quality
	0.15 MV perl qulity code
	0.16 MV more perl code quality
	0.17 MV revision change
	0.18 MV languages.pl test online
	0.19 MV multi image viewer
	0.20 MV perl packaging
	0.21 MV md5 project
	0.22 MV database
	0.23 MV perl module versions in files
	0.24 MV movies and small fixes
	0.25 MV thumbnail user interface
	0.26 MV dbman package creation
	0.27 MV more thumbnail issues
	0.28 MV md5 project
	0.29 MV website construction
	0.30 MV web site automation
	0.31 MV SEE ALSO section fix
	0.32 MV md5 issues

=head1 SEE ALSO

Error(3), File::Copy(3), strict(3)

=head1 TODO

-add a method which moves a file to a directory (and optionally makes sure that it is a directory). with overwrite and without.

-add a method that moves a file to a directory and if a file already exists there with that name changes the name until it finds a name for it. (optionally checks if the files are the same and if so does not copy ?!?).
