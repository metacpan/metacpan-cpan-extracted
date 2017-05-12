#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Db::Dbi qw();
use Meta::Db::Def qw();
use Meta::Cgi::SqlTable qw();

my($connections_file,$def_file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->def_modu("connections_file","which connections file","xmlx/connections/connections.xml",\$connections_file);
$opts->def_modu("def_file","which definition file","xmlx/def/dbman.xml",\$def_file);
$opts->analyze(\@ARGV);

my($def)=Meta::Db::Def->new_modu($def_file);

my($dbi)=Meta::Db::Dbi->new();
$dbi->Meta::Db::Dbi::connect_xml($connections_file->get_abs_path(),undef,"dbman");
my($stat)="select name,description from section";
my($p)=Meta::Cgi::SqlTable->new();
print $p->header();
print $p->start_html();
print $p->sql_table($stat,$def,$dbi,30);
print $p->end_html();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

dbman_cgi.pl - web based interface to a dbman database.

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

	MANIFEST: dbman_cgi.pl
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	dbman_cgi.pl [options]

=head1 DESCRIPTION

This program will present a CGI type interface to the dbman database.
It will show which sections and manual pages are available and allow
yo to search for a specific entry and view it.

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

which connections file

=item B<def_file> (type: modu, default: xmlx/def/dbman.xml)

which definition file

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

	0.00 MV download scripts
	0.01 MV teachers project
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Cgi::SqlTable(3), Meta::Db::Dbi(3), Meta::Db::Def(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
