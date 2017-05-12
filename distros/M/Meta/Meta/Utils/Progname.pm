#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Progname;

use strict qw(vars refs subs);
use File::Basename qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.25";
@ISA=qw();

#sub basename();
#sub progname();
#sub fullname();
#sub TEST($);

#__DATA__

sub basename() {
	my($prog)=progname();
	my($base)=($prog=~/^(.*)\.pl$/);
	if(!defined($base)) {
		throw Meta::Error::Simple("unable to extract name from script [".$prog."]");
	}
	return($base);
}

sub progname() {
	return(File::Basename::basename($0));
}

sub fullname() {
	return($0);
}

sub TEST($) {
	my($context)=@_;
	my($base)=basename();
	my($prog)=progname();
	my($full)=fullname();
	Meta::Utils::Output::print("basename is [".$base."]\n");
	Meta::Utils::Output::print("progname is [".$prog."]\n");
	Meta::Utils::Output::print("fullname is [".$full."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Progname - give you the name of the current script.

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

	MANIFEST: Progname.pm
	PROJECT: meta
	VERSION: 0.25

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Progname qw();
	my($prog)=Meta::Utils::Progname::progname();

=head1 DESCRIPTION

This is a lean and mean library to give you the name of the current script
you're running.

Why should you have such a library ? Doesn't $0 contain that ? Well - anyone
that think that $0 is a good variable name for holding the current script
name raise his hand! No one ? good. Use this library - I'm sure that $0 will
be gone one day and they you'll be sorry.

=head1 FUNCTIONS

	basename()
	progname()
	fullname()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<basename()>

This method will give you the name of the current perl script
you are running without the a ".pl" extension. If your script does
not have a ".pl" extension calling this method will cause an
exception so you better know which type of standard for names
your scripts follow.

=item B<progname()>

Give you the name of the current perl script you are running in.
The implementation is currently just taking the $0 variable (which
holds the running image path) and removes all the junk using the basename
function.

=item B<fullname()>

This routine returns the full path to the current script. This could be
useful for various purposes.

=item B<TEST($)>

A small test suite for this module. Call it to test the functionality
of the module.

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
	0.06 MV perl code quality
	0.07 MV more perl quality
	0.08 MV more perl quality
	0.09 MV perl documentation
	0.10 MV more perl quality
	0.11 MV more perl code quality
	0.12 MV revision change
	0.13 MV languages.pl test online
	0.14 MV perl packaging
	0.15 MV md5 project
	0.16 MV database
	0.17 MV perl module versions in files
	0.18 MV movies and small fixes
	0.19 MV thumbnail user interface
	0.20 MV dbman package creation
	0.21 MV more thumbnail issues
	0.22 MV website construction
	0.23 MV web site automation
	0.24 MV SEE ALSO section fix
	0.25 MV md5 issues

=head1 SEE ALSO

Error(3), File::Basename(3), strict(3)

=head1 TODO

Nothing.
