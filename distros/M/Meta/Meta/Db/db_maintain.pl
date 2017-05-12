#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Db::Def qw();
use Meta::Db::Connections qw();
use Meta::Db::Dbi qw();
 
my($def_file,$connections_file,$name,$con_name);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("def_file","which definition file to use ?","xmlx/def/contacts.xml",\$def_file);
$opts->def_modu("connections_file","which connections file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("name","which database name to use ?",undef,\$name);
$opts->def_stri("con_name","which connection name to use ?",undef,\$con_name);
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
#do sanity checks here
$dbi->disconnect();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

db_maintain.pl - perform periodic database maintainance.

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

	MANIFEST: db_maintain.pl
	PROJECT: meta
	VERSION: 0.09

=head1 SYNOPSIS

	db_maintain.pl [options]

=head1 DESCRIPTION

This program performs periodic maintainance on a database. Different
database servers need different periodic maintainance (some don't
need any, some need it via SQL, some need it via cmd line). This
script will accomplish this via the single interface/different
drivers paradigm.

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

=item B<def_file> (type: modu, default: xmlx/def/contacts.xml)

which definition file to use ?

=item B<connections_file> (type: modu, default: xmlx/connections/connections.xml)

which connections file to use ?

=item B<name> (type: stri, default: )

which database name to use ?

=item B<con_name> (type: stri, default: )

which connection name to use ?

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

	0.00 MV more thumbnail code
	0.01 MV thumbnail user interface
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV improve the movie db xml
	0.05 MV web site automation
	0.06 MV SEE ALSO section fix
	0.07 MV move tests to modules
	0.08 MV teachers project
	0.09 MV md5 issues

=head1 SEE ALSO

Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Def(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
