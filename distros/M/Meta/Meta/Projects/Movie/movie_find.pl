#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Db::Connections qw();
use Meta::Class::DBI qw();
use Meta::Projects::Movie::Person qw();

my($connections_file,$con_name,$name);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("con_name","what connection name ?",undef,\$con_name);
$opts->def_stri("name","what database name ?","movie",\$name);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($connections)=Meta::Db::Connections->new_modu($connections_file);
my($connection)=$connections->get_con_null($con_name);
Meta::Class::DBI::set_connection($connection,$name);

my($person)=Meta::Projects::Movie::Person->retrieve(7);
Meta::Utils::Output::print("firstname is [".$person->firstname()."]\n");

#my(@person)=Meta::Movie::Person->retrieve_all();
my(@person)=Meta::Projects::Movie::Person->search("surname","Allen");
for(my($i)=0;$i<=$#person;$i++) {
	my($curr)=$person[$i];
	Meta::Utils::Output::print("firstname is [".$curr->firstname()."]\n");
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

movie_find.pl - find a person in the movie db.

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

	MANIFEST: movie_find.pl
	PROJECT: meta
	VERSION: 0.08

=head1 SYNOPSIS

	movie_find.pl [options]

=head1 DESCRIPTION

Put your programs description here.

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

=item B<name> (type: stri, default: movie)

what database name ?

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

	0.00 MV import tests
	0.01 MV more thumbnail issues
	0.02 MV website construction
	0.03 MV improve the movie db xml
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV move tests to modules
	0.07 MV teachers project
	0.08 MV md5 issues

=head1 SEE ALSO

Meta::Class::DBI(3), Meta::Db::Connections(3), Meta::Projects::Movie::Person(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
