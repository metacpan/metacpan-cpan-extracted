#!/bin/echo This is a perl module and should not be run

package Meta::Ds::String;

use strict qw(vars refs subs);

our($VERSION,@ISA);
$VERSION="0.27";
@ISA=qw();

#sub new($);
#sub new_stri($);
#sub get_text($);
#sub set_text($$);
#sub cmp($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	$self->{TEXT}=defined;
	return($self);
}

sub new_stri($$) {
	my($class,$text)=@_;
	my($self)={};
	bless($self,$class);
	$self->{TEXT}=$text;
	return($self);
}

sub get_text($) {
	my($self)=@_;
	return($self->{TEXT});
}

sub set_text($$) {
	my($self,$text)=@_;
	$self->{TEXT}=$text;
}

sub cmp($$) {
	my($self,$obje)=@_;
	return($self->get_text() cmp $obje->get_text());
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::String - data structure that represents a string.

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

	MANIFEST: String.pm
	PROJECT: meta
	VERSION: 0.27

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::String qw();
	my($string)=Meta::Ds::String->new();
	$string->set_text("mark");

=head1 DESCRIPTION

This is a library to let you create a set like data structure.

=head1 FUNCTIONS

	new($)
	new_stri($)
	get_text($)
	set_text($$)
	cmp($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

Gives you a new String object.

=item B<new_stri($$)>

This method is a constructor for the Meta::Ds::String object giving you
a string object initialized to the content you supplied.

=item B<get_text($)>

This returns the text of the current string.

=item B<set_text($$)>

This will set the text of the current string.

=item B<cmp($$)>

This method compares the string received to another string.

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

	0.00 MV ok. This is for real
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
	0.16 MV PDMT
	0.17 MV fix database problems
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

strict(3)

=head1 TODO

-add a lot more methods to this object (catenation, searching, splitting etc...).

-remove this object from DS (it's not a data structure). Maybe DT for DataType ?
