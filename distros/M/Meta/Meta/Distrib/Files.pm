#!/bin/echo This is a perl module and should not be run

package Meta::Distrib::Files;

use strict qw(vars refs subs);
use Meta::Ds::Array qw();
use Meta::Baseline::Aegis qw();
use Meta::Distrib::File qw();
use Meta::IO::File qw();
use Meta::Development::Assert qw();
use Meta::Utils::Output qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.29";
@ISA=qw(Meta::Ds::Array);

#sub new($);
#sub read($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Ds::Array->new();
	bless($self,$class);
	return($self);
}

sub read($$) {
	my($self,$file)=@_;
	my($io)=Meta::IO::File->new_reader($file);
	while(!$io->eof()) {
		my($line)=$io->cgetline();
#		Meta::Utils::Output::print("in here with line [".$line."]\n");
		my(@fiel)=split('\t',$line);
		Meta::Development::Assert::assert_eq($#fiel,2,"number of fields needs to be 3");
		my($obje)=Meta::Distrib::File->new();
		my($sour)=$fiel[0];
		my($prefix);
		if(Meta::Baseline::Aegis::deve()) {
			$prefix="C".Meta::Baseline::Aegis::change();
		} else {
			$prefix=Meta::Baseline::Aegis::project();
		}
		my($targ)=$prefix."/".$sour;
		my($phys)=Meta::Baseline::Aegis::which($sour);
		my($buil_desc)=$fiel[1];
		if($buil_desc ne "build" && $buil_desc ne "source") {
			throw Meta::Error::Simple("what is file type [".$buil_desc."]");
		}
		my($buil);
		if($buil_desc eq "build") {
			$buil=1;
		} else {
			$buil=0;
		}
		my($perm)=$fiel[2];
		$obje->set_sour($sour);
		$obje->set_targ($targ);
		$obje->set_buil($buil);
		$obje->set_phys($phys);
		$obje->set_perm($perm);
		$self->push($obje);
	}
	$io->close();
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Distrib::Files - Object to store a definition of a list of files to distribute.

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

	MANIFEST: Files.pm
	PROJECT: meta
	VERSION: 0.29

=head1 SYNOPSIS

	package foo;
	use Meta::Distrib::Files qw();
	my($files)=Meta::Distrib::Files->new();
	$files->read("file_list.txt");

=head1 DESCRIPTION

This is an object to store a list of files.

=head1 FUNCTIONS

	new($)
	read($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a file list definitions.

=item B<read($$)>

This will read a file distribution list.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Ds::Array(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV initial code brought in
	0.01 MV bring databases on line
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV more on tests/more checks to perl
	0.08 MV change new methods to have prototypes
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
	0.19 MV perl packaging
	0.20 MV md5 project
	0.21 MV database
	0.22 MV perl module versions in files
	0.23 MV movies and small fixes
	0.24 MV thumbnail user interface
	0.25 MV more thumbnail issues
	0.26 MV website construction
	0.27 MV web site automation
	0.28 MV SEE ALSO section fix
	0.29 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Aegis(3), Meta::Development::Assert(3), Meta::Distrib::File(3), Meta::Ds::Array(3), Meta::IO::File(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.
