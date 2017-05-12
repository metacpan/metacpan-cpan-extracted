#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Arch;

use strict qw(vars refs subs);
use Meta::Ds::Dhash qw();
use Meta::Baseline::Aegis qw();
use Meta::Class::MethodMaker qw();
use Meta::Utils::Output qw();
use Meta::Development::Assert qw();

our($VERSION,@ISA);
$VERSION="0.34";
@ISA=qw();

#sub BEGIN();
#sub analyze($$);
#sub get_string($);
#sub get_dire($);
#sub get_obj_directory($);
#sub get_lib_directory($);
#sub get_dll_directory($);
#sub get_bin_directory($);
#sub TEST($);

#__DATA__

our($hash);

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_cpu",
		-java=>"_os",
		-java=>"_os_version",
		-java=>"_compiler",
		-java=>"_compiler_version",
		-java=>"_flagset_primary",
		-java=>"_flagset_secondary",
	);
	my($file)=Meta::Baseline::Aegis::which("data/baseline/arch/data.txt");
	$hash=Meta::Ds::Dhash->new();
	$hash->read($file);
}

sub analyze($$) {
	my($self,$arch)=@_;
	my(@fiel)=split('-',$arch);
	Meta::Development::Assert::assert_eq($#fiel,6,"6 fields in architecture expected");
	$self->set_cpu($fiel[0]);
	$self->set_os($fiel[1]);
	$self->set_os_version($fiel[2]);
	$self->set_compiler($fiel[3]);
	$self->set_compiler_version($fiel[4]);
	$self->set_flagset_primary($fiel[5]);
	$self->set_flagset_secondary($fiel[6]);
}

sub get_string($) {
	my($self)=@_;
	return(join("-",
			$self->get_cpu(),
			$self->get_os(),
			$self->get_os_version(),
			$self->get_compiler(),
			$self->get_compiler_version(),
			$self->get_flagset_primary(),
			$self->get_flagset_secondary()
		)
	);
}

sub get_dire($) {
	my($self)=@_;
	return($hash->get_a($self->get_string()));
}

sub from_dire($$) {
	my($self,$dire)=@_;
	my($arch)=$hash->get_b($dire);
	$self->analyze($arch);
}

sub get_obj_directory($) {
	my($self)=@_;
	my($temp)=$self->get_flagset_primary();
	$self->set_flagset_primary("obj");
	my($retu)=$self->get_dire();
	$self->set_flagset_primary($temp);
	return($retu);
}

sub get_lib_directory($) {
	my($self)=@_;
	my($temp)=$self->get_flagset_primary();
	$self->set_flagset_primary("lib");
	my($retu)=$self->get_dire();
	$self->set_flagset_primary($temp);
	return($retu);
}

sub get_dll_directory($) {
	my($self)=@_;
	my($temp)=$self->get_flagset_primary();
	$self->set_flagset_primary("dll");
	my($retu)=$self->get_dire();
	$self->set_flagset_primary($temp);
	return($retu);
}

sub get_bin_directory($) {
	my($self)=@_;
	my($temp)=$self->get_flagset_primary();
	$self->set_flagset_primary("bin");
	my($retu)=$self->get_dire();
	$self->set_flagset_primary($temp);
	return($retu);
}

sub TEST($) {
	my($context)=@_;
	my($arch)=Meta::Baseline::Arch->new();
	$arch->analyze("pentium3-linux-2.4.19-g++-3.2-obj-dbg");
	Meta::Utils::Output::dump($arch);
	$arch->from_dire("bins/reg.cxx.bin.dbg");
	Meta::Utils::Output::dump($arch);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Arch - library to provide utilities to handle architecture details.

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

	MANIFEST: Arch.pm
	PROJECT: meta
	VERSION: 0.34

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Arch qw();
	my($arch)=Meta::Baseline::Arch->new();
	Meta::Baseline::Arch::get_cpu();

=head1 DESCRIPTION

This package will provide information about the current architecture on which
you are running and will analyze architecture strings and return information
from them.

=head1 FUNCTIONS

	BEGIN()
	analyze($$)
	get_string($)
	get_dire($)
	get_obj_directory($)
	get_lib_directory($)
	get_dll_directory($)
	get_bin_directory($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method will setup the accessor methods for this class.
They are:
cpu: id of the cpu that the compilation is for.
cpu_version: version of the cpu that the compilation is for.
os: id of the os that the compilation is for.
os_version: version of the os that the compilation is for.
compiler: compiler that did the compilation.
compiler_version: version of the compiler that did the compilation.
flagset_primary: which flag set was used (primary).
flagset_secondary: which flag set was used (secondary).

=item B<analyze($$)>

This will get an architecture object and a string representing an
architecture. This will check that the string is indeed an architecture
(or will die) and if so will set the current object to that architecture.

=item B<get_string($)>

This will give you a description string for the architecture.

=item B<get_dire($)>

This will give you a directory name which uniquely identified this architecture.

=item B<from_dire($$)>

This will perform the reverse of analyze using the reverse hash.

=item B<get_obj_directory($)>

This will return the object directory for this architecture.

=item B<get_lib_directory($)>

This will return the library directory for this architecture.

=item B<get_dll_directory($)>

This will return the dynamic library directory for this architecture.

=item B<get_bin_directory($)>

This will return the binary directory for this architecture.

=item B<TEST($)>

Test suite for this module.
It currently just creates an object, puts an architecture in it and checks
the translation into directory names.

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

	0.00 MV bring databases on line
	0.01 MV handle architectures better
	0.02 MV adding an XML viewer/editor to work with the baseline
	0.03 MV make quality checks on perl code
	0.04 MV more perl checks
	0.05 MV make Meta::Utils::Opts object oriented
	0.06 MV check that all uses have qw
	0.07 MV fix todo items look in pod documentation
	0.08 MV more on tests/more checks to perl
	0.09 MV change new methods to have prototypes
	0.10 MV correct die usage
	0.11 MV perl code quality
	0.12 MV more perl quality
	0.13 MV more perl quality
	0.14 MV perl documentation
	0.15 MV more perl quality
	0.16 MV perl qulity code
	0.17 MV more perl code quality
	0.18 MV revision change
	0.19 MV languages.pl test online
	0.20 MV perl packaging
	0.21 MV PDMT
	0.22 MV md5 project
	0.23 MV database
	0.24 MV perl module versions in files
	0.25 MV movies and small fixes
	0.26 MV thumbnail project basics
	0.27 MV thumbnail user interface
	0.28 MV more thumbnail issues
	0.29 MV website construction
	0.30 MV web site development
	0.31 MV web site automation
	0.32 MV SEE ALSO section fix
	0.33 MV teachers project
	0.34 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Class::MethodMaker(3), Meta::Development::Assert(3), Meta::Ds::Dhash(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-add a collections for each component of the architecture so the class will know which are true architectures.

-make the class know which two architectures are compatible (compatibility is a one way graph...:)

-make all of the data above come from files.

-fix get_dire to give a directory name which is a little better than the clean concatenation (so it will be shorter...).

-add the cpu version component.

-make the version here be my faithful versiono.

-think more about if we really need the name "CPU" here or maybe just make this an array of components which are of interest ?

-move this out of this directory and into Development or something....

-turn the input file for this class to be xml based.
