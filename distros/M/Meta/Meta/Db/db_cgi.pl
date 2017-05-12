#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Db::Def qw();
use CGI qw();

my($def_file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_modu("def_file","which definition file to use ?","xmlx/def/qbopt.xml",\$def_file);
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($c)=CGI->new();
print $c->header();
print $c->start_html();
# load the def and print it.
my($def)=Meta::Db::Def->new_modu($def_file);
print $def->printc($c);
print $c->end_html();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

db_cgi.pl - display dbdef object using CGI methods.

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

	MANIFEST: db_cgi.pl
	PROJECT: meta
	VERSION: 0.05

=head1 SYNOPSIS

	db_cgi.pl [options]

=head1 DESCRIPTION

This program will load a def object from an XML file and will display it
using CGI methods. This is fit to be run inside a browser.

The idea is to let the user see the database definition in the most clearest
form.

If you want to embed such a display in a larger system then just have a look
at the modules used by this module since the script itself doesnt do much.

=head1 OPTIONS

=over 4

=item B<def_file> (type: modu, default: xmlx/def/qbopt.xml)

which definition file to use ?

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

	0.00 MV web site development
	0.01 MV web site automation
	0.02 MV SEE ALSO section fix
	0.03 MV move tests to modules
	0.04 MV teachers project
	0.05 MV md5 issues

=head1 SEE ALSO

CGI(3), Meta::Db::Def(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
