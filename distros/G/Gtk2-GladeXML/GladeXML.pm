#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/GladeXML.pm,v 1.32 2008/09/07 20:10:48 kaffeetisch Exp $
#
# Based strongly on gtk-perl's GladeXML
#

package Gtk2::GladeXML;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '1.007';

sub import {
	my $class = shift;
	$class->VERSION (@_);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gtk2::GladeXML->bootstrap ($VERSION);

sub _do_connect {
	my ($object, $signal_name, $signal_data, $connect_object,
	    $after, $handler) = @_;

	my $func = $after ? 'signal_connect_after' : 'signal_connect';
	# we get connect_object when we're supposed to call
	# signal_connect_object, which ensures that the data (an object)
	# lives as long as the signal is connected.  the bindings take
	# care of that for us in all cases, so we only have signal_connect.
	# if we get a connect_object, just use that instead of signal_data.
	$object->$func($signal_name => $handler,
		       $connect_object ? $connect_object : $signal_data);
}

# XXX used only by handler_connect, which appears to be derelict code
sub _connect_helper
{
	my $handler_name = shift;
	my $object = shift;
	my $signal_name = shift;
	my $signal_data = shift;
	my $connect_object = shift;
	my $after = shift;
	my $handler = shift;

	_do_connect ($object, $signal_name, $signal_data, $connect_object,
		     $after, $handler);
}

sub _autoconnect_helper
{
	my $handler_name = shift;
	my $object = shift;
	my $signal_name = shift;
	my $signal_data = shift;
	my $connect_object = shift;
	my $after = shift;
	my $package = shift;

	no strict qw/refs/;

	my $handler = $handler_name;
	if (ref $package) {
		$handler = sub { $package->$handler_name(@_) };
	} else {
		$handler = $package.'::'.$handler_name
			if( $package && $handler !~ /::/ );
	}

	_do_connect ($object, $signal_name, $signal_data, $connect_object,
		     $after, $handler);
}

# XXX unused code?
sub handler_connect {
	my ($self, $hname, @handler) = @_;

	$self->signal_connect_full($hname, \&_connect_helper, @handler);
}

sub signal_autoconnect_from_package
{
	my $self = shift;
	my $package = shift;

	($package, undef, undef) = caller() unless $package;
	$self->signal_autoconnect(\&_autoconnect_helper, $package);
}

sub signal_autoconnect_all {
	my ($self, %handler) = @_;
        $self->signal_autoconnect(sub {
           my $handler_name = shift;
           my $object = shift;
           my $signal_name = shift;
           my $signal_data = shift;
           my $connect_object = shift;
           my $after = shift;

           my $handler = $handler{$handler_name}
              or return;

	   _do_connect ($object, $signal_name, $signal_data, $connect_object,
			$after, $handler);
        });
}

1;
__END__

=head1 NAME

Gtk2::GladeXML - Create user interfaces directly from Glade XML files.

=head1 SYNOPSIS

  # for a pure gtk+ glade project
  use Gtk2 -init;
  use Gtk2::GladeXML;
  $gladexml = Gtk2::GladeXML->new('example.glade');
  $gladexml->signal_autoconnect_from_package('main');
  $quitbtn = $gladexml->get_widget('Quit'); 
  Gtk2->main;

  # for glade files using gnome widgets, you must initialize Gnome2
  # before loading the glade file.
  use Gnome2;
  use Gtk2::GladeXML;
  # this call also initializes gtk+ for us
  Gnome2::Program->init ($appname, $version);
  $gladexml = Gtk2::GladeXML->new('gnomeapp.glade');
  Gtk2->main;

=head1 ABSTRACT

Gtk2::GladeXML allows Perl programmers to use libglade, a C library which
generates graphical user interfaces directly from the XML output of the
Glade user interface designer.

=head1 DESCRIPTION

Glade is a free user interface builder for GTK+ and GNOME.  After designing
a user interface with glade-2 the layout and configuration are saved in an
XML file.  libglade is a library which knows how to build and hook up the
user interface described in the Glade XML file at application run time.

This extension module binds libglade to Perl so you can create and manipulate
user interfaces in Perl code in conjunction with Gtk2 and even Gnome2.  Better
yet you can load a file's contents into a PERL scalar do a few magical regular
expressions to customize things and the load up the app. It doesn't get any
easier. 

=head1 FUNCTIONS

=over

=item $gladexml = Gtk2::GladeXML->new(GLADE_FILE, [ROOT, DOMAIN])

Create a new GladeXML object by loading the data in GLADE_FILE.  ROOT is an
optional parameter that specifies a point (widget node) from which to start
building.  DOMAIN is an optional parameter that specifies the translation
domain for the xml file.

=item $gladexml = Gtk2::GladeXML->new_from_buffer(BUFFER, [ROOT, DOMAIN])

Create a new GladeXML object from the scalar string contained in BUFFER.  ROOT
is an optional parameter that specifies a point (widget node) from which to
start building.  DOMAIN is an optional parameter that specifies the translation
domain for the xml file.

=item $widget = $gladexml->get_widget(NAME)

Return the widget created by the XML file with NAME or undef if no such name
exists.

=item $gladexml->signal_autoconnect($callback[, $userdata])

Iterates over all signals and calls the given callback:

   sub example_cb {
      my ($name, $widget, $signal, $signal_data, $connect, $after, $userdata) = @_;
   }

The following two convenience methods use this to provide a more
convenient interface.

=item $gladexml->signal_autoconnect_from_package([PACKAGE or OBJECT])

Sets up the signal handling callbacks as specified in the glade XML data.

The argument to this method can be a Perl package name or an object.  If a
package name is used, each handler named in the Glade XML data will be called
as a subroutine in the named package.  If an object is supplied each handler
will be called as a method of the object.  If no argument is supplied, the name
of the calling package will be used.  A user data argument cannot be supplied
however this is seldom necessary when an object is used.

The names of the subroutines or methods must exactly match the handler name in
the XML data.  It is worth noting that callbacks you get for free in c such as
gtk_main_quit will not exist in perl and must always be defined, for example:

  sub gtk_main_quit
  {
  	Gtk2->main_quit;
  }

Otherwise behavior should be exactly as expected with the use of libglade
from a C application.

=item $gladexml->signal_autoconnect_all (name => handler, ...)

Iterates over all named signals and tries to connect them to the handlers
specified as arguments (handlers not given as argument are being
ignored). This is very handy when implementing your own widgets, where you
can't use global callbacks.


=item $widget = Gtk2::Glade->set_custom_handler ($callback[, $userdata])

This method tells Gtk2::GladeXML how to create handlers for custom widgets.

You can specify a "custom" widget in a glade file, which allows you to
include in your interface widgets that Glade itself doesn't know how to
create.  To tell libglade how to instantiate such widgets, you specify a
"custom widget handler", a function which returns a Gtk2:Widget object
for that custom widget.  This handler needs to be installed sometime
before the instantiation of your Gtk2::GladeXML object, by calling
C<set_custom_handler>.

    my $widget = Gtk2::Glade->set_custom_handler( \&my_handler );
    my $gladexml = Gtk2::GladeXML->new( 'MyApp.glade' );

The prototype for the custom handler is:

    sub my_handler {
        my ($xml,       # The Gtk2::GladeXML object
            # the remaining arguments are as specified in the glade file:
            $func_name,	# The function name
            $name,      # the name of the widget to be created
            $str1,      # the string1 property
            $str2,      # the string2 property
            $int1,      # the int1 property
            $int2,      # the int2 property
            $userdata   # the data passed to set_custom_handler
	   ) = @_;
	...
	return $widget; # a new Gtk2::Widget; you must call ->show on it.
    }

=back

=head1 FAQ

=over

=item Where is the option to generate Perl source in Glade?

Glade itself only creates the XML description, and relies on extra converter
programs to write source code; only a few converters are widely popular.

In general, however, you don't want to generate source code for a variety of
reasons, mostly to do with maintainability.  This message on the glade-devel
list explains it best:

http://lists.ximian.com/archives/public/glade-devel/2003-February/000015.html

=item Why does my program crash on startup?

Does your glade file use Gnome widgets?  If so, you must initialize Gnome
manually; libglade can knows how to create gnome widgets, but can't know how
you want to initialize the app.  This is usually sufficient:

  use Gnome2;
  Gnome2::Program->init ($app_name, $version_string);

Libglade's API reference mentions this:
http://developer.gnome.org/doc/API/2.0/libglade/libglade-modules.html

=back

=head1 SEE ALSO

L<perl>(1), L<Glib>(3pm), L<Gtk2>(3pm)

The Libglade Reference Manual at
L<http://developer.gnome.org/doc/API/2.0/libglade/>

An introductory article that originally appeared in The Perl Review:
L<http://live.gnome.org/GTK2-Perl/GladeXML/Tutorial>

=head1 AUTHOR

Ross McFarland <rwmcfa1 at neces dot com>, Marc Lehmann <pcg@goof.com>,
muppet <scott at asofyet dot org>.  Bruce Alderson provided several examples.
Grant McClean <grant at mclean dot net dot nz> and Marco Antonio Manzo
<amnesiac at perl dot org dot mx> contributed documentation.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2006 by the gtk2-perl team.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.

=cut
