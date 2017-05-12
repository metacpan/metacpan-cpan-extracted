#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Gtk qw();
use Gtk::Gdk::ImlibImage qw();
use Image::Magick qw();
use Meta::Utils::Output qw();

my($col_size,$col_sizes);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("col_size","should I find image size ?",1,\$col_size);
$opts->def_bool("col_sizes","should I find image sizes ?",0,\$col_sizes);
$opts->set_free_allo(1);
$opts->set_free_stri("[files]");
$opts->set_free_mini(1);
$opts->set_free_noli(1);
$opts->analyze(\@ARGV);

my($pic_window)=undef;# init for no value
my($pix)=undef;# init for no value

sub quit($) {
	my($window)=@_;
	Gtk->main_quit();
}

my($counter)=0;

sub load_handler($$$) {
	my($list,$prog_window,$bar)=@_;
#	Meta::Utils::Output::print("in here with counter [".$counter."]\n");
	if($counter>$#ARGV) {
#		Meta::Utils::Output::print("in here with counter [".$counter."]\n");
		$prog_window->hide();
		return(0);
	} else {
		my($curr)=$ARGV[$counter];
		load_single($list,$curr);
		$bar->update($counter/$#ARGV);
#		Gtk->idle_add(\&load_handler,$list,$prog_window,$bar);
		$counter++;
		return(1);
	}
}

sub select_row($$$$) {
#	Meta::Utils::Output::print("params are [".join(",",@_)."]\n");
	my($widget,$row,$column,$event)=@_;
#	Meta::Utils::Output::print("widget [".$widget."]\n");
#	Meta::Utils::Output::print("row [".$row."]\n");
#	Meta::Utils::Output::print("column [".$column."]\n");
#	Meta::Utils::Output::print("event [".$event."]\n");
#	Meta::Utils::Output::print("pix [".$pix."]\n");
#	Meta::Utils::Output::print("pic_window [".$pic_window."]\n");
	my($file)=$widget->get_text($row,0);
#	Meta::Utils::Output::print("trying to load [".$file."]\n");
	my($pixi)=Gtk::Gdk::ImlibImage->load_file_to_pixmap($file);
	if(!$pixi) {
		throw Meta::Error::Simple("unable to load file [".$file."]");
	}
	if(!defined($pic_window)) {
#		Meta::Utils::Output::print("in here\n");
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
#	Meta::Utils::Output::print("widget [".$widget."]\n");
#	Meta::Utils::Output::print("row [".$row."]\n");
#	Meta::Utils::Output::print("column [".$column."]\n");
#	Meta::Utils::Output::print("event [".$event."]\n");
#	Meta::Utils::Output::print("pix [".$pix."]\n");
#	Meta::Utils::Output::print("pic_window [".$pic_window."]\n");
#	$pic_window->hide();
}

sub load_single($$) {
	my($list,$name)=@_;
	if(!-f $name) {
		Meta::Utils::Output::print("error: [".$name."] is not a file\n");
		return;
	}
	my(@params);
	push(@params,$name);
	if($col_size) {
		my($size)=(CORE::stat($name))[7];
		push(@params,$size);
	}
	if($col_sizes) {
		my($image)=Image::Magick->new();
		my($ret)=$image->Read($name);
		if($ret) {
			throw Meta::Error::Simple("unable to read image [".$name."]");
		} else {
			my($x_size,$y_size)=$image->Get('height','width');
			push(@params,$x_size,$y_size);
		}
	}
	$list->append(@params);
}

Gtk->init();
Gtk::Gdk::ImlibImage->init();

my($window)=Gtk::Window->new("toplevel");
$window->signal_connect("destroy",\&quit);

my($scrolled)=Gtk::ScrolledWindow->new(undef,undef);
$scrolled->set_policy('always','always');
$window->add($scrolled);

my($prog_window)=Gtk::Window->new();
my($bar)=Gtk::ProgressBar->new();
$prog_window->add($bar);
$prog_window->show_all();

my($col_num)=1;
if($col_size) {
	$col_num++;
}
if($col_sizes) {
	$col_num+=2;
}
my($list)=Gtk::CList->new($col_num);
$list->set_auto_sort(1);
$list->column_titles_show();
$list->set_column_title(0,"Name");
$list->signal_connect("select_row",\&select_row);
$list->signal_connect("unselect_row",\&unselect_row);
my($c_counter)=1;
if($col_size) {
	$list->set_column_title($c_counter,"Byte Size");
	$c_counter++;
}
if($col_sizes) {
	$list->set_column_title($c_counter,"X Size");
	$c_counter++;
	$list->set_column_title($c_counter,"Y Size");
	$c_counter++;
}
for(my($i)=0;$i<$col_num;$i++) {
	$list->set_column_auto_resize($i,1);
}
$scrolled->add($list);
$window->show_all();

Gtk->idle_add(\&load_handler,$list,$prog_window,$bar);
Gtk->main();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

pics_multi_view.pl - view multiple image files.

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

	MANIFEST: pics_multi_view.pl
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	pics_multi_view.pl [options]

=head1 DESCRIPTION

This is a simple multiple image viewer using Gtk, Gdk, ImageImlib.

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

=item B<col_size> (type: bool, default: 1)

should I find image size ?

=item B<col_sizes> (type: bool, default: 0)

should I find image sizes ?

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

	0.00 MV books XML into database
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV thumbnail user interface
	0.05 MV more thumbnail issues
	0.06 MV website construction
	0.07 MV improve the movie db xml
	0.08 MV web site automation
	0.09 MV SEE ALSO section fix
	0.10 MV move tests to modules
	0.11 MV md5 issues

=head1 SEE ALSO

Gtk(3), Gtk::Gdk::ImlibImage(3), Image::Magick(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-enable to resize or not to resize with each new image

-enable to move or not to move with each new image.

-how about the scroll bars on the main list - do we need them that way ?

-if you kill the picture window then program gets broken.
