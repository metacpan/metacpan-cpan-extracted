#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Docb::Params;

use strict qw(vars refs subs);

our($VERSION,@ISA);
$VERSION="0.17";
@ISA=qw();

#sub get_encoding();
#sub get_public();
#sub get_system();
#sub get_xsystem();
#sub get_comment();
#sub get_extra();
#sub TEST($);

#__DATA__

sub get_encoding() {
	return("ISO-8859-1");
}

sub get_public() {
	return("-//OASIS//DTD DocBook V4.1//EN");
#	return(undef);
}

sub get_system() {
	return("impo/sgml/docbook.dtd");
#	return("docbook.dtd");
#	return(undef);
}

sub get_xsystem() {
	return("docbookx.dtd");
}

sub get_comment() {
	return("Base auto generated DocBook file - DO NOT EDIT!");
}

sub get_extra() {
#	return("/usr/lib/sgml:/usr/lib/sgml/stylesheets/sgmltools");
	return("");
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Docb::Params - supply parameters about DocBook usage.

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

	MANIFEST: Params.pm
	PROJECT: meta
	VERSION: 0.17

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Docb::Params qw();
	my($object)=Meta::Lang::Docb::Params->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module will supply you with parameters regarding DocBook issues.
currently supported are:
0. encoding.
1. public id.
2. filename.

=head1 FUNCTIONS

	get_encoding()
	get_public()
	get_system()
	get_xsystem()
	get_comment()
	get_extra()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<get_encoding()>

This will supply you with the default encoding that we use.

=item B<get_public()>

This method will give you the public id of the document dtd we are using.

=item B<get_system()>

This method will give you the file name of the document dtd we are using.

=item B<get_xsystem()>

This method will give you the file name of the document XML dtd we are using.

=item B<get_comment()>

This method will give you a standard comment to put on all docbook files.

=item B<get_extra()>

This method will give you the extra path where to look for SGML data.

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

	0.00 MV get graph stuff going
	0.01 MV more perl quality
	0.02 MV more perl code quality
	0.03 MV revision change
	0.04 MV cook updates
	0.05 MV languages.pl test online
	0.06 MV history change
	0.07 MV perl packaging
	0.08 MV md5 project
	0.09 MV database
	0.10 MV perl module versions in files
	0.11 MV movies and small fixes
	0.12 MV thumbnail user interface
	0.13 MV more thumbnail issues
	0.14 MV website construction
	0.15 MV web site automation
	0.16 MV SEE ALSO section fix
	0.17 MV md5 issues

=head1 SEE ALSO

strict(3)

=head1 TODO

-read all the stuff here from some xml configuration file.
