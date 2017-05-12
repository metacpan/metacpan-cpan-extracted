#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Text::Lines;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.26";
@ISA=qw();

#sub new($);
#sub set_text($$$);
#sub remove_line($$);
#sub remove_line_re($$);
#sub remove_line_nre($$);
#sub get_text($);
#sub get_text_fixed($);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	$self->{DELI}=defined;
	$self->{LIST}=defined;
	$self->{ATEN}=defined;
	return($self);
}

sub set_text($$$) {
	my($self,$text,$deli)=@_;
	$self->{DELI}=$deli;
	my(@lines)=split($deli,$text);
	$self->{LIST}=\@lines;
}

sub remove_line($$) {
	my($self,$line)=@_;
	my($list)=$self->{LIST};
	my($size)=$#$list;
	for(my($i)=0;$i<=$size;$i++) {
		my($curr)=$list->[$i];
		if($curr eq $line) {
			$list->[$i]=undef;#remove the line
		}
	}
}

sub remove_line_re($$) {
	my($self,$re)=@_;
	my($list)=$self->{LIST};
	my($size)=$#$list;
	for(my($i)=0;$i<=$size;$i++) {
		my($curr)=$list->[$i];
		if($curr=~/$re/) {
			$list->[$i]=undef;#remove the line
		}
	}
}

sub remove_line_nre($$) {
	my($self,$re)=@_;
	my($list)=$self->{LIST};
	my($size)=$#$list;
	for(my($i)=0;$i<=$size;$i++) {
		my($curr)=$list->[$i];
#		Meta::Utils::Output::print("curr is [".$curr."]\n");
#		Meta::Utils::Output::print("re is [".$re."]\n");
		if($curr!~/$re/) {
#			Meta::Utils::Output::print("in match\n");
			$list->[$i]=undef;#remove the line
		}
	}
}

sub get_text($) {
	my($self)=@_;
	my($list)=$self->{LIST};
	my($size)=$#$list;
	my(@arra);
	for(my($i)=0;$i<=$size;$i++) {
		my($curr)=$list->[$i];
		if(defined($curr)) {
			push(@arra,$curr);
		}
	}
	my($resu)=join($self->{DELI},@arra);
	return($resu);
}

sub get_text_fixed($) {
	my($self)=@_;
	my($text)=$self->get_text();
	my($deli)=$self->{DELI};
	if($text ne "") {
		if(substr($text,-1) ne $deli) {
			$text.=$deli;
		}
	}
	return($text);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Text::Lines - library to do operations on sets of lines.

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

	MANIFEST: Lines.pm
	PROJECT: meta
	VERSION: 0.26

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Text::Lines qw();
	my($obje)=Meta::Utils::Text::Lines->new();
	$obje->set_text("mark\ndoron\n","\n");
	$obje->remove_line("doron");
	my($new_text)=$obje->get_text();

=head1 DESCRIPTION

This is a library to help you do things with lines of text coming from a file.
Currently it supports splitting the text and removing lines and returning
the text that results.

=head1 FUNCTIONS

	new($)
	set_text($$$)
	remove_line($$)
	remove_line_re($$)
	remove_line_nre($$)
	get_text($)
	get_text_fixed($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

Gives you a new Lines object.

=item B<set_text($$$)>

This will set the text that the object will work on.

=item B<remove_line($$)>

This will remove a line that you know the text of.

=item B<remove_line_re($$)>

This will remove all lines matching a certain regexp.

=item B<remove_line_nre($$)>

This will remove all lines not matching a certain regexp.

=item B<get_text($)>

This will retrieve the text currently stored in the object.

=item B<get_text_fixed($)>

This method is the same as get_text except it adds the delimiter at the end
if it is not there.

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

	0.00 MV fix up perl checks
	0.01 MV check that all uses have qw
	0.02 MV fix todo items look in pod documentation
	0.03 MV more on tests/more checks to perl
	0.04 MV change new methods to have prototypes
	0.05 MV perl code quality
	0.06 MV more perl quality
	0.07 MV more perl quality
	0.08 MV get papers in good condition
	0.09 MV perl documentation
	0.10 MV more perl quality
	0.11 MV perl qulity code
	0.12 MV more perl code quality
	0.13 MV revision change
	0.14 MV languages.pl test online
	0.15 MV perl packaging
	0.16 MV PDMT
	0.17 MV md5 project
	0.18 MV database
	0.19 MV perl module versions in files
	0.20 MV movies and small fixes
	0.21 MV thumbnail user interface
	0.22 MV more thumbnail issues
	0.23 MV website construction
	0.24 MV web site automation
	0.25 MV SEE ALSO section fix
	0.26 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.
