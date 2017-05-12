#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Gnome qw();
 
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($name)="def editor";
my($vers)="0.1";

sub appl_dele() {
	Gtk->main_quit();
	return(0);
}

sub file_new() {
	Meta::Utils::Output::print("file new\n");
}

my($file_open_dialog);

sub file_open_destroy() {
}

sub file_open() {
	Meta::Utils::Output::print("file open\n");
	my($file_open_dialog)=Gtk::FileSelection->new("open def");
	$file_open_dialog->show();
}

sub file_close() {
	Meta::Utils::Output::print("file close\n");
}

sub file_save() {
	Meta::Utils::Output::print("file save\n");
}

sub file_save_as() {
	Meta::Utils::Output::print("file save_as\n");
}

sub file_exit() {
	Meta::Utils::Output::print("file exit\n");
}

Gnome->init($name,$vers);

my($appl)=Gnome::MDI->new("def editor","database definition editor");
#$appl->signal_connect("delete_event",\&appl_dele);

=begin COMMENT

	$appl->create_menus(
		{
			type=>'subtree',
			label=>'_File',
			subtree=> [
				{
					type=>'item',
					label=>'_New',
					pixmap_type=>'stock',
					pixmap_info=>'Menu_New',
					callback=>\&file_new,
				},
				{
					type=>'item',
					label=>'_Open...',
					pixmap_type=>'stock',
					pixmap_info=>'Menu_Open',
					callback=>\&file_open,
				},
				{
					type=>'item',
					label=>'_Close',
					pixmap_type=>'stock',
					pixmap_info=>'Menu_Close',
					callback=>\&file_close,
				},
				{
					type=>'separator'
				},
				{
					type=>'item',
					label=>'_Save',
					pixmap_type=>'stock',
					pixmap_info=>'Menu_Save',
					callback=>\&file_save,
				},
				{
					type=>'item',
					label=>'Save _As...',
					pixmap_type=>'stock',
					pixmap_info=>'Menu_Save As',
					callback=>\&file_save_as,
				},
				{
					type=>'separator'
				},
				{
					type=>'item',
					label=>'E_xit...',
					pixmap_type=>'stock',
					pixmap_info=>'Menu_Quit',
					callback=>\&file_exit,
				},
			]
		}
	);

=cut

#$appl->show_all();
#$appl->menu_template();
$appl->open_toplevel();
Gtk->main();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

db_edit_def.pl - database definition editor application.

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

	MANIFEST: db_edit_def.pl
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	db_edit_def.pl

=head1 DESCRIPTION

database definition editor application.

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

	0.00 MV more on data sets
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
	0.13 MV md5 issues

=head1 SEE ALSO

Gnome(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
