#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Ccxx;

use strict qw(vars refs subs);
use Meta::Baseline::Lang qw();
use Meta::Baseline::Utils qw();
use Meta::Tool::Cincl qw();
use Meta::Tool::Gcc qw();

our($VERSION,@ISA);
$VERSION="0.31";
@ISA=qw(Meta::Baseline::Lang);

#sub c2deps($);
#sub c2chec($);
#sub c2html($);
#sub c2objs($);
#sub my_file($$);
#sub TEST($);

#__DATA__

sub c2deps($) {
	my($buil)=@_;
	my($res)=Meta::Tool::Cincl::run($buil);
	return($res);
}

sub c2chec($) {
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
	my($res)=Meta::Tool::Gcc::compile($buil);
	return($res);
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^ccxx\/.*\.cc$/) {
		return(1);
	}
	if($file=~/^ccxx\/.*\.hh$/) {
		return(1);
	}
	if($file=~/^ccxx\/.*\.ii$/) {
		return(1);
	}
	if($file=~/^ccxx\/.*\.tt$/) {
		return(1);
	}
	return(0);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Lang::Ccxx - library to handle C++ stuff in the baseline.

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

	MANIFEST: Ccxx.pm
	PROJECT: meta
	VERSION: 0.31

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Ccxx qw();
	Meta::Baseline::Lang::Ccxx::run_with_flags("hello","gcc","opt");

=head1 DESCRIPTION

This will do stuff that concerns the use of the C++ programming language
in the baseline.
This includes:
0. identifiying C++ sources.
1. providing C++ template files to start writing source files.
2. sanity checking C++ sources.
3. sanity checking C++ objects.
4. turn c++ sources to documentation.

=head1 FUNCTIONS

	c2deps($)
	c2chec($)
	c2html($)
	c2objs($)
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2deps($)>

This will turn C++ files into dependencies.

=item B<c2chec($)>

This will check C++ files using various tools.

=item B<c2html($)>

This will turn C++ files into documentation.

=item B<c2objs($)>

This will turn C++ files into object files (compile them).

=item B<my_file($$)>

This method will return true if the file receives should be handled by this
module.

=item B<TEST($)>

Test suite for this module.

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
	0.07 MV perl quality change
	0.08 MV perl code quality
	0.09 MV more perl quality
	0.10 MV more perl quality
	0.11 MV perl documentation
	0.12 MV more perl quality
	0.13 MV perl qulity code
	0.14 MV more perl code quality
	0.15 MV revision change
	0.16 MV revision for perl files and better sanity checks
	0.17 MV languages.pl test online
	0.18 MV C++ and temp stuff
	0.19 MV c++ framework stuff
	0.20 MV perl packaging
	0.21 MV BuildInfo object change
	0.22 MV md5 project
	0.23 MV database
	0.24 MV perl module versions in files
	0.25 MV movies and small fixes
	0.26 MV thumbnail user interface
	0.27 MV more thumbnail issues
	0.28 MV website construction
	0.29 MV web site automation
	0.30 MV SEE ALSO section fix
	0.31 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Lang(3), Meta::Baseline::Utils(3), Meta::Tool::Cincl(3), Meta::Tool::Gcc(3), strict(3)

=head1 TODO

Nothing.
