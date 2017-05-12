# Copyright 2010, 2011, 2012 Kevin Ryde

# Gtk2-Ex-WidgetBits is shared by several distributions.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

package Test::Without::Gtk2Things;
use 5.008;
use strict;
use warnings;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 48;

our $VERBOSE = 0;

# Not sure the without_foo methods are a good idea.  Might prefer a hash of
# names so can associate a gtk version number to a without-ness, to have a
# "without version 2.x" option etc.
#
# FIXME: deleting the whole glob with "undef *Foo::Bar::func" is probably
# not a good idea.  Maybe let Sub::Delete do the work.
#

sub import {
  my $class = shift;
  my $count = 0;

  foreach my $thing (@_) {
    if ($thing eq '-verbose' || $thing eq 'verbose') {
      $VERBOSE++;

    } elsif ($thing eq 'all') {
      foreach my $method ($class->all_without_methods) {
        $class->$method;
        $count++;
      }

    } else {
      (my $method = "without_$thing") =~ tr/-/_/;
      if (! $class->can($method)) {
        die "Unknown thing to disable: $thing";
      }
      $class->$method;
      $count++;
    }
  }
  if ($VERBOSE) {
    print STDERR
      "Test::Without::Gtk2Things -- count without $count thing",
        ($count==1?'':'s'), "\n";
  }
}

# search @ISA with a view to subclasses, but is it a good idea?
sub all_without_methods {
  my ($class) = @_;
  ### all_without_methods(): $class
  my @methods;
  no strict 'refs';
  my @classes = ($class, @{"${class}::ISA"});
  ### @classes
  while (@classes) {
    my $c = shift @classes;
    ### $c
    #     my @keys = keys %{"${c}::"};
    #     ### keys: @keys
    push @methods, grep {/^without_/} keys %{"${c}::"};
    push @classes, grep {/^Test/} @{$c::ISA};
    ### @classes
  }
  ### @methods
  return @methods;
}

# our @ISA = ('TestX');
# {
# package TestX;
# our @ISA = ('TestY');
# }
# print __PACKAGE__->all_without_methods();

#------------------------------------------------------------------------------
# withouts

sub without_blank_cursor {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without CursorType blank-cursor, per Gtk before 2.16\n";
  }

  no warnings 'redefine', 'once';
  {
    my $orig = Glib::Type->can('list_values');
    *Glib::Type::list_values = sub {
      my ($class, $package) = @_;
      my @result = &$orig (@_);
      if ($package eq 'Gtk2::Gdk::CursorType') {
        @result = grep {$_->{'nick'} ne 'blank-cursor'} @result;
      }
      return @result;
    };
  }
  foreach my $func ('new', 'new_for_display') {
    my $orig = Gtk2::Gdk::Cursor->can($func);
    my $new = sub {
      my $cursor_type = $_[-1];
      if ($cursor_type eq 'blank-cursor') {
        require Carp;
        Carp::croak ('Test::Without::Gtk2Things -- no blank-cursor');
      }
      goto $orig;
    };
    my $func = "Gtk2::Gdk::Cursor::$func";
    no strict 'refs';
    *$func = $new;
  }
}

sub without_cell_layout_get_cells {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gtk2::CellLayout get_cells() method, per Gtk before 2.12\n";
  }

  _without_methods ('Gtk2::CellLayout', 'get_cells');
}

sub without_draw_as_radio {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gtk2::CheckMenuItem/ToggleAction draw-as-radio property, per Gtk before 2.4\n";
  }
  _without_properties ('Gtk2::CheckMenuItem', 'draw-as-radio');
  _without_properties ('Gtk2::ToggleAction', 'draw-as-radio');

  # check the desired effect ...
  {
    if (eval { Gtk2::CheckMenuItem->Glib::Object::new (draw_as_radio => 1) }) {
      die 'Oops, Gtk2::CheckMenuItem create with Glib::Object::new and draw-as-radio still succeeds';
    }
    if (Gtk2::CheckMenuItem->find_property ('draw_as_radio')) {
      die 'Oops, Gtk2::CheckMenuItem find_property("draw_as_radio") still succeeds';
    }
    my $action = Gtk2::ToggleAction->new (name => 'Test-Without-Gtk2Things');
    if (eval { $action->get_draw_as_radio() }) {
      die 'Oops, Gtk2::ToggleAction get_draw_as_radio() still available';
    }
  }
}

sub without_insert_with_values {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without ListStore,TreeStore insert_with_values(), per Gtk before 2.6\n";
  }

  _without_methods ('Gtk2::ListStore', 'insert_with_values');
  _without_methods ('Gtk2::TreeStore', 'insert_with_values');

  # check the desired effect ...
  {
    my $store = Gtk2::ListStore->new ('Glib::String');
    if (eval { $store->insert_with_values(0, 0=>'foo'); 1 }) {
      die 'Oops, Gtk2::ListStore call store->insert_with_values() still succeeds';
    }
  }
  {
    my $store = Gtk2::TreeStore->new ('Glib::String');
    if (eval { $store->insert_with_values(undef, 0, 0=>'foo'); 1 }) {
      die 'Oops, Gtk2::TreeStore call store->insert_with_values() still succeeds';
    }
  }
}

sub without_menuitem_label_property {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gtk2::MenuItem label and use-underline properties, per Gtk before 2.16\n";
  }
  _without_properties ('Gtk2::MenuItem', 'label', 'use-underline');

  # check the desired effect ...
  {
    if (eval { Gtk2::MenuItem->Glib::Object::new (label => 'hello') }) {
      die 'Oops, Gtk2::MenuItem create with Glib::Object::new and label still succeeds';
    }
    if (eval { Gtk2::MenuItem->Glib::Object::new ('use-underline' => 1) }) {
      die 'Oops, Gtk2::MenuItem create with Glib::Object::new and use-underline still succeeds';
    }
    if (Gtk2::MenuItem->can('get_label')) {
      die 'Oops, Gtk2::MenuItem still can("get_label")';
    }
  }
}

sub without_warp_pointer {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gtk2::Gdk::Display warp_pointer() method, per Gtk before 2.8\n";
  }

  _without_methods ('Gtk2::Gdk::Display', 'warp_pointer');

  # check the desired effect ...
  if (Gtk2::Gdk::Display->can('get_default')) { # new in Gtk 2.2
    if (my $display = Gtk2::Gdk::Display->get_default) {
      if (my $coderef = $display->can('warp_pointer')) {
        die "Oops, display->can(warp_pointer) still true: $coderef";
      }
    }
  }
}

sub without_widget_tooltip {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gtk2::Widget tooltips, per Gtk before 2.12\n";
  }
  _without_properties ('Gtk2::Widget',
                       'tooltip-text', 'tooltip-markup', 'has-tooltip');
  _without_methods ('Gtk2::Widget',
                    'get_tooltip_text', 'set_tooltip_text',
                    'get_tooltip_markup', 'set_tooltip_markup',
                    'get_has_tooltip', 'set_has_tooltip',);
  _without_signals ('Gtk2::Widget', 'query-tooltip');
}

sub without_gdkdisplay {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gdk2::Gdk::Display and Gtk2::Gdk::Screen, per Gtk 2.0.x\n";
  }

  # In Gtk 2.2 up Gtk2::Gdk->get_default_root_window() gives a g_log()
  # warning if no Gtk2->init() yet.  Wrap it to quietly give undef the same
  # as in Gtk 2.0.0.
  #
  # Something in recent Gtk or Perl-Gtk or Perl doesn't like running the
  # Gtk2::Gdk::Screen->get_default when that package has otherwise been
  # killed.  How to cleanly test for init-ed?
  #
  {
    my $get_default_screen = Gtk2::Gdk::Screen->can('get_default');
    my $orig = Gtk2::Gdk->can('get_default_root_window') || die;
    no warnings 'redefine';
    *Gtk2::Gdk::get_default_root_window = sub {
      local $SIG{__WARN__} = sub {};
      return &$orig(@_);
      
      # ### Without get_default_root_window() ...
      # my $x = Gtk2::Gdk::Screen->$get_default_screen();
      # print "$x\n";
      # if (! Gtk2::Gdk::Screen->$get_default_screen()) {
      #   return undef;
      # }
      # # this could have been "goto $orig" but have seen trouble in 5.8.9
      # # jumping to an XSUB like that
      # return &$orig(@_);
    };
  }

  _without_packages ('Gtk2::Gdk::Display', 'Gtk2::Gdk::Screen');

  _without_methods ('Gtk2::Gdk',
                    'get_display_arg_name',
                    'text_property_to_text_list_for_display',
                    'text_property_to_utf8_list_for_display',
                    'utf8_to_compound_text_for_display');
  _without_methods ('Gtk2::Gdk::Cursor',
                    'get_display',
                    'new_for_display','new_from_name','new_from_pixbuf');
  _without_methods ('Gtk2::Gdk::Colormap', 'get_screen');
  _without_methods ('Gtk2::Gdk::Drawable', 'get_display', 'get_screen');
  _without_methods ('Gtk2::Gdk::Font',     'get_display');
  _without_methods ('Gtk2::Gdk::GC',       'get_screen');
  _without_methods ('Gtk2::Gdk::Event',    'get_screen','set_screen',
                    'send_client_message_for_display');
  _without_methods ('Gtk2::Gdk::Visual',   'get_screen');

  # mangle the base Gtk2::Widget class so can() is false for subclasses
  _without_methods ('Gtk2::Widget',        'get_display', 'get_screen',
                    'has_screen');
  _without_signals ('Gtk2::Widget', 'screen-changed');

  _without_methods ('Gtk2::Clipboard',     'get_display', 'get_for_display');
  _without_methods ('Gtk2::Invisible',     'get_screen','set_screen',
                    'new_for_screen');
  _without_methods ('Gtk2::Menu',          'set_screen');
  _without_methods ('Gtk2::MountOperation','get_screen');
  _without_methods ('Gtk2::StatusIcon',    'get_screen','set_screen');
  _without_methods ('Gtk2::Window', 'get_screen','set_screen');
  _without_properties ('Gtk2::Window', 'screen');

  # check the desired effect ...
  if (my $coderef = Gtk2::Gdk::Display->can('get_default')) {
    die "Oops, Gtk2::Gdk::Display->can(get_default) still true: $coderef";
  }
  if (my $coderef = Gtk2::Gdk::Screen->can('get_display')) {
    die "Oops, Gtk2::Gdk::Screen->can(get_display) still true: $coderef";
  }
}

sub without_builder {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gtk2::Builder and Buildable interface, per Gtk before 2.12\n";
  }
  _without_packages ('Gtk2::Builder');
  _without_interfaces ('Gtk2::Buildable');
}

#------------------------------------------------------------------------------
# removing stuff

sub _without_interfaces {
  _without_packages (@_);

  {
    no warnings 'redefine', 'once';
    my %without;
    @without{@_} = (); # hash slice
    my $orig = UNIVERSAL->can('isa');

    *UNIVERSAL::isa = sub {
      my ($class_or_instance, $type) = @_;
      if (exists $without{$type}) {
        return !1; # false
      }
      goto $orig;
    };
  }
}

sub _without_packages {
  foreach my $package (@_) {
    $package->can('something'); # finish lazy loading, or some such
    no strict 'refs';
    foreach my $name (%{"${package}::"}) {
      my $fullname = "${package}::$name";
      undef *$fullname;
    }
  }
}

sub _without_methods {
  my $class = shift;
  foreach my $method (@_) {
    # force autoload ... umm, or something
    $class->can($method);

    my $fullname = "${class}::$method";
    { no strict 'refs'; undef *$fullname; }
  }

  # check the desired effect ...
  foreach my $method (@_) {
    if (my $coderef = $class->can($method)) {
      die "Oops, $class->can($method) still true: $coderef";
    }
  }
}

sub _without_properties {
  my ($without_class, @without_pnames) = @_;

  foreach my $without_pname (@without_pnames) {
    (my $method = $without_pname) =~ tr/-/_/;
    _without_methods ($without_class, "get_$method", "set_$method");
  }

  my %without_pnames;
  @without_pnames{@without_pnames} = (1) x scalar(@without_pnames); # slice

  no warnings 'redefine', 'once';
  {
    my $orig = Glib::Object->can('list_properties');
    *Glib::Object::list_properties = sub {
      my ($class) = @_;
      if ($class->isa($without_class)) {
        return grep {! $without_pnames{$_->get_name}} &$orig (@_);
      }
      goto $orig;
    };
  }
  {
    my $orig = Glib::Object->can('find_property');
    *Glib::Object::find_property = sub {
      my ($class, $pname) = @_;
      if ($class->isa($without_class)
          && _pnames_match ($pname, \%without_pnames)) {
        ### wrapped find_property() exclude
        return undef;
      }
      goto $orig;
    };
  }
  foreach my $func ('get', 'get_property') {
    my $orig = Glib::Object->can($func);
    my $new = sub {
      if ($_[0]->isa($without_class)) {
        for (my $i = 1; $i < @_; $i++) {
          my $pname = $_[$i];
          if (_pnames_match ($pname, \%without_pnames)) {
            require Carp;
            Carp::croak ("Test-Without-Gtk2Things: no get property $pname");
          }
        }
      }
      goto $orig;
    };
    my $func = "Glib::Object::$func";
    no strict 'refs';
    *$func = $new;
  }
  foreach my $func ('new', 'set', 'set_property') {
    my $orig = Glib::Object->can($func); # force autoload
    my $new = sub {
      if ($_[0]->isa($without_class)) {
        for (my $i = 1; $i < @_; $i += 2) {
          my $pname = $_[$i];
          if (_pnames_match ($pname, \%without_pnames)) {
            require Carp;
            Carp::croak ("Test-Without-Gtk2Things: no set property $pname");
          }
        }
      }
      goto $orig;
    };
    my $func = "Glib::Object::$func";
    no strict 'refs';
    *$func = $new;
  }


  # check the desired effect ...
  foreach my $without_pname (@without_pnames) {
    if (my $pspec = $without_class->find_property($without_pname)) {
      die "Oops, $without_class->find_property() still finds $without_pname: $pspec";
    }
    if (my @pspecs = grep {$_->get_name eq $without_pname}
        $without_class->list_properties) {
      local $, = ' ';
      die "Oops, $without_class->list_properties() still finds $without_pname: @pspecs";
    }
  }
}

sub _pnames_match {
  my ($pname, $without_pnames) = @_;
  ### $pname
  $pname =~ tr/_/-/;
  return $without_pnames->{$pname};
}

sub _without_signals {
  my ($without_class, @without_signames) = @_;

  my %without_signames;
  @without_signames{@without_signames} # hash slice
    = (1) x scalar(@without_signames);

  no warnings 'redefine', 'once';
  {
    require Glib;
    my $orig = Glib::Type->can('list_signals');
    *Glib::Type::list_signals = sub {
      my (undef, $list_class) = @_;
      if ($list_class->isa($without_class)) {
        return grep {! $without_signames{$_->{'signal_name'}}} &$orig (@_);
      }
      goto $orig;
    };
  }
  {
    my $orig = Glib::Object->can('signal_query');
    *Glib::Object::signal_query = sub {
      my ($class, $signame) = @_;
      if ($class->isa($without_class)
          && _pnames_match ($signame, \%without_signames)) {
        ### wrapped signal_query() exclude
        return undef;
      }
      goto $orig;
    };
  }
  foreach my $func ('signal_connect',
                    'signal_connect_after',
                    'signal_connect_swapped',
                    'signal_emit',
                    'signal_add_emission_hook',
                    'signal_remove_emission_hook',
                    'signal_stop_emission_by_name') {
    my $orig = Glib::Object->can($func);
    my $new = sub {
      my ($obj, $signame) = @_;
      if ($obj->isa($without_class)) {
        if (_pnames_match ($signame, \%without_signames)) {
          require Carp;
          Carp::croak ("Test-Without-Gtk2Things: no signal $signame");
        }
      }
      goto $orig;
    };
    my $func = "Glib::Object::$func";
    no strict 'refs';
    *$func = $new;
  }


  # check the desired effect ...
  foreach my $without_signame (@without_signames) {
    if (my $siginfo = $without_class->signal_query($without_signame)) {
      die "Oops, $without_class->signal_query() still finds $without_signame: $siginfo";
    }
    if (my @siginfos = grep {$_->{'signal_name'} eq $without_signame}
        Glib::Type->list_signals($without_class)) {
      local $, = ' ';
      die "Oops, Glib::Type->list_signals($without_class) still finds $without_signame: @siginfos";
    }
  }
}

1;
__END__

=for stopwords Gtk2-Ex-WidgetBits Gtk withouts tooltip Ryde

=head1 NAME

Test::Without::Gtk2Things - disable selected Gtk2 methods for testing

=head1 SYNOPSIS

 # perl -MTest::Without::Gtk2Things=insert_with_values foo.t

 # or
 use Test::Without::Gtk2Things 'insert_with_values';

=head1 DESCRIPTION

This module removes or disables selected features from C<Gtk2> in order to
simulate an older version or other restrictions.  It can be used for
development or testing to check code which adapts itself to available
features or which is meant to run on older Gtk.  There's only a couple of
"without" things as yet.

Obviously the best way to test application code on older Gtk is to run it on
an older Gtk, but making a full environment for that can be difficult.

=head2 Usage

From the command line use a C<-M> module load (as per L<perlrun>) for a
program or test script,

    perl -MTest::Without::Gtk2Things=insert_with_values foo.t

Or the same through C<Test::Harness> in a C<MakeMaker> test

    HARNESS_PERL_SWITCHES="-MTest::Without::Gtk2Things=blank_cursor" \
      make test

A test script can do the same with a C<use>,

    use Test::Without::Gtk2Things 'insert_with_values';

Or an equivalent explicit import,

    require Test::Without::Gtk2Things;
    Test::Without::Gtk2Things->import('insert_with_values');

In each case generally the "withouts" should be established before loading
application code in case that code checks features at C<BEGIN> time.

Currently C<Test::Without::Gtk2Things> loads C<Gtk2> if not already loaded,
but don't rely on that.  Mangling if/when loaded might be good instead, if
it could be done reliably.

=head1 WITHOUT THINGS

=over

=item C<verbose>

Have C<Test::Without::Gtk2Things> print some diagnostic messages to C<STDERR>.
For example,

    perl -MTest::Without::Gtk2Things=verbose,blank_cursor foo.t

    # prints
    Test::Without::Gtk2Things -- without CursorType blank-cursor, per Gtk before 2.16
    ...

=item C<blank_cursor>

Remove C<blank-cursor> from the C<Gtk2::Gdk::CursorType> enumeration per Gtk
before 2.16.

This means removing it from
C<< Glib::Type->list_values('Gtk2::Gdk::CursorType') >>, and making
C<< Gtk2::Gdk::Cursor->new() >> and C<new_for_display()> throw an error if
asked for that type.

Object properties of type C<Gtk2::Gdk::CursorType> are not affected, so they
can still be set to C<blank-cursor>, but perhaps that could be caught in the
future.  Blank cursors within Gtk itself are unaffected.

C<blank-cursor> is new in Gtk 2.16.  In earlier versions an invisible cursor
can be made by applications with a no-pixels-set bitmap as described by
C<gdk_cursor_new()> in such earlier versions.  (See
L<Gtk2::Ex::WidgetCursor> for some help doing that.)

=item C<builder>

Remove C<Gtk2::Builder> and the C<Gtk2::Buildable> interface, as per Gtk
before 2.12.

The Buildable interface is removed by removing the class and by mangling
C<UNIVERSAL::isa()> to pretend nothing is a Buildable.  Actual package
C<@ISA> lists are not changed currently.  This should mean Buildable still
works in C code, but not from Perl (neither currently loaded classes nor
later loaded classes).

In a Perl widget implementation it's fairly easy to support Gtk pre-2.12 by
omitting the Buildable interface if not available.

    use Glib::Object::Subclass
      'Gtk2::DrawingArea',
      interfaces => [ # Buildable new in Gtk 2.12, omit otherwise
                      Gtk2::Widget->isa('Gtk2::Buildable')
                      ? ('Gtk2::Buildable')
                      : (),
      ];

=item C<cell_layout_get_cells>

Remove the C<get_cells()> method from the C<Gtk2::CellLayout> interface, per
Gtk before 2.12.

This method removal affects all widget classes which implement the
CellLayout interface.  In earlier Gtk versions C<Gtk2::CellView> and
C<Gtk2::TreeViewColumn> have individual C<get_cell_renderers()> methods.
Those methods are unaffected by this without.

=item C<draw_as_radio>

Remove the C<Gtk2::CheckMenuItem> and C<Gtk2::ToggleAction> C<draw-as-radio>
property and corresponding explicit get/set methods.

C<draw-as-radio> on those two classes is new in Gtk 2.4.  For prior versions
it was only a builtin drawing feature of C<Gtk2::RadioMenuItem>, or some
such.  Simply skipping it may be good enough in those prior versions.

=item C<gdkdisplay>

Remove C<Gtk2::Gdk::Display> and C<Gtk2::Gdk::Screen> classes, and the
various C<get_display()>, C<set_screen()>, etc widget methods, as would be
the case in Gtk 2.0.x.

In Gtk 2.0.x there is a single implicit screen and display, and some methods
for querying their attributes (see L<Gtk2::Gdk>).  Most widget code doesn't
need to do much with a screen or display object, and it can be reasonably
easy to support 2.0.x by checking for a C<set_screen()> method etc if say
putting a dialog on the same screen as its originating main window.

=item C<insert_with_values>

Remove the C<insert_with_values()> method from C<Gtk2::ListStore> and
C<Gtk2::TreeStore>.  That method is new in Gtk 2.6.  In earlier versions
separate C<insert()> and C<set()> calls are necessary.

=item C<menuitem_label_property>

Remove from C<Gtk2::MenuItem> C<label> and C<use-underline> properties and
corresponding explicit C<get_label()>, C<set_use_underline()> etc methods.

C<label> and C<use-underline> are new in Gtk 2.16.  (For prior versions
C<new_with_label()> or C<new_with_mnemonic()> create and set a child label
widget.)

=item C<widget_tooltip>

Remove from C<Gtk2::Widget> base tooltip support new in Gtk 2.12.  This
means the C<tooltip-text>, C<tooltip-markup> and C<has-tooltip> properties,
their direct get/set methods such as C<< $widget->set_tooltip_text() >>, and
the C<query-tooltip> signal.

For code supporting both earlier and later than 2.12 it may be enough to
just skip the tooltip setups for the earlier versions.  See
C<set_property_maybe()> in L<Glib::Ex::ObjectBits> for some help with that.

=back

=head1 BUGS

It's not possible to restore removed things, once removed they're gone for
the whole program run.

=head1 SEE ALSO

L<Gtk2>,
L<Test::Without::Module>,
L<Test::Weaken::Gtk2>

L<Glib::Ex::ObjectBits> C<set_property_maybe()> for skipping non-existent
properties.

=head1 COPYRIGHT

Copyright 2010, 2011, 2012 Kevin Ryde

Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-WidgetBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
