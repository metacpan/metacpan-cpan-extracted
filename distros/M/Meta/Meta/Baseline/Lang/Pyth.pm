#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Pyth;

use strict qw(vars refs subs);
use Meta::Utils::File::Path qw();
use Meta::Baseline::Aegis qw();
use Meta::Baseline::Lang qw();
use Meta::Utils::Env qw();

our($VERSION,@ISA);
$VERSION="0.33";
@ISA=qw(Meta::Baseline::Lang);

#sub env();
#sub c2chec($);
#sub c2deps($);
#sub c2html($);
#sub c2objs($);
#sub my_file($$);
#sub TEST($);

#__DATA__

sub env() {
	my(%hash);
	my($path)="";
	my($sear)=Meta::Baseline::Aegis::search_path_list();
	for(my($i)=0;$i<=$#$sear;$i++) {
		my($curr)=$sear->[$i];
		$path=Meta::Utils::File::Path::add_path($path,
			$curr."/pyth/lib/Meta",":");
		$path=Meta::Utils::File::Path::add_path($path,
			$curr."/pyth/import/lib/",":");
	}
	$hash{"PYTHONLIB"}=$path;
	return(\%hash);
}

sub c2chec($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2deps($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2html($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2objs($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^pyth\/.*\.py$/) {
		return(1);
	}
	if($file=~/^pyth\/.*\.pyc$/) {
		return(1);
	}
	return(0);
}

sub TEST($) {
	my($context)=@_;
	my($hash)=Meta::Baseline::Lang::Pyth::env();
	Meta::Utils::Env::bash_cat($hash);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Lang::Pyth - doing Python specific stuff in the baseline.

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

	MANIFEST: Pyth.pm
	PROJECT: meta
	VERSION: 0.33

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Python qw();
	my($hash)=Meta::Baseline::Lang::Pyth::env();

=head1 DESCRIPTION

This package does the 4 things that language packages in the baseline are
supposed to do:
0. Produce a hash of environment variable names which should be changed or
	set or removed in order for programs in this language to run.
1. Check a file name and answer if it belongs to this language or not.
2. Run different processes that concern this file - this could be compilation,
	translation, generating documentation, or strictness checking...
3. Wrap some code up in a comment.

For Python specific purposes this does:
0. Change the PYTHONLIB environment variable.
	(maybe the TKINTER stuff for Pytk?).
1. Checks that python executables and libraries end with .py.
	(and that they are in the baselines python library).
2. Run the following processes:
	0. change the first line of all python scripts to "/usr/bin/env python"
	1. compile python code to pyo and pyc (for optimized and non optimized).
	2. provide dependencies for python modules.
	3. run python lint processes on python sources.

=head1 FUNCTIONS

	env()
	c2chec($)
	c2deps($)
	c2html($)
	c2objs($)
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<env()>

This routie returns a hash of environment variables which are essential for
running Pyth scripts.

=item B<c2chec($)>

This routine will do various source verifications on Python code.
This method currently does nothing.
This method returns an error code.

=item B<c2deps($)>

This method will convert Python sources to dependency listings.
This method currently does nothing.
This method returns an error code.

=item B<c2html($)>

This method will convert Python sources to HTML documentation.
This method currently does nothing.
This method returns an error code.

=item B<c2objs($)>

This method will convert Python sources to Python Byte Code.
This method currently does nothing.
This method returns an error code.

=item B<my_file($$)>

This method will return true if the file received should be handled by this
module.

=item B<TEST($)>

Test suite for this module.
This currently just runs the Env stuff and checks whats the output bash script.

=back

=head1 SUPER CLASSES

Meta::Baseline::Lang(3)

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
	0.07 MV more organization
	0.08 MV perl quality change
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV perl documentation
	0.13 MV more perl quality
	0.14 MV perl qulity code
	0.15 MV more perl code quality
	0.16 MV revision change
	0.17 MV revision for perl files and better sanity checks
	0.18 MV languages.pl test online
	0.19 MV xml/rpc client/server
	0.20 MV web site and docbook style sheets
	0.21 MV perl packaging
	0.22 MV BuildInfo object change
	0.23 MV md5 project
	0.24 MV database
	0.25 MV perl module versions in files
	0.26 MV movies and small fixes
	0.27 MV thumbnail user interface
	0.28 MV more thumbnail issues
	0.29 MV website construction
	0.30 MV web site automation
	0.31 MV SEE ALSO section fix
	0.32 MV put all tests in modules
	0.33 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Lang(3), Meta::Utils::Env(3), Meta::Utils::File::Path(3), strict(3)

=head1 TODO

Nothing.

