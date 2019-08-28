#
# Copyright (C) 2003-2013 by the gtk2-perl team (see the file AUTHORS for
# the full list)
#
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
# more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
#
# $Id$
#

package Gtk2;

# Gtk uses unicode strings; thus we require perl>=5.8.x,
# which is unicode internally.
use 5.008;
use strict;
use warnings;

use Glib;
use Pango;

# Backwards compatibility: create Gtk2::Pango aliases for everything in Pango
# that was originally in Gtk2::Pango.
{
  no strict 'refs';
  my @pango_keys = qw(
    AttrBackground:: AttrColor:: AttrFallback:: AttrFamily:: AttrFontDesc::
    AttrForeground:: AttrGravity:: AttrGravityHint:: Attribute:: AttrInt::
    AttrIterator:: AttrLanguage:: AttrLetterSpacing:: AttrList:: AttrRise::
    AttrScale:: AttrShape:: AttrSize:: AttrStretch:: AttrStrikethrough::
    AttrStrikethroughColor:: AttrString:: AttrStyle:: AttrUnderline::
    AttrUnderlineColor:: AttrVariant:: AttrWeight:: Cairo:: Color:: Context::
    Font:: FontDescription:: FontFace:: FontFamily:: FontMap:: FontMask::
    FontMetrics:: Fontset:: GlyphString:: Gravity:: Language:: Layout::
    LayoutIter:: LayoutLine:: Matrix:: Renderer:: Script:: ScriptIter::
    TabArray::

    extents_to_pixels find_base_dir parse_markup pixels scale scale_large
    scale_medium scale_small scale_x_large scale_x_small scale_xx_large
    scale_xx_small units_from_double units_to_double

    PANGO_PIXELS

    CHECK_VERSION GET_VERSION_INFO VERSION

    ISA
  );
  foreach my $key (@pango_keys) {
    # Avoid warnings about names that are used only once by checking for
    # definedness here.
    if (defined *{'Pango::' . $key}) {
      *{'Gtk2::Pango::' . $key} = *{'Pango::' . $key};
    }
  }
}

# if the gtk+ we've been compiled against is at 2.8.0 or newer or if pango is
# at 1.10.0 or newer, we need to import the Cairo module for the cairo glue in
# gtk+ and pango.
eval "use Cairo;";

use Exporter;
require DynaLoader;

our $VERSION = '1.24993';

our @ISA = qw(DynaLoader Exporter);

# this is critical -- tell dynaloader to load the module so that its
# symbols are available to all other modules.  without this, nobody
# else can use important functions like gtk2perl_new_object!
#
# hrm.  win32 doesn't really use this, because we have to link the whole
# thing at compile time to ensure all the symbols are defined.
#
# on darwin, at least with the particular 5.8.0 binary i'm using, perl
# complains "Can't make loaded symbols global on this platform" when this
# is set to 0x01, but goes on to work fine.  returning 0 here avoids the
# warning and doesn't appear to break anything.
sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

# now load the XS code.
Gtk2->bootstrap ($VERSION);

# %Gtk2::EXPORT_TAGS is filled from the constants-x.y files by the generated XS
# code in build/constants.xs
our @EXPORT_OK = map { @$_ } values %Gtk2::EXPORT_TAGS;
$Gtk2::EXPORT_TAGS{all} = \@EXPORT_OK;

# Compatibility with perl 5.20 and non-dot locales.  Wrap all functions that
# might end up calling setlocale() such that POSIX::setlocale() is also called
# to ensure perl knows about the current locale.  See the discussion in
# <https://rt.perl.org//Public/Bug/Display.html?id=121930>,
# <https://rt.perl.org/Public/Bug/Display.html?id=121317>,
# <https://rt.perl.org/Public/Bug/Display.html?id=120723>.
if ($^V ge v5.20.0) {
  require POSIX;
  no strict 'refs';
  no warnings 'redefine';

  my $disable_setlocale = 0;
  my $orig_setlocale = \&Gtk2::disable_setlocale;
  *{Gtk2::disable_setlocale} = sub {
    $disable_setlocale = 1;
    $orig_setlocale->(@_);
  };

  # gtk_init_with_args is not wrapped.
  foreach my $function (qw/Gtk2::init Gtk2::init_check Gtk2::parse_args/) {
    my $orig_function = \&{$function};
    *{$function} = sub {
      if (!$disable_setlocale) {
        POSIX::setlocale (POSIX::LC_ALL (), '');
      }
      $orig_function->(@_);
    };
  }
}

# Names "STOP" and "PROPAGATE" here are per the GtkWidget event signal
# descriptions.  In some other flavours of signals the jargon is "handled"
# instead of "stop".  "Handled" matches g_signal_accumulator_true_handled(),
# though that function doesn't rate a mention in the Gtk docs.  There's
# nothing fixed in the idea of "true means cease emission" (whether it's
# called "stop" or "handled").  You can just as easily have false for cease
# (the way the underlying GSignalAccumulator func in fact operates).  The
# upshot being don't want to attempt to be too universal with the names
# here; "EVENT" is meant to hint at the context or signal flavour they're
# for use with.
use constant {
  EVENT_STOP      => 1,
  EVENT_PROPAGATE => !1,
};

sub import {
	my $class = shift;

	# threads' init needs to be called before the main init and we don't
	# want to force the order those options are passed to us so we need to
	# cache the choices in booleans and (optionally) do them in the corect
	# order afterwards
	my $init = 0;
	my $threads_init = 0;

	my @unknown_args = ($class);
	foreach (@_) {
		if (/^-?init$/) {
			$init = 1;
		} elsif (/-?threads-init$/) {
			$threads_init = 1;
		} else {
			push @unknown_args, $_;
		}
	}

	Gtk2::Gdk::Threads->init if ($threads_init);
	Gtk2->init if ($init);

	# call into Exporter for the unrecognized arguments; handles exporting
	# and version checking
	Gtk2->export_to_level (1, @unknown_args);
}

# Preloaded methods go here.

package Gtk2::Gdk;

sub CHARS { 8 };
sub SHORTS { 16 };
sub LONGS { 32 };

sub USHORTS { 16 };
sub ULONGS { 32 };

package Gtk2::Gdk::Atom;

use overload
	'==' => \&Gtk2::Gdk::Atom::eq,
	'!=' => \&Gtk2::Gdk::Atom::ne,
	fallback => 1;

package Gtk2::CellLayout::DataFunc;

use overload
	'&{}' => sub {
                   my ($func) = @_;
                   return sub { Gtk2::CellLayout::DataFunc::invoke($func, @_) }
                 },
	fallback => 1;

package Gtk2::TreeSortable::IterCompareFunc;

use overload
	'&{}' => sub {
                   my ($func) = @_;
                   return sub { Gtk2::TreeSortable::IterCompareFunc::invoke($func, @_) };
                 },
	fallback => 1;

package Gtk2::TreeModelSort;

# We forgot to prepend Gtk2::TreeModel to @Gtk2::TreeModelSort::ISA.  So this
# hack is here to make sure that $model_sort->get resolves to
# Gtk2::TreeModel::get when appropriate and to Glib::Object::get otherwise, so
# we stay backwards compatible.
sub get {
	if (@_ > 1 and ref $_[1] eq 'Gtk2::TreeIter') {
		# called as $model->get ($iter, columns...);
		return Gtk2::TreeModel::get (@_);
	} else {
		# called as $model->get (names...);
		return Glib::Object::get (@_);
	}
}

package Gtk2::Builder;

sub _do_connect {
  my ($object,
      $signal_name,
      $user_data,
      $connect_object,
      $flags,
      $handler) = @_;

  my $func = ($flags & 'after') ? 'signal_connect_after' : 'signal_connect';

  # we get connect_object when we're supposed to call
  # signal_connect_object, which ensures that the data (an object)
  # lives as long as the signal is connected.  the bindings take
  # care of that for us in all cases, so we only have signal_connect.
  # if we get a connect_object, just use that instead of user_data.
  $object->$func($signal_name => $handler,
                 $connect_object ? $connect_object : $user_data);
}

sub connect_signals {
  my $builder = shift;
  my $user_data = shift;

  # $builder->connect_signals ($user_data)
  # $builder->connect_signals ($user_data, $package)
  if ($#_ <= 0) {
    my $package = shift;
    $package = caller unless defined $package;

    $builder->connect_signals_full(sub {
      my ($builder,
          $object,
          $signal_name,
          $handler_name,
          $connect_object,
          $flags) = @_;

      no strict qw/refs/;

      my $handler = $handler_name;
      if (ref $package) {
        $handler = sub { $package->$handler_name(@_) };
      } else {
        if ($package && $handler !~ /::/) {
          $handler = $package.'::'.$handler_name;
        }
      }

      _do_connect ($object, $signal_name, $user_data, $connect_object,
                   $flags, $handler);
    });
  }

  # $builder->connect_signals ($user_data, %handlers)
  else {
    my %handlers = @_;

    $builder->connect_signals_full(sub {
      my ($builder,
          $object,
          $signal_name,
          $handler_name,
          $connect_object,
          $flags) = @_;

      return unless exists $handlers{$handler_name};

      _do_connect ($object, $signal_name, $user_data, $connect_object,
                   $flags, $handlers{$handler_name});
    });
  }
}

package Gtk2;

1;
__END__
# documentation is a good thing.

=head1 NAME

Gtk2 - Perl interface to the 2.x series of the Gimp Toolkit library

=head1 SYNOPSIS

  use Gtk2 -init;
  # Gtk2->init; works if you didn't use -init on use
  my $window = Gtk2::Window->new ('toplevel');
  my $button = Gtk2::Button->new ('Quit');
  $button->signal_connect (clicked => sub { Gtk2->main_quit });
  $window->add ($button);
  $window->show_all;
  Gtk2->main;

=head1 ABSTRACT

Perl bindings to the 2.x series of the Gtk+ widget set.  This module
allows you to write graphical user interfaces in a Perlish and
object-oriented way, freeing you from the casting and memory management
in C, yet remaining very close in spirit to original API.

=head1 DESCRIPTION

The Gtk2 module allows a Perl developer to use the Gtk+ graphical user
interface library.  Find out more about Gtk+ at http://www.gtk.org.

The GTK+ Reference Manual is also a handy companion when writing Gtk
programs in any language.  http://developer.gnome.org/doc/API/2.0/gtk/
The Perl bindings follow the C API very closely, and the C reference
documentation should be considered the canonical source.

To discuss gtk2-perl, ask questions and flame/praise the authors,
join gtk-perl-list@gnome.org at lists.gnome.org.

Also have a look at the gtk2-perl website and sourceforge project page,
http://gtk2-perl.sourceforge.net

=head1 INITIALIZATION

  use Gtk2 qw/-init/;
  use Gtk2 qw/-init -threads-init/;

=over

=item -init

Equivalent to Gtk2->init, called to initialize GLIB and GTK+. Just about every
Gtk2-Perl script should do "use Gtk2 -init"; This initialization should take
place before using any other Gtk2 functions in your GUI applications. It will
initialize everything needed to operate the toolkit and parses some standard
command line options. @ARGV is adjusted accordingly so your own code will never
see those standard arguments.

=item -threads-init

Equivalent to Gtk2::Gdk::Threads->init, called to initialze/enable gdk's thread
safety mechanisms so that gdk can be accessed from multiple threads when used
in conjunction with Gtk2::Gdk::Threads->enter and Gtk2::Gdk::Threads->leave. If
invoked as Gtk2::Gdk::Threads->init it should be done before Gtk2->init is
called, if done by "use Gtk2 -init -threads-init" order does not matter.

=back

=head1 EXPORTS

Gtk2 exports nothing by default, but some constants are available upon request.

=over

=item Tag: constants

  GTK_PRIORITY_RESIZE

  GTK_PATH_PRIO_LOWEST
  GTK_PATH_PRIO_GTK
  GTK_PATH_PRIO_APPLICATION
  GTK_PATH_PRIO_THEME
  GTK_PATH_PRIO_RC
  GTK_PATH_PRIO_HIGHEST

  GDK_PRIORITY_EVENTS
  GDK_PRIORITY_REDRAW
  GDK_CURRENT_TIME

=back

See L<Glib> for other standard priority levels.

=head1 SEE ALSO

L<perl>(1), L<Glib>(3pm), L<Pango>(3pm).

L<Gtk2::Gdk::Keysyms>(3pm) contains a hash of key codes, culled from
gdk/gdkkeysyms.h

L<Gtk2::api>(3pm) describes how to map the C API into Perl, and some of the
important differences in the Perl bindings.

L<Gtk2::Helper>(3pm) contains stuff that makes writing Gtk2 programs
a little easier.

L<Gtk2::SimpleList>(3pm) makes the GtkListStore and GtkTreeModel a I<lot>
easier to use.

L<Gtk2::Pango>(3pm) exports various little-used but important constants you
may need to work with pango directly.

L<Gtk2::index>(3pm) lists the autogenerated api documentation pod files
for Gtk2.

Gtk2 also provides code to make it relatively painless to create Perl
wrappers for other GLib/Gtk-based libraries.  See L<Gtk2::CodeGen>,
L<ExtUtils::PkgConfig>, and L<ExtUtils::Depends>.  If you're writing bindings,
you'll probably also be interested in L<Gtk2::devel>, which is a supplement
to L<Glib::devel> and L<Glib::xsapi>.  The Binding Howto, at
http://gtk2-perl.sourceforge.net/doc/binding_howto.pod.html, ties it all
together.

=head1 AUTHORS

=encoding utf8

The gtk2-perl team:

 muppet <scott at asofyet dot org>
 Ross McFarland <rwmcfa1 at neces dot com>
 Torsten Schoenfeld <kaffeetisch at web dot de>
 Marc Lehmann <pcg at goof dot com>
 Göran Thyni <gthyni at kirra dot net>
 Jörn Reder <joern at zyn dot de>
 Chas Owens <alas at wilma dot widomaker dot com>
 Guillaume Cottenceau <gc at mandrakesoft dot com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2011 by the gtk2-perl team.

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
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA  02110-1301  USA.

=cut
