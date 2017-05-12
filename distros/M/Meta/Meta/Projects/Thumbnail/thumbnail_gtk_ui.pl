#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Gtk qw();
use Gtk::Gdk qw();
use Gtk::Gdk::ImlibImage qw();
use Meta::Utils::Output qw();
use Meta::Db::Dbi qw();
use Meta::Db::Def qw();
use Meta::Db::Connections qw();
use Meta::Widget::Gtk::SqlList qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::File qw();
use Meta::Utils::File::Remove qw();
use Meta::Development::Module qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($pic_window,$pix);

sub db_connect() {
#	Meta::Utils::Output::print("in db_connect\n");
}
sub db_disconnect() {
#	Meta::Utils::Output::print("in db_disconnect\n");
}
sub db_quit($) {
	my($widget)=@_;
#	Meta::Utils::Output::print("in db_quit\n");
	Gtk->main_quit();
}
sub import_single() {
#	Meta::Utils::Output::print("in import_single\n");
}
sub import_directory() {
#	Meta::Utils::Output::print("in import_directory\n");
}
sub help_about() {
#	Meta::Utils::Output::print("in help_about\n");
}
sub select_row($$$$) {
#	Meta::Utils::Output::print("params are [".join(",",@_)."]\n");
	my($widget,$row,$column,$event)=@_;
	my($id)=$widget->get_text($row,0);
	my($res)=get_dbi()->execute_arrayref("SELECT thumb from item where id=".$id);
	my($data)=$res->[0]->[0];
	my($file)=Meta::Utils::Utils::get_temp_file();
	Meta::Utils::File::File::save($file,$data);
	my($pixi)=Gtk::Gdk::ImlibImage->load_file_to_pixmap($file);
	Meta::Utils::File::Remove::rm($file);
	#The next line doesnt work since it doesnt generate a pixmap
	#my($pixi)=Gtk::Gdk::ImlibImage->load_image($file);
	#This is the direct way which dumps core
	#my($pixi)=Gtk::Gdk::ImlibImage->data_to_pixmap($data);
	if(!$pixi) {
		throw Meta::Error::Simple("unable to create pixmap");
	}
	if(!defined($pic_window)) {
	#	Meta::Utils::Output::print("in here\n");
		$pic_window=Gtk::Window->new();
		if(!$pic_window) {
			throw Meta::Error::Simple("unable to build pic_window");
		}
		$pix=Gtk::Pixmap->new($pixi,undef);
		if(!$pix) {
			throw Meta::Error::Simple("unable to build pixmap [".$pix."]");
		}
		$pic_window->add($pix);
	} else {
		$pix->set($pixi,undef);
	}
	$pic_window->show_all();
}
sub unselect_row($$$$) {
	my($widget,$row,$column,$event)=@_;
}

Gtk->init();

my($window)=Gtk::Window->new();
$window->signal_connect("destroy",\&db_quit);

my($module)=Meta::Development::Module->new_name("xmlx/def/thumbnail.xml");
my($def)=Meta::Db::Def->new_modu($module);
 
my($cmodule)=Meta::Development::Module->new_name("xmlx/connections/connections.xml");
my($connections)=Meta::Db::Connections->new_modu($cmodule);
my($connection)=$connections->get_def_con();

my($dbi)=Meta::Db::Dbi->new();
$dbi->connect_def($connection,$def);

sub get_dbi() {
	return($dbi);
}

Gtk->init();
my($window)=Gtk::Window->new();
$window->signal_connect("destroy",\&db_quit);
my($listwin)=Meta::Widget::Gtk::SqlList->new_statement($dbi,"SELECT id,name,description,x,y FROM item",$def);
$listwin->signal_connect("select_row",\&select_row);
$listwin->signal_connect("unselect_row",\&unselect_row);
$window->add($listwin);
$window->show_all();
Gtk->main();

$dbi->disconnect();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

thumbnail_gtk_ui.pl - user interface for the Thumbnail project.

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

	MANIFEST: thumbnail_gtk_ui.pl
	PROJECT: meta
	VERSION: 0.10

=head1 SYNOPSIS

	thumbnail_gtk_ui.pl [options]

=head1 DESCRIPTION

This is a user interface for the Thumbnail project. It enables you to see all
the pictures you have in your database and to insert new ones.
Dummy comment.

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

	0.00 MV thumbnail project basics
	0.01 MV thumbnail user interface
	0.02 MV import tests
	0.03 MV more thumbnail issues
	0.04 MV website construction
	0.05 MV improve the movie db xml
	0.06 MV web site automation
	0.07 MV SEE ALSO section fix
	0.08 MV move tests to modules
	0.09 MV teachers project
	0.10 MV md5 issues

=head1 SEE ALSO

Gtk(3), Gtk::Gdk(3), Gtk::Gdk::ImlibImage(3), Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Def(3), Meta::Development::Module(3), Meta::Utils::File::File(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Utils(3), Meta::Widget::Gtk::SqlList(3), strict(3)

=head1 TODO

-is there no better way to turn data into a pixmap than to save it in a file ?!? The commented way with creating the image from data dumps core...:(
