#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Gtk qw();
use Gtk::Gdk::ImlibImage qw();
use Meta::Baseline::Aegis qw();
use Meta::Error::Simple qw();

my($deve,$file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("development","is this a development file ?",1,\$deve);
$opts->def_stri("file","what is the file name ?","pngx/simul.png",\$file);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

sub quit($) {
	my($window)=@_;
	Gtk->main_quit();
}

Gtk->init();
Gtk::Gdk::ImlibImage->init();

my($window)=Gtk::Window->new("toplevel");
$window->signal_connect("destroy",\&quit);
if($deve) {
	$file=Meta::Baseline::Aegis::which($file);
}
my($pixi)=Gtk::Gdk::ImlibImage->load_file_to_pixmap($file);
if(!$pixi) {
	throw Meta::Error::Simple("unable to load file [".$file."]");
}
my($pix)=Gtk::Pixmap->new($pixi,undef);
if(!$pix) {
	throw Meta::Error::Simple("unable to build pixmap [".$pixi."]");
}
$window->add($pix);
#my($image)=Gtk::Gdk::ImlibImage->load_image($file);
#if(!$image) {
#	Meta::Utils::System::die("unable to load file [".$file."]");
#}
#my($image_widget)=Gtk::Image->new($image,undef);
#if(!$image_widget) {
#	Meta::Utils::System::die("unable to create image widget");
#}
#$window->add($image_widget);
$window->show_all();
Gtk->main();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

pics_single_view.pl - view a single image file.

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

	MANIFEST: pics_single_view.pl
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	pics_single_view.pl [options]

=head1 DESCRIPTION

This is a simple image viewer using Gtk, Gdk, ImageImlib.

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

=item B<development> (type: bool, default: 1)

is this a development file ?

=item B<file> (type: stri, default: pngx/simul.png)

what is the file name ?

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

Gtk(3), Gtk::Gdk::ImlibImage(3), Meta::Baseline::Aegis(3), Meta::Error::Simple(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
