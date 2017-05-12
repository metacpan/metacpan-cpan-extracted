#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Cleanup;

use strict qw(vars refs subs);
use Meta::Utils::Hash qw();
use Meta::Utils::File::Remove qw();
use Meta::Utils::File::Collect qw();
use Meta::Utils::File::Purge qw();
use Meta::Baseline::Aegis qw();
use Meta::Baseline::Cook qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.27";
@ISA=qw();

#sub cleanup($$$$$$);
#sub extra_files_hash($$$$);
#sub no_extra_files($$$$);
#sub TEST($);

#__DATA__

sub cleanup($$$$$$) {
	my($dire,$abso,$safe,$matc,$demo,$verb)=@_;
	my($hash)=extra_files_hash($dire,$abso,$safe,0);
	$hash=Meta::Utils::Hash::filter_regexp($hash,$matc,1);
	my($resu)=Meta::Utils::File::Remove::rmhash($hash);
	if(!$resu) {
		return($resu);
	}
	my($numb);
	return(Meta::Utils::File::Purge::purge($dire,$demo,$verb,\$numb));
}

sub extra_files_hash($$$$) {
	my($dire,$abso,$safe,$verb)=@_;
	my($hash)=Meta::Utils::File::Collect::hash($dire,$abso);
	my($chan)=Meta::Baseline::Aegis::change_files_hash(1,1,1,1,1,$abso);
	Meta::Utils::Hash::remove_hash($hash,$chan,0);
	if($safe) {
		Meta::Baseline::Cook::file_init();
		while(my($key,$val)=each(%$hash)) {
			if(!Meta::Baseline::Cook::file_temp($key)) {
				delete($hash->{$key});
			}
		}
	}
	if($verb) {
		Meta::Utils::Hash::print(Meta::Utils::Output::get_file(),$hash);
	}
	return($hash);
}

sub no_extra_files($$$$) {
	my($dire,$abso,$safe,$verb)=@_;
	my($hash)=extra_files_hash($dire,$abso,$safe,$verb);
	return(Meta::Utils::Hash::empty($hash));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Cleanup - module to do cleanup of a change.

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

	MANIFEST: Cleanup.pm
	PROJECT: meta
	VERSION: 0.27

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Cleanup qw();
	Meta::Baseline::Cleanup::cleanup($directory,$demo,$abso,$matc,$safe,$verbose);

=head1 DESCRIPTION

This module gives you a cleaning up utility for parts of the baseline.
This is the basis of the now all world popular cleanup.pl script.
Have a good time on me.

p.s. Aegis gives this service (aeclean) but it doesnt have a demo type
flag and so we want to have our own implementation.

=head1 FUNCTIONS

	cleanup($$$$$$)
	extra_files_hash($$$$)
	no_extra_files($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<cleanup($$$$$$)>

This function does the actual cleaning up.
It just uses the extra_files_hash and removes the files and then
does some purging.
input:
0. directory - directory in which to cleanup.
1. absolute - whether to work in absolute mode or not.
2. safe - whether the cleanup will be safe or not.
3. matc - string to match agains for each remove.
4. demo - whether this is a demo or not.
5. verbose - whether to be verbose or not.

This routine returns a success value.

=item B<extra_files_hash($$$$)>

This routine receives a directory and returns a hash with all the
files in that directory which are not reported to aegis (extra).
The way the routine works is using collect to collect all the files in
the directory, using change_files to get all the files in the change
and subtracting one from the other. If safe mode is on it also subtracts
anything which is not a temp file.
input:
0. directory - directory in which to check for extra files.
1. absolute - whether to give out a hash with absolute file names or not.
2. safe - whether the check will be safe or not.
3. verb - whether the check will be verbose or not.

=item B<no_extra_files($$$$)>

This routine returns a boolean according to whether there are no extra files
in the directory it receives.
input:
0. directory - directory in which to check.
1. absolute - whether the check will use absolute pathnames.
2. safe - whether the check will be safe.
3. verb - whether to be verbose or not.
The routine simply calls extra_files_hash and checks if the hash is empty.

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
	0.05 MV make all tests real tests
	0.06 MV more on tests/more checks to perl
	0.07 MV more perl quality
	0.08 MV perl code quality
	0.09 MV more perl quality
	0.10 MV more perl quality
	0.11 MV perl documentation
	0.12 MV more perl quality
	0.13 MV perl qulity code
	0.14 MV more perl code quality
	0.15 MV revision change
	0.16 MV languages.pl test online
	0.17 MV perl packaging
	0.18 MV md5 project
	0.19 MV database
	0.20 MV perl module versions in files
	0.21 MV movies and small fixes
	0.22 MV thumbnail user interface
	0.23 MV more thumbnail issues
	0.24 MV website construction
	0.25 MV web site automation
	0.26 MV SEE ALSO section fix
	0.27 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Cook(3), Meta::Utils::File::Collect(3), Meta::Utils::File::Purge(3), Meta::Utils::File::Remove(3), Meta::Utils::Hash(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-Cleanup does not work well when $abso is 0. fix this. after that fix the base_aegi_cleanup script which uses this to have a default value of 0 on the $abso flag.
