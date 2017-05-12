# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
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

package Gtk2::Ex::MenuItem::Subclass;
use 5.008;
use Gtk2;
use strict;
use warnings;

# Not sure about exporting.  Would be a way to take just new_with_label()
# and new_with_mnemonic() and leave key/value new().  Maybe a tag
# ":all_except_new".
#
# use base 'Exporter';
# our @EXPORT_OK = qw(new new_with_label new_with_mnemonic);
# our %EXPORT_TAGS = (all => \@EXPORT_OK);

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 48;

BEGIN {
  if (Gtk2::MenuItem->find_property('label')) {
    eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;

# GtkMenuItem in 2.16 up has "label" and "use-underline" properties which do
# the AccelLabel creation stuff.
#
sub new_with_label {
  my ($class, $str) = @_;
  ### MenuItem-Subclass new_with_label()
  return $class->Glib::Object::new (@_ > 1
                                    ? (label => $str)
                                    : ());
}
sub new_with_mnemonic {
  my ($class, $str) = @_;
  return $class->Glib::Object::new (@_ > 1
                                    ? (label => $str,
                                       use_underline => 1)
                                    : ());
}
1
HERE


  } else {
    eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;

sub new_with_label {
  my ($class, $str) = @_;
  my $self = $class->Glib::Object::new;
  if (@_ > 1) {
    # Replicate C code from
    #     gtk_menu_item_new_with_label()
    #     gtk_check_menu_item_new_with_label()
    #
    my $label = Gtk2::AccelLabel->new ($str);
    $label->set_alignment (0, 0.5);
    $self->add ($label);
    $label->set_accel_widget ($self);
    $label->show;
  }
  return $self;
}

sub new_with_mnemonic {
  my ($class, $str) = @_;
  my $self = $class->Glib::Object::new;
  if (@_ > 1) {
    # Replicate C code from
    #     gtk_menu_item_new_with_mnemonic()
    #     gtk_check_menu_item_new_with_mnemonic()
    #
    my $label = Gtk2::AccelLabel->Glib::Object::new; # no initial label string
    $label->set_text_with_mnemonic ($str);
    $label->set_alignment (0, 0.5);
    $self->add ($label);
    $label->set_accel_widget ($self);
    $label->show;
  }
  return $self;
}
1
HERE
  }

  *new = \&new_with_mnemonic;
}

1;
__END__

=for stopwords subclassing MenuItem Ryde Gtk2-Ex-WidgetBits

=head1 NAME

Gtk2::Ex::MenuItem::Subclass -- help for subclassing Gtk2::MenuItem

=for test_synopsis our @ISA

=head1 SYNOPSIS

 package My::MenuItem;
 use Glib::Object::Subclass 'Gtk2::MenuItem';

 use Gtk2::Ex::MenuItem::Subclass;
 unshift @ISA, 'Gtk2::Ex::MenuItem::Subclass';

 # then in an application
 my $item1 = My::MenuItem->new ('_Foo');
 my $item2 = My::MenuItem->new_with_label ('Bar');
 my $item3 = My::MenuItem->new_with_mnemonic ('_Quux');

=head1 DESCRIPTION

C<Gtk2::Ex::MenuItem::Subclass> helps subclasses of C<Gtk2::MenuItem>.  It
provides versions of the following class methods

    new
    new_with_label
    new_with_mnemonic

which behave like the base C<Gtk2::MenuItem> methods but create a widget of
the subclass, not merely a C<Gtk2::MenuItem> like the wrapped C code does.
This is designed as a multiple inheritance mix-in.  For example,

    package My::MenuItem;
    use Glib::Object::Subclass 'Gtk2::MenuItem',
       signals => { ... },
       properties => [ ... ];

    # prepend to prefer this new() etc
    use Gtk2::Ex::MenuItem::Subclass;
    unshift @ISA, 'Gtk2::Ex::MenuItem::Subclass';

Then application code can create a C<My::MenuItem> widget with

    my $item = My::MenuItem->new ('_Foo');

C<$item> is created as a C<My::MenuItem>, as the call suggests.  Similarly
C<new_with_label()> and C<new_with_mnemonic()>.

The same can be done when subclassing from C<Gtk2::CheckMenuItem> too.

=head2 C<ISA> order

The C<unshift @ISA> shown above ensures C<Gtk2::Ex::MenuItem::Subclass> is
before the C<new_with_label()> and C<new_with_mnemonic()> from
C<Gtk2::MenuItem>, and also before the C<new()> from
C<Glib::Object::Subclass>.  The effect is

    @ISA = ('Gtk2::Ex::MenuItem::Subclass',
            'Glib::Object::Subclass',
            'Gtk2::MenuItem',
            'Gtk2::Item',
            'Gtk2::Bin',
            ...)

If you want the key/value C<new()> from C<Glib::Object::Subclass> rather
than the label-string one then put C<Gtk2::Ex::MenuItem::Subclass> just
after C<Glib::Object::Subclass>, like

    # for key/value new() per plain Glib::Object
    @ISA = ('Glib::Object::Subclass',
            'Gtk2::Ex::MenuItem::Subclass',
            'Gtk2::MenuItem',
            'Gtk2::Item',
            ...)

All C<@ISA> setups are left to the subclassing package because the order can
be important and it can be confusing if too many C<use> things muck about
with it.

=head1 FUNCTIONS

=over 4

=item C<< $item = $class->new () >>

=item C<< $item = $class->new ($str) >>

Create and return a new menu item widget of C<$class>.  If a C<$str>
argument is given then this behaves as C<new_with_mnemonic()> below.

=item C<< $item = $class->new_with_label () >>

=item C<< $item = $class->new_with_label ($str) >>

Create and return a new menu item widget of C<$class>.  If a C<$str>
argument is given then a C<Gtk2::AccelLabel> child is created and added to
display that string.  C<$str> should not be C<undef>.

If there's no C<$str> argument then C<new_with_label()> behaves the same as
plain C<new()> and doesn't create a child widget.

=item C<< $item = $class->new_with_mnemonic () >>

=item C<< $item = $class->new_with_mnemonic ($str) >>

Create and return a new menu item widget of C<$class>.  If a C<$str>
argument is given then a C<Gtk2::AccelLabel> child is created and added to
display that string.  An underscore in the string becomes an underline and
keyboard shortcut, eg. "_Edit" for underlined "E".  C<$str> should not be
C<undef>.

If there's no C<$str> argument then C<new_with_mnemonic()> behaves the same
as plain C<new()> and doesn't create a child widget.

=back

For Gtk 2.16 and up C<new_with_label()> simply sets the C<label> property
and C<new_with_mnemonic()> sets the C<label> and C<use-underline>
properties.  For earlier versions an explicit C<Gtk2::AccelLabel> creation
is done as per past code in C<gtk_menu_item_new_with_label()> and
C<gtk_menu_item_new_with_mnemonic()>.

For reference, it doesn't work to re-bless the return from the MenuItem
widgets from the base C<new_with_label()> and C<new_with_mnemonic()> into a
new subclass.  Doing so changes the Perl hierarchy but doesn't change the
underlying C code object C<GType> and therefore doesn't get new properties
or signals from the subclass.

=head1 OTHER WAYS TO DO IT

When running on Gtk 2.16 the C<label> property can be used instead of
C<new_with_label()> and so in a subclass there's no particular need to have
the separate C<new_with_label()>.

    package My::MenuItem;
    use Glib::Object::Subclass 'Gtk2::MenuItem';

    # then in the application
    my $item = My::MenuItem->new (label => 'Hello');

But the benefit of C<Gtk2::Ex::MenuItem::Subclass> is that you don't leave
exposed a C<new_with_label()> which does the wrong thing, and it can work on
Gtk prior to 2.16.

=head1 SEE ALSO

C<Glib::Object::Subclass>, C<Gtk2::MenuItem>, C<Gtk2::CheckMenuItem>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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
