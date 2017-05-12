#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Cgi::SqlTable qw();
use Meta::Db::Dbi qw();
use Meta::Db::Def qw();
use Meta::Utils::Output qw();

my($con_modu,$con_name,$db_name,$def_modu,$uid,$limit);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("con_modu","file with connection info","xmlx/connections/connections.xml",\$con_modu);
$opts->def_stri("con_name","connection name",undef,\$con_name);
$opts->def_stri("db_name","db name","movie",\$db_name);
$opts->def_modu("def_modu","database definition file","xmlx/def/movie.xml",\$def_modu);
$opts->def_stri("uid","user id",1,\$uid);
$opts->def_stri("limit","limit on number of entries",30,\$limit);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($def)=Meta::Db::Def->new_modu($def_modu);
my($dbi)=Meta::Db::Dbi->new();
$dbi->Meta::Db::Dbi::connect_xml($con_modu->get_abs_path(),$con_name,$db_name);
#my($stat)="select id,name,description,release_date from movie order by name";
my($stat)="select movie.id,movie.name,view.date from movie,view where view.movie=movie.id order by view.date desc";
#my($columns)=[ "movie.id","movie.name","view.date" ];
#Meta::Utils::Output::print("columns is [".$columns."]\n");
#my($stat)="select name,date from movie,view where view.movie=movie.id order by date desc";
#my($stat)="select name,date from movie INNER JOIN view ON (view.movie=movie.id) order by date desc";
#Meta::Utils::Output::print("stat is [".$stat."]\n");
my($p)=Meta::Cgi::SqlTable->new();
print $p->header();
print $p->start_html(
	-title=>"Mark Veltzer's home page",
	-style=>{'src'=>'http://www.veltzer.org/cssx/projects/Website/main.css'},
);
print $p->sql_table($stat,$def,$dbi,$limit);
#print $p->core_code($stat,$def,$dbi,$limit,$columns);
print $p->end_html();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

movie_cgi.pl - Perl/CGI interface to the movie database.

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

	MANIFEST: movie_cgi.pl
	PROJECT: meta
	VERSION: 0.08

=head1 SYNOPSIS

	movie_cgi.pl [options]

=head1 DESCRIPTION

This is a CGI script which enables you to browse my movie database.
If you want to embed this as part of a larger framework then please
have a look at the modules that this is using since in itself
it does almost nothing.

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

=item B<con_modu> (type: modu, default: xmlx/connections/connections.xml)

file with connection info

=item B<con_name> (type: stri, default: )

connection name

=item B<db_name> (type: stri, default: movie)

db name

=item B<def_modu> (type: modu, default: xmlx/def/movie.xml)

database definition file

=item B<uid> (type: stri, default: 1)

user id

=item B<limit> (type: stri, default: 30)

limit on number of entries

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

	0.00 MV web site development
	0.01 MV web site automation
	0.02 MV SEE ALSO section fix
	0.03 MV put all tests in modules
	0.04 MV move tests to modules
	0.05 MV download scripts
	0.06 MV bring movie data
	0.07 MV weblog issues
	0.08 MV md5 issues

=head1 SEE ALSO

Meta::Cgi::SqlTable(3), Meta::Db::Dbi(3), Meta::Db::Def(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
