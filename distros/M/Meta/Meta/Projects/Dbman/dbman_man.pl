#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Projects::Dbman::Page qw();
use Meta::Tool::Less qw();
use Meta::Utils::Output qw();
use Compress::Zlib qw();
use Meta::Info::Enum qw();
use Meta::Error::Simple qw();
use Meta::Db::Connections qw();
use Meta::Class::DBI qw();

my($connections_file,$con_name,$dbname,$choice);
my($enum)=Meta::Info::Enum->new();
$enum->insert("description","the description of the page");
$enum->insert("troff","the troff version of the page");
$enum->insert("ascii","the plain ascii text version of the page");
$enum->insert("ps","the postscript version");
$enum->insert("dvi","the dvi version");
$enum->insert("html","the html version");
$enum->set_default("ascii");
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("con_name","what connection name ?",undef,\$con_name);
$opts->def_stri("name","what database name ?","dbman",\$dbname);
$opts->def_enum("display","what should I display ?","ascii",\$choice,$enum);
$opts->set_free_allo(1);
$opts->set_free_stri("[name]");
$opts->set_free_mini(1);
$opts->set_free_maxi(1);
$opts->analyze(\@ARGV);

my($connections)=Meta::Db::Connections->new_modu($connections_file);
my($connection)=$connections->get_con_null($con_name);
Meta::Class::DBI::set_connection($connection,$dbname);

my($name)=$ARGV[0];
my($page)=Meta::Projects::Dbman::Page->search('name',$name);
if(!defined($page)) {
	throw Meta::Error::Simple("unable to find manual page for [".$name."]");
}
if($enum->is_selected($choice,"description")) {
	Meta::Utils::Output::print($page->description()."\n");
}
if($enum->is_selected($choice,"troff")) {
	Meta::Tool::Less::show_data(Compress::Zlib::memGunzip($page->contenttroff()));
}
if($enum->is_selected($choice,"ascii")) {
	Meta::Tool::Less::show_data(Compress::Zlib::memGunzip($page->contentascii()));
	Meta::Utils::File::File::save("/tmp/tmp",Compress::Zlib::memGunzip($page->contentascii()));
}
if($enum->is_selected($choice,"ps")) {
	Meta::Tool::Less::show_data(Compress::Zlib::memGunzip($page->contentps()));
}
if($enum->is_selected($choice,"dvi")) {
	Meta::Tool::Less::show_data(Compress::Zlib::memGunzip($page->contentdvi()));
}
if($enum->is_selected($choice,"html")) {
	Meta::Tool::Less::show_data(Compress::Zlib::memGunzip($page->contenthtml()));
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

dbman_man.pl - display a manual page from the Dbman database.

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

	MANIFEST: dbman_man.pl
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	dbman_man.pl [options]

=head1 DESCRIPTION

This program displays manual pages stored in the Dbman database.

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

=item B<connections_file> (type: modu, default: xmlx/connections/connections.xml)

what connections XML file to use ?

=item B<con_name> (type: stri, default: )

what connection name ?

=item B<name> (type: stri, default: dbman)

what database name ?

=item B<display> (type: enum, default: ascii)

what should I display ?

options:
	description - the description of the page
	troff - the troff version of the page
	ascii - the plain ascii text version of the page
	ps - the postscript version
	dvi - the dvi version
	html - the html version

=back

minimum of [1] free arguments required
no maximum limit on number of free arguments placed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV import tests
	0.01 MV dbman package creation
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV improve the movie db xml
	0.05 MV web site automation
	0.06 MV SEE ALSO section fix
	0.07 MV move tests to modules
	0.08 MV download scripts
	0.09 MV bring movie data
	0.10 MV finish papers
	0.11 MV teachers project
	0.12 MV md5 issues

=head1 SEE ALSO

Compress::Zlib(3), Meta::Class::DBI(3), Meta::Db::Connections(3), Meta::Error::Simple(3), Meta::Info::Enum(3), Meta::Projects::Dbman::Page(3), Meta::Tool::Less(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-display the man page nice.

-use the PAGER variable to display the man page.

-use envrionment variables to control connection to the database.

-when getting multiple matches on the name (could happen): do not display the manual page but instead display option (with numerical index with them) and let the user choose which one he wants.
