#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Mkdir;

use strict qw(vars refs subs);
use File::Path qw();
use File::Basename qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.21";
@ISA=qw();

#sub mkdir($);
#sub mkdir_check($);
#sub mkdir_p_check($);
#sub mkdir_p_check_file($);
#sub TEST($);

#__DATA__

sub mkdir($) {
	my($dire)=@_;
	if(!CORE::mkdir($dire)) {
		throw Meta::Error::Simple("unable to create directory [".$dire."] with error [".$!."]");
	}
}

sub mkdir_check($) {
	my($dire)=@_;
	if(!(-d $dire)) {
		&mkdir($dire);
	}
}

sub mkdir_p_check($) {
	my($dire)=@_;
	if(!(-d $dire)) {
		if(!File::Path::mkpath($dire)) {
			throw Meta::Error::Simple("unable to create directory [".$dire."]");
		}
	}
}

sub mkdir_p_check_file($) {
	my($file)=@_;
	my($dire)=File::Basename::dirname($file);
	return(&mkdir_p_check($dire));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Mkdir - library to help you make directories.

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

	MANIFEST: Mkdir.pm
	PROJECT: meta
	VERSION: 0.21

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Mkdir qw();
	Meta::Utils::File::Mkdir::mkdir_check("/local");

=head1 DESCRIPTION

This module takes care of making directories for you.

=head1 FUNCTIONS

	mkdir($)
	mkdir_check($)
	mkdir_p_check($)
	mkdir_p_check_file($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<mkdir($)>

This method will try to create the directory using the built in CORE::mkdir
method and will throw an exception if it fails.

=item B<mkdir_check($)>

This method checks that the directory given to it doesnt exist and then
creates it using the mkdir system call. The routine will throw an exception
if it fails to create the directory.

=item B<mkdir_p_check($)>

This method is exactly like mkdir_check but creates the whole hierarchy
(you can give something like "foo/boo/bar" to it and it will create them
all).

=item B<mkdir_p_check_file($)>

This method is the same as mkdir_p_check except that it receives a file
name instead of a directory name. It extracts the directory from the
name and calls mkdir_p_check. This is a convenience method so that
you won't have to do it yourself.

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

	0.00 MV Java compilation
	0.01 MV perl code quality
	0.02 MV more perl quality
	0.03 MV more perl quality
	0.04 MV perl documentation
	0.05 MV more perl quality
	0.06 MV perl qulity code
	0.07 MV more perl code quality
	0.08 MV revision change
	0.09 MV languages.pl test online
	0.10 MV perl packaging
	0.11 MV md5 project
	0.12 MV database
	0.13 MV perl module versions in files
	0.14 MV movies and small fixes
	0.15 MV thumbnail user interface
	0.16 MV more thumbnail issues
	0.17 MV website construction
	0.18 MV web site automation
	0.19 MV SEE ALSO section fix
	0.20 MV teachers project
	0.21 MV md5 issues

=head1 SEE ALSO

Error(3), File::Basename(3), File::Path(3), strict(3)

=head1 TODO

-add more functions to this module.
