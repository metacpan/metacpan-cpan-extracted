#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Db::Def qw();
use Meta::Db::Connections qw();
use Meta::Db::Dbi qw();
use Meta::Db::Info qw();
use Meta::Sql::Stats qw();
use Error qw(:try);

my($def_file,$connections_file,$name,$con_name,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("def_file","which definition file to use ?",undef,\$def_file);
$opts->def_modu("connections_file","which connections file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("name","which database name ?",undef,\$name);
$opts->def_stri("con_name","which connection name ?",undef,\$con_name);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
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
# we are not connecting directly to the db or else we can't drop it!!!
$dbi->connect($connection);

my($info)=Meta::Db::Info->new();
$info->set_name($def->get_name());
$info->set_type($connection->get_type());
my($drop_stats)=Meta::Sql::Stats->new();
try {
	$def->getsql_drop($drop_stats,$info,1);
	$dbi->execute($drop_stats,$connection,$info);
}
catch Error::Simple with {
	Meta::Utils::Output::verbose($verbose,"Not dropping database since it doesnt exist.\n");
};
my($stats)=Meta::Sql::Stats->new();
$def->getsql_create($stats,$info);
#$stats->print(Meta::Utils::Output::get_file());
$dbi->execute($stats,$connection,$info);

$dbi->disconnect();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

db_create.pl - create a database according to a definition.

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

	MANIFEST: db_create.pl
	PROJECT: meta
	VERSION: 0.21

=head1 SYNOPSIS

	db_create.pl

=head1 DESCRIPTION

This will create a database for you.
You need to supply three things for this:
0. Def object which describes the database internal structure.
1. Connections data to connect to the database.
2. Which of the connections to use to connect.
3. Name under which the database will be created. 

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

=item B<def_file> (type: modu, default: )

which definition file to use ?

=item B<connections_file> (type: modu, default: xmlx/connections/connections.xml)

which connections file to use ?

=item B<name> (type: stri, default: )

which database name ?

=item B<con_name> (type: stri, default: )

which connection name ?

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

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

	0.00 MV more data sets
	0.01 MV perl packaging
	0.02 MV license issues
	0.03 MV more movies
	0.04 MV fix database problems
	0.05 MV more database issues
	0.06 MV md5 project
	0.07 MV database
	0.08 MV perl module versions in files
	0.09 MV movie stuff
	0.10 MV thumbnail project basics
	0.11 MV more thumbnail stuff
	0.12 MV thumbnail user interface
	0.13 MV dbman package creation
	0.14 MV more thumbnail issues
	0.15 MV website construction
	0.16 MV improve the movie db xml
	0.17 MV web site automation
	0.18 MV SEE ALSO section fix
	0.19 MV move tests to modules
	0.20 MV teachers project
	0.21 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Def(3), Meta::Db::Info(3), Meta::Sql::Stats(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-make this actually work.
