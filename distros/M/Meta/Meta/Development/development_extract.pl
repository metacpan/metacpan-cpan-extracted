#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Development::Module qw();
use Meta::Lang::Xml::Xml qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

# setup the right path for XML parsing

Meta::Lang::Xml::Xml::setup_path();

my($module1)=Meta::Development::Module->new();
$module1->set_name("xmlx/def/movie.xml");
Meta::Utils::Output::print("name is [".$module1->get_xml_def_name()."]\n");

my($module2)=Meta::Development::Module->new();
$module2->set_name("sgml/temp/sgml/papers/biology/neo_conflict.sgml");
Meta::Utils::Output::print("sgml title is [".$module2->get_sgml_name()."]\n");

my($module3)=Meta::Development::Module->new();
$module3->set_name("temp/sgml/papers/biology/neo_conflict.temp");
Meta::Utils::Output::print("temp sgml title is [".$module3->get_temp_sgml_name()."]\n");

my($module4)=Meta::Development::Module->new();
$module4->set_name("temp/sgml/projects/computing/pdmt.temp");
Meta::Utils::Output::print("temp sgml book title is [".$module4->get_temp_sgml_book()."]\n");

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

development_extract.pl - extract various information from development modules.

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

	MANIFEST: development_extract.pl
	PROJECT: meta
	VERSION: 0.05

=head1 SYNOPSIS

	development_extract.pl [options]

=head1 DESCRIPTION

This script tests various capabilities of the development module object to extract
information from development modules.

=head1 OPTIONS

=over 4

=item B<help> (type: bool, default: 0)

display help message

=item B<pod> (type: bool, default: 0)

display pod options snipplet

=item B<man> (type: bool, default: 0)

display manual page

=item B<quit> (type: bool, default: 0)

quit without doing anything

=item B<gtk> (type: bool, default: 0)

run a gtk ui to get the parameters

=item B<license> (type: bool, default: 0)

show license and exit

=item B<copyright> (type: bool, default: 0)

show copyright and exit

=item B<description> (type: bool, default: 0)

show description and exit

=item B<history> (type: bool, default: 0)

show history and exit

=back

no free arguments are allowed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV more web page stuff
	0.01 MV web site automation
	0.02 MV SEE ALSO section fix
	0.03 MV put all tests in modules
	0.04 MV move tests to modules
	0.05 MV md5 issues

=head1 SEE ALSO

Meta::Development::Module(3), Meta::Lang::Xml::Xml(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-move this whole thing as a test for Meta::Development::Module.
