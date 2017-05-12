#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Db::Def qw();
use Meta::Db::Connections qw();
use Meta::Db::Dbi qw();
use Meta::Xml::Parsers::Movie qw();
use Meta::Sql::Stats qw();
use Meta::Db::Info qw();

my($def_file,$connections_file,$name,$con_name,$clean,$data_file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("def_file","what def XML file to use ?","xmlx/def/movie.xml",\$def_file);
$opts->def_modu("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("name","name of the database to use ?",undef,\$name);
$opts->def_stri("con_name","name of the connection to use ?",undef,\$con_name);
$opts->def_bool("clean","clean the database before import ?",1,\$clean);
$opts->def_devf("data_file","what data XML file to use ?","xmlx/movie/movie.xml",\$data_file);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($def)=Meta::Db::Def->new_modu($def_file);
if(!defined($name)) {
	$name=$def->get_name();
}
my($connections)=Meta::Db::Connections->new_modu($connections_file);
my($connection);
if(defined($con_name)) {
	$connection=$connections->get($con_name);
} else {
	$connection=$connections->get_def_con();
}
my($dbi)=Meta::Db::Dbi->new();
$dbi->connect_name($connection,$name);

$dbi->begin_work();

my($info)=Meta::Db::Info->new();
$info->set_name($name);
$info->set_type($connection->get_type());

if($clean) {
	my($stats)=Meta::Sql::Stats->new();
	$def->getsql_clean($stats,$info);
	$dbi->execute($stats,$connection,$info);
}

my($parser)=Meta::Xml::Parsers::Movie->new();
$parser->set_dbi($dbi);
$parser->parsefile(Meta::Baseline::Aegis::which($data_file));

$dbi->commit();

$dbi->disconnect();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

movie_import.pl - import movie data from an XML file.

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

	MANIFEST: movie_import.pl
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	movie_import.pl [options]

=head1 DESCRIPTION

This script will read the data stored in a Movie DTD XML file and will
store it in a movie DEF database. Mind you that the script cleans
the database first.

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

=item B<def_file> (type: modu, default: xmlx/def/movie.xml)

what def XML file to use ?

=item B<connections_file> (type: modu, default: xmlx/connections/connections.xml)

what connections XML file to use ?

=item B<name> (type: stri, default: )

name of the database to use ?

=item B<con_name> (type: stri, default: )

name of the connection to use ?

=item B<clean> (type: bool, default: 1)

clean the database before import ?

=item B<data_file> (type: devf, default: xmlx/movie/movie.xml)

what data XML file to use ?

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

	0.00 MV more movies
	0.01 MV fix database problems
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV more thumbnail code
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

Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Def(3), Meta::Db::Info(3), Meta::Sql::Stats(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), Meta::Xml::Parsers::Movie(3), strict(3)

=head1 TODO

Nothing.
