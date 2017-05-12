#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Gtk qw();
use Meta::Utils::Output qw();

my($verb);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","noisy or silent ?",1,\$verb);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

sub main_window_delete() {
	if($verb) {
		Meta::Utils::Output::print("event: main_window_delete\n");
	}
	Gtk->exit(0);
	return(0);
}

#my($preferences)=Gtk::Window->new();

my($app_name)="chess_ui";
Gtk->init();
my($main_window)=Gtk::Window->new("toplevel");
$main_window->signal_connect("delete_event",\&main_window_delete);
#my($main_toolbar)=Gtk::Toolbar->new();
#$main_toolbar->add("Database");
#$main_toolbar->add_item("Create");
#$main_toolbar->add_item("Destroy");
#$main_toolbar->add_item("Connect");
#$main_toolbar->add_item("Preferences");
$main_window->show();
Gtk->main();
Meta::Utils::System::exit_ok();

__END__

=head1 NAME

chess_ui.pl - manage a chess database.

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

	MANIFEST: chess_ui.pl
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	chess_ui.pl

=head1 DESCRIPTION

This application will allow you to manage your chess database.
The application will allow you to:
1. create the database on any database server.
2. insert data manually into the database.
3. remove data manually from the database.
4. sanity check the data in the database.
5. import data into the database from various formats.
6. export data from the database to various formats.

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

=item B<verbose> (type: bool, default: 1)

noisy or silent ?

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

	0.00 MV fix database problems
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV thumbnail project basics
	0.05 MV thumbnail user interface
	0.06 MV more thumbnail issues
	0.07 MV website construction
	0.08 MV improve the movie db xml
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV move tests to modules
	0.12 MV md5 issues

=head1 SEE ALSO

Gtk(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
