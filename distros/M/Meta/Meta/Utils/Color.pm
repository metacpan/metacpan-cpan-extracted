#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Color;

use strict qw(vars refs subs);
use Term::ANSIColor qw();

our($VERSION,@ISA);
$VERSION="0.27";
@ISA=qw();

#sub set_color($$);
#sub get_color($);
#sub get_reset();
#sub reset($);
#sub TEST($);

#__DATA__

sub set_color($$) {
	my($file,$colo)=@_;
	print $file Term::ANSIColor::color($colo);
}

sub get_color($) {
	my($colo)=@_;
	return(Term::ANSIColor::color($colo));
}

sub get_reset() {
	return(Term::ANSIColor::color("reset"));
}

sub reset($) {
	my($file)=@_;
	set_color($file,"reset");
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Color - give you options to color the text you're writing.

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

	MANIFEST: Color.pm
	PROJECT: meta
	VERSION: 0.27

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Color qw();
	Meta::Utils::Color::set_color(*FILE,"red");
	Meta::Utils::Output::print("Hello, World!\n");

=head1 DESCRIPTION

This is a library to give you a clean interface to the ANSIColor.pm module
which enables nice coloring and emition of color escape codes for terminals
and texts.

=head1 FUNCTIONS

	set_color($$)
	get_color($)
	get_reset()
	reset($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<set_color($$)>

This sets the current color for writing to the file received.

=item B<get_color($)>

This returns the escape sequence needed to provide a certain color on
the console.

=item B<get_reset()>

This method return the escape sequence needed to reset the color on
the console.

=item B<reset($)>

This resets the color to the regular color and avoids all kinds
of weird side effects (for the file specified of course).

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
	0.06 MV cleanup tests change
	0.07 MV perl code quality
	0.08 MV more perl quality
	0.09 MV more perl quality
	0.10 MV perl documentation
	0.11 MV more perl quality
	0.12 MV perl qulity code
	0.13 MV more perl code quality
	0.14 MV revision change
	0.15 MV languages.pl test online
	0.16 MV perl packaging
	0.17 MV more movies
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

Term::ANSIColor(3), strict(3)

=head1 TODO

-the reset won't actually get done unless the file gets flushed.
