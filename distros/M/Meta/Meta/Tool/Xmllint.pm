#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Xmllint;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.07";
@ISA=qw();

#sub check_file($);
#sub check_modu($);
#sub TEST($);

#__DATA__

sub check_file($) {
	my($file)=@_;
	my($prog)="xmllint";
	my(@args);
	push(@args,"--valid");#validate the doc according to DTD
	push(@args,"--noout");#do not output anything
#	you need to set SGML_CATALOG_FILES env var to use the next line
#	push(@args,"--catalogs");#use catalog files
	push(@args,$file);
#	Meta::Utils::Output::print("args are [".join(',',@args)."]\n");
	my($code)=Meta::Utils::System::system_nodie($prog,\@args);
	return($code);
}

sub check_modu($) {
	my($modu)=@_;
	return(check_file($modu->get_abs_path()));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Xmllint - run xmllint to check xml files.

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

	MANIFEST: Xmllint.pm
	PROJECT: meta
	VERSION: 0.07

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Xmllint qw();
	my($result)=Meta::Tool::Xmllint::check_file("myxml.xml");

=head1 DESCRIPTION

This module runs xmllint to check XML files for you. xmllint is a tool supplied with libxml2 which is
the gnome projects xml library. This tool currently runs the command line "xmllint" executable so
it's not ideal but it's something...:).

=head1 FUNCTIONS

	check_file($)
	check_modu($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<check_file($)>

This method receives a file and checks it for you.

=item B<check_modu($)>

This method receives a development module and checks it for you.

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

	0.00 MV md5 progress
	0.01 MV thumbnail user interface
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV teachers project
	0.07 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Output(3), strict(3)

=head1 TODO

-run xmllint with DTD validation (the code is currently remarked because it cant find the DTDs - make it find them). look at the libxml2 library documentation. Some env var should be good enough.

-enable to the user of this tool to set and turn off options here. Turn this module into an object oriented one to do this.
