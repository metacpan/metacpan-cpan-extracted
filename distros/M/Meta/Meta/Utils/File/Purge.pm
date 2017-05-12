#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Purge;

use strict qw(vars refs subs);
use Meta::Utils::File::Remove qw();
use File::Find qw();

our($VERSION,@ISA);
$VERSION="0.25";
@ISA=qw();

#sub init($$$);
#sub doit();
#sub purge($$$$);
#sub TEST($);

#__DATA__

my($demo,$verb,$done,$erro);

sub init($$$) {
	($demo,$verb,$done)=@_;
	$$done=0;
	$erro=0;
}

sub doit() {
	my($curr)=$File::Find::name;
	my($dirx)=$File::Find::dir;
	if(-d $curr) {
		if(Meta::Utils::File::Dir::empty($curr)) {
			Meta::Utils::File::Remove::rmdir($curr);
			$$done++;
		}
	}
}

sub purge($$$$) {
	my($dire,$demo,$verb,$done)=@_;
	init($demo,$verb,$done);
	File::Find::finddepth(\&doit,$dire);
	return(!$erro);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Purge - utility for recursivly removing empty directories.

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

	MANIFEST: Purge.pm
	PROJECT: meta
	VERSION: 0.25

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Purge qw();
	my($done)=Meta::Utils::File::Purge::purge($my_directory,$demo,$verbose);

=head1 DESCRIPTION

This is a general utility to clean up whole directory trees from empty
dirs which are created in the build process.
This library utilizes the finddepth routine to do the purging, meaning
it scans the directory at hand in the order of children before fathers,
if a directory is empty it removes it and if a father is left empty
after all children were removed it removes the father and so on...

=head1 FUNCTIONS

	init($$$)
	doit()
	purge($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<$demo,$verb,$done,$erro>

These routines hold the data for the entire process.
demo is whether the run is a dry run.
verb is whether we should be verbose or not.
done is whether we have anything so far.
erro is whether there was an error so far.

=item B<init($$$)>

This function starts up all the vars in the purge process.
This is an internal routine and you should not call it directly.

=item B<doit()>

This function actually does the purging.
This is an internal routine and you should not call it directly.

=item B<purge($$$$)>

This function purges a directory tree meaning removes all sub directories
which are empty in recursion (meaning that directories which had only
empty dirs in them will be removed etc.. etc.. etc..).
The inputs are a directory name, demo boolean that controls whether the
dirs are actually removed or not, and a verbose flag.
The routine also receives a pointer of where to store the number
of directories actually removed.

This routine returns a success value.

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
	0.16 MV md5 project
	0.17 MV database
	0.18 MV perl module versions in files
	0.19 MV movies and small fixes
	0.20 MV thumbnail user interface
	0.21 MV more thumbnail issues
	0.22 MV website construction
	0.23 MV web site automation
	0.24 MV SEE ALSO section fix
	0.25 MV md5 issues

=head1 SEE ALSO

File::Find(3), Meta::Utils::File::Remove(3), strict(3)

=head1 TODO

Nothing.
