#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Db::Console::Console qw();
use Meta::Utils::Output qw();
use Meta::Template::Sub qw();

my($prompt,$startup,$startup_file,$history,$history_file,$verbose);
my($connections,$connection_name,$def);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_stri("opt_prompt","what prompt to use ?","XQL# ",\$prompt);
$opts->def_bool("opt_startup","use startup file ?",1,\$startup);
$opts->def_stri("opt_startup_file","what startup file ?","[% home_dir %]/.db_console.rc",\$startup_file);
$opts->def_bool("opt_history","use history ?",1,\$history);
$opts->def_stri("opt_history_file","what history file to use ?","[% home_dir %]/.db_console.hist",\$history_file);
$opts->def_bool("opt_verbose","be verbose ?",1,\$verbose);

$opts->def_modu("connections","what connections file ?","xmlx/connections/connections.xml",\$connections);
$opts->def_stri("connection_name","what connections name ?",undef,\$connection_name);
$opts->def_modu("def","what definitions file ?","xmlx/def/movie.xml",\$def);

$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$prompt=Meta::Template::Sub::interpolate($prompt);
$startup_file=Meta::Template::Sub::interpolate($startup_file);
$history_file=Meta::Template::Sub::interpolate($history_file);

my($shell)=Meta::Db::Console::Console->new();

$shell->set_prompt($prompt);
$shell->set_startup($startup);
$shell->set_startup_file($startup_file);
$shell->set_history($history);
$shell->set_history_file($history_file);
$shell->set_verbose($verbose);

$shell->set_connections($connections);
$shell->set_connection_name($connection_name);
$shell->set_def($def);

$shell->run();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

db_console.pl - run a DBI/DBD console.

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

	MANIFEST: db_console.pl
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	db_console.pl [options]

=head1 DESCRIPTION

This perl program runs a DBI/DBD console on your terminal using DBI/DBD
connection.

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

=item B<opt_prompt> (type: stri, default: XQL# )

what prompt to use ?

=item B<opt_startup> (type: bool, default: 1)

use startup file ?

=item B<opt_startup_file> (type: stri, default: [% home_dir %]/.db_console.rc)

what startup file ?

=item B<opt_history> (type: bool, default: 1)

use history ?

=item B<opt_history_file> (type: stri, default: [% home_dir %]/.db_console.hist)

what history file to use ?

=item B<opt_verbose> (type: bool, default: 1)

be verbose ?

=item B<connections> (type: modu, default: xmlx/connections/connections.xml)

what connections file ?

=item B<connection_name> (type: stri, default: )

what connections name ?

=item B<def> (type: modu, default: xmlx/def/movie.xml)

what definitions file ?

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

	0.00 MV xml data sets
	0.01 MV perl packaging
	0.02 MV license issues
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV improve the movie db xml
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV move tests to modules
	0.13 MV teachers project
	0.14 MV md5 issues

=head1 SEE ALSO

Meta::Db::Console::Console(3), Meta::Template::Sub(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-make the console not fly on error whenever there is an error in the SQL
	syntax.
