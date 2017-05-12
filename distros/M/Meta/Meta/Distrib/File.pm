#!/bin/echo This is a perl module and should not be run

package Meta::Distrib::File;

use strict qw(vars refs subs);

our($VERSION,@ISA);
$VERSION="0.28";
@ISA=qw();

#sub new($);
#sub set($$$$$$);
#sub get_sour($);
#sub set_sour($$);
#sub get_targ($);
#sub set_targ($$);
#sub get_buil($);
#sub set_buil($$);
#sub get_phys($);
#sub set_phys($$);
#sub get_perm($);
#sub set_perm($$);
#sub print($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	$self->{SOUR}=defined;
	$self->{TARG}=defined;
	$self->{BUIL}=defined;
	$self->{PHYS}=defined;
	$self->{PERM}=defined;
	return($self);
}

sub set($$$$$$) {
	my($self,$sour,$targ,$buil,$phys,$perm)=@_;
	$self->{SOUR}=$sour;
	$self->{TARG}=$targ;
	$self->{BUIL}=$buil;
	$self->{PHYS}=$phys;
	$self->{PERM}=$perm;
}

sub get_sour($) {
	my($self)=@_;
	return($self->{SOUR});
}

sub set_sour($$) {
	my($self,$sour)=@_;
	$self->{SOUR}=$sour;
}

sub get_targ($) {
	my($self)=@_;
	return($self->{TARG});
}

sub set_targ($$) {
	my($self,$targ)=@_;
	$self->{TARG}=$targ;
}

sub get_buil($) {
	my($self)=@_;
	return($self->{BUIL});
}

sub set_buil($$) {
	my($self,$buil)=@_;
	$self->{BUIL}=$buil;
}

sub get_phys($) {
	my($self)=@_;
	return($self->{PHYS});
}

sub set_phys($$) {
	my($self,$phys)=@_;
	$self->{PHYS}=$phys;
}

sub get_perm($) {
	my($self)=@_;
	return($self->{PERM});
}

sub set_perm($$) {
	my($self,$perm)=@_;
	$self->{PERM}=$perm;
}

sub print($$) {
	my($self,$file)=@_;
	print $file "sour=[".$self->get_sour()."]\n";
	print $file "targ=[".$self->get_targ()."]\n";
	print $file "buil=[".$self->get_buil()."]\n";
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Distrib::File - Object to store a definition of a file to be distributed.

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

	MANIFEST: File.pm
	PROJECT: meta
	VERSION: 0.28

=head1 SYNOPSIS

	package foo;
	use Meta::Distrib::File qw();
	my($file)=Meta::Distrib::File->new();
	$field->set_sour("/etc/hosts");
	$field->set_targ("/etc/hosts");

=head1 DESCRIPTION

This object will store the definition of a file to be used in a distribution
process.

=head1 FUNCTIONS

	new($)
	set($$$$$$)
	get_sour($)
	set_sour($$)
	get_targ($)
	set_targ($$)
	get_buil($)
	set_buil($$)
	get_phys($)
	set_phys($$)
	get_perm($)
	set_perm($$)
	print($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a table definitions.

=item B<set($$$$$$)>

This will set the sour,targ for you.

=item B<get_sour($)>

This gives you the source file for the distribution.

=item B<set_sour($$)>

This will set the name of the source file for distribution for you.

=item B<get_targ($)>

This will give you the name of the target file for the distribution for you.

=item B<set_targ($$)>

This will set the name of the target file for the distribution for you.

=item B<set_buil($$)>

This will set whether the file needs to be built.

=item B<get_phys($)>

This will give you the physical address of the file.

=item B<set_phys($$)>

This will set whether the file needs to be built.

=item B<get_perm($)>

This will give you the neccessary permissions for the current file.

=item B<set_perm($$)>

This will set the permissions for the current file.

=item B<print($$)>

This will print the current machine stats for you.

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
	0.01 MV bring databases on line
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV check that all uses have qw
	0.05 MV fix todo items look in pod documentation
	0.06 MV more on tests/more checks to perl
	0.07 MV change new methods to have prototypes
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
	0.18 MV PDMT
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

strict(3)

=head1 TODO

Nothing.
