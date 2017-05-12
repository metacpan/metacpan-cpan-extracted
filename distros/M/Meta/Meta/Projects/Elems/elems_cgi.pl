#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Db::Dbi qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::System qw();
use CGI qw();
use Error qw(:try);

my($p)=CGI->new();
my($name)=$p->param('name');;

my($connections,$database);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_devf("connections","what XML/connections file to use","xmlx/connections/connections.xml",\$connections);
$opts->def_stri("database","what database to work on","elems",\$database);
$opts->set_standard();
$opts->set_free_allo(1);
$opts->set_free_stri("args");
$opts->analyze(\@ARGV);

$connections=Meta::Baseline::Aegis::which($connections);
my($dbi)=Meta::Db::Dbi->new();
$dbi->Meta::Db::Dbi::connect_xml($connections,$database);
my($stat)="SELECT content FROM elems WHERE name='".$name."'";
my($res)=$dbi->execute_arrayref($stat);
if($#$res!=0) {
	throw Meta::Error::Simple("could not get field from db");
}
my($content)=$res->[0][0];
print $p->header();
print $content;

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

elems_cgi.pl - provide CGI interface to the elems system.

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

	MANIFEST: elems_cgi.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	elems_cgi.pl [options]

=head1 DESCRIPTION

This script is your interface to the elems system. The elems system is
a web site management system which stores the web site in an RDMBS. This
script is the only script which need to be placed in your apache service
directory under a directory which has CGI capability and all traffic
needs to be directed to it with the argument name=[resource name].

=head1 OPTIONS

=over 4

=item B<connections> (type: devf, default: xmlx/connections/connections.xml)

what XML/connections file to use

=item B<database> (type: stri, default: elems)

what database to work on

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

	0.00 MV download scripts
	0.01 MV md5 issues

=head1 SEE ALSO

CGI(3), Error(3), Meta::Baseline::Aegis(3), Meta::Db::Dbi(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-whenever an error occurs dont just raise an error. Print some kind of error page.
