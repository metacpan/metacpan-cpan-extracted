#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Prop;

use strict qw(vars refs subs);
use File::stat qw();
use Meta::Utils::Utils qw();
use Meta::Utils::Output qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.31";
@ISA=qw();

#sub chown($$$);
#sub chown_curr($);
#sub chmod_r($);
#sub chmod_x($);
#sub chmod_agw($);
#sub chmod_rgw($);
#sub same_mode($$);
#sub stat($);
#sub size($);
#sub mode($);
#sub is_r($);
#sub TEST($);

#__DATA__

sub chown($$$) {
	my($uidx,$gidx,$file)=@_;
	if(!CORE::chown($uidx,$gidx,$file)) {
		throw Meta::Error::Simple("unable to chown [".$file."] to [".$uidx.",".$gidx."]");
	}
}

sub chown_curr($) {
	my($file)=@_;
	&chown(Meta::Utils::Utils::cuid(),Meta::Utils::Utils::cgid(),$file);
}

sub chmod_r($) {
	my($file)=@_;
	if(!CORE::chmod(0444,$file)) {
		throw Meta::Error::Simple("unable to chmod file [".$file."] to [0444]");
	}
}

sub chmod_x($) {
	my($file)=@_;
	if(!CORE::chmod(0755,$file)) {
		throw Meta::Error::Simple("unable to chmod file [".$file."] to [0755]\n");
	}
}

sub chmod_agw($) {
	my($file)=@_;
	if(!CORE::chmod(mode($file) | 00020,$file)) {
		throw Meta::Error::Simple("unable to chmod file [".$file."] to [| 00020]");
	}
}

sub chmod_rgw($) {
	my($file)=@_;
	if(!CORE::chmod(mode($file) & 07757,$file)) {
		throw Meta::Error::Simple("unable to chmod file [".$file."] to [& 07757]");
	}
}

sub same_mode($$) {
	my($fn1,$fn2)=@_;
	my($mode)=&mode($fn1);
	if(!CORE::chmod($mode,$fn2)) {
		throw Meta::Error::Simple("unable to chmod file [".$fn2."] to [".$mode."]");
	}
}

sub stat($) {
	my($file)=@_;
	my($sb)=File::stat::stat($file);
	if(!$sb) {
		throw Meta::Error::Simple("unable to stat the file [".$file."]");
	}
	return($sb);
}

sub size($) {
	my($file)=@_;
	return(&stat($file)->size());
}

sub mode($) {
	my($file)=@_;
	return(&stat($file)->mode());
}

sub is_r($) {
	my($file)=@_;
	return(&mode($file)==444);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Prop - library to help you chmod files and test file properties.

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

	MANIFEST: Prop.pm
	PROJECT: meta
	VERSION: 0.31

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Prop qw();
	Meta::Utils::File::Prop::chmod_r($file);

=head1 DESCRIPTION

This module eases setting permissions on files.
This module provides method to:
1. change ownerships on files.
2. change read/write/execute permissions on files.
3. get various pieces of info on the file using the stat function.
and other things.

=head1 FUNCTIONS

	chown($$$)
	chown_curr($)
	chmod_r($)
	chmod_x($)
	chmod_agw($)
	chmod_rgw($)
	same_mode($$)
	stat($)
	size($)
	mode($)
	is_r($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<chown($$$)>

This functions receives a uid and a gid and changes a certain files owner
to that uid and gid. The function dies if it cannot do so.

=item B<chown_curr($)>

Changes the owner id and group id of a certain file to the current group
id and owner id.

=item B<chmod_r($)>

This function makes a file read only (receives only one file as argument).

=item B<chmod_x($)>

This function make a file executable too (receives only one file as argument).

=item B<chmod_agw($)>

This functions adds a g+w permission to a file or a directory.

=item B<chmod_rgw($)>

This function adds a g-w permission to a file or a directory.

=item B<same_mode($$)>

This function gets two file names and makes the mode of the second be like
the first.

=item B<stat($)>

This method will stat the file and return the stat structure.

=item B<size($)>

This method returns the size of the file given.

=item B<mode($)>

This functions returns the current mode of a file.
The function dies if it cannot stat the file (which means the file does not
exist...).

=item B<is_r($)>

This function tests whether a file is indeed read only.

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
	0.07 MV correct die usage
	0.08 MV Java compilation
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
	0.19 MV xml
	0.20 MV md5 project
	0.21 MV database
	0.22 MV perl module versions in files
	0.23 MV movies and small fixes
	0.24 MV thumbnail user interface
	0.25 MV import tests
	0.26 MV more thumbnail issues
	0.27 MV website construction
	0.28 MV web site automation
	0.29 MV SEE ALSO section fix
	0.30 MV web site development
	0.31 MV md5 issues

=head1 SEE ALSO

Error(3), File::stat(3), Meta::Utils::Output(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-do a lot more functions here.

-fix the is_r function which actualy tests for absolute premission which is not what it is intended to do.

-add a function to test for absolute permissions as this is needed by baseline checking routines.
