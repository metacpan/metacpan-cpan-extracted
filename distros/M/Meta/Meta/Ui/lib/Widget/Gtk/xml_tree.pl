#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Widget::Gtk::XmlTree qw();
use Gtk qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Gtk->init();
my($window)=Gtk::Window->new();
$window->set_usize(500,500);
$window->set_title("XmlTree demo");
$window->signal_connect("delete_event",sub {Gtk->exit(0);});
my($scrolled)=Gtk::ScrolledWindow->new(undef,undef);
$scrolled->set_policy('always','always');
$scrolled->show();
$window->add($scrolled);
my($widget)=Meta::Widget::Gtk::XmlTree->new();
$widget->set_deve_file("xmlx/movie/movie.xml");
$widget->show();
$scrolled->add_with_viewport($widget);
$window->show();
Gtk->main();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

xml_tree.pl - demo the XmlTree widget.

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

	MANIFEST: xml_tree.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	xml_tree.pl [options]

=head1 DESCRIPTION

This program will demo the XmlTree widget which is derived from the general
Gtk::CTree widget and presents an XML::DOM object.

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

	0.00 MV bring movie data
	0.01 MV md5 issues

=head1 SEE ALSO

Gtk(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), Meta::Widget::Gtk::XmlTree(3), strict(3)

=head1 TODO

Nothing.
