#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Symlink;

use strict qw(vars refs subs);
use Meta::Utils::File::Copy qw();
use File::Find qw();
use Meta::Utils::Output qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.28";
@ISA=qw();

#sub is_symlink($);
#sub check_symlink($);
#sub check_valid_symlink($);
#sub check_doit();
#sub check($$);
#sub replace_doit();
#sub replace($$$);
#sub symlink($$);
#sub link($$);
#sub TEST($);

#__DATA__

sub is_symlink($) {
	my($file)=@_;
	if(-l $file) {
		return(1);
	} else {
		return(0);
	}
}

sub check_symlink($) {
	my($file)=@_;
	if(!is_symlink($file)) {
		throw Meta::Error::Simple("file [".$file."] is not a symlink");
	}
}

sub check_valid_symlink($) {
	my($file)=@_;
	check_symlink($file);
	my($real)=CORE::readlink($file);
	if(!-e $real) {
		throw Meta::Error::Simple("cant readlink [".$real."]");
	}
}

sub check_doit($) {
	my($curr)=@_;
	my($full)=$File::Find::name;
	my($dire)=$File::Find::dir;
	my($verb)=0;
	if(-l $curr) {
		Meta::Utils::Output::verbose($verb,"checking [".$full."]\n");
		my($read)=CORE::readlink($curr);
		if(!$read) {
			throw Meta::Error::Simple("cant readlink [".$full."]");
		}
		if(!-e $read) {
			throw Meta::Error::Simple("test failed for [".$full."]\n");
		}
	}
}

sub check($$) {
	my($dire,$verb)=@_;
	File::Find::finddepth(\&check_doit,$dire);
}

sub replace_doit() {
	my($curr)=@_;
	my($full)=$File::Find::name;
	my($dire)=$File::Find::dir;
	my($verb)=0;
	my($demo)=0;
	if(-l $curr) {
		Meta::Utils::Output::verbose($verb,"replacing [".$full."]\n");
		if(!$demo) {
			my($read)=CORE::readlink($curr);
			if($read) {
				Meta::Utils::File::Copy::copy_unlink($read,$curr);
			} else {
				throw Meta::Error::Simple("unable to replace symlink [".$full."]");
			}
		}
	}
}

sub replace($$$) {
	my($dire,$demo,$verb)=@_;
	File::Find::finddepth(\&replace_doit,$dire);
}

sub symlink($$) {
	my($oldx,$newx)=@_;
	if(!CORE::symlink($oldx,$newx)) {
		throw Meta::Error::Simple("unable to create symlink from [".$oldx."] to [".$newx."]");
	}
}

sub link($$) {
	my($oldx,$newx)=@_;
	if(!CORE::link($oldx,$newx)) {
		throw Meta::Error::Simple("unable to create link from [".$oldx."] to [".$newx."]");
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Symlink - module to help you deal with symbolic links.

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

	MANIFEST: Symlink.pm
	PROJECT: meta
	VERSION: 0.28

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Symlink qw();
	my($directory)="~/data";
	my($verbose)=1;
	Meta::Utils::File::Symlink::check($directory,$verbose);

=head1 DESCRIPTION

This library helps you with handling symbolic links.
It has easy to use function to tell you if a file is a symbolic link,
find out if a symbolic link is pointing at a valid file and the like.

There are two higher level services that this library provides:
1. scan directories in recursive fashion to check that all symlinks in
	those directories are valid.
2. scan directories in recursive fashion to replace all symlinks with the
	files they are pointing at.
This module uses File::Find extensivly.

=head1 FUNCTIONS

	is_symlink($)
	check_symlink($)
	check_valid_symlink($)
	check_doit($)
	check($$)
	replace_doit()
	replace($$$)
	symlink($$)
	link($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<is_symlink($)>

This function will return true iff the file given to it is a symlink.

=item B<check_symlink($)>

This function will check that a file given to it is a symlink. If it
is not it will throw an exception.

=item B<check_valid_symlink($)>

This function will check that a file given to it is a symlink and also
points to a valid file. If there is an error it will throw an exception.

=item B<check_doit($)>

This function checks if the file she gets is a symlink and if so verifies
the fact that is is ok.

=item B<check($$)>

This function receives a directory and scans it using File::Find and
fills up a hash with all the files found there.
The routine also receives a verbose parameter.
The routine returns nothing.

=item B<replace_doit()>

This function checks if the file she gets is a symlink and if so removes
it and replaces it with the content of the file it is pointing at.

=item B<replace($$$)>

This function receives a directory and scans it using File::Find and
fills up a hash with all the files found there.
The routine also receives a demo parameter.
The routine also receives a verbose parameter.
The routine returns nothing.

=item B<symlink($$)>

Create a symbolic link.

=item B<link($$)>

Create a hard link.

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
	0.06 MV more on tests/more checks to perl
	0.07 MV spelling change
	0.08 MV correct die usage
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
	0.19 MV md5 project
	0.20 MV database
	0.21 MV perl module versions in files
	0.22 MV movies and small fixes
	0.23 MV thumbnail user interface
	0.24 MV more thumbnail issues
	0.25 MV website construction
	0.26 MV web site automation
	0.27 MV SEE ALSO section fix
	0.28 MV md5 issues

=head1 SEE ALSO

Error(3), File::Find(3), Meta::Utils::File::Copy(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-do we need to export the "_doit" routines ? No!!!
