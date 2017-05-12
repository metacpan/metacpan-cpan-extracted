# Copyright 2010, 2011, 2012 Kevin Ryde

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


package Gtk2::Ex::ContainerBits;
use 5.008;
use strict;
use warnings;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(remove_all
                    remove_widgets);

our $VERSION = 48;

sub remove_all {
  my ($container) = @_;
  push @_, $container->get_children;
  goto &remove_widgets;
}

# Shifting off each $child arg lets each get garbage collected immediately
# if nothing else refers to them.  Probably not very important, and not a
# documented feature yet, but it means the widget is destroyed immediately
# after remove if not referred to elsewhere, which is probably what would be
# hoped for from remove_all().
#
sub remove_widgets {
  my $container = shift;
  while (@_) {
    my $child = shift;
    if (my $parent = $child->get_parent) {
      if ($parent == $container) {
        $container->remove ($child);
      }
    }
  }
}

1;
__END__

=for stopwords Ryde Gtk2-Ex-WidgetBits

=head1 NAME

Gtk2::Ex::ContainerBits -- helpers for Gtk2::Container widgets

=head1 SYNOPSIS

 use Gtk2::Ex::ContainerBits;

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::ContainerBits::remove_widgets ($container, $widget,...) >>

Remove each given C<$widget> from C<$container> if it is in fact a child of
C<$container>.

Checking widgets are children avoids C<Glib::Log> error messages from
C<< $container->remove >>, including unusual cases of a C<remove> signal
handler removing multiple widgets in response to removing one.

=item C<< Gtk2::Ex::ContainerBits::remove_all ($container) >>

Remove all child widgets from C<$container>.

This is simply the above C<remove_widgets> on all current children and so
copes with removal of one child causing removal of others.  If a removal
causes new children to be added then they're not removed, only those present
at the start.

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use Gtk2::Ex::ContainerBits 'remove_widgets';
    remove_widgets ($container, $widget1, $widget2);

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes.

When making a container subclass the functions could be imported to have
them available as methods on the new class if the names and purpose suit.

    package MyBucket;                         # new class
    use Glib::Object::Subclass 'Gtk2::HBox';
    use Gtk2::Ex::ContainerBits 'remove_all'; # import

    $bucket->remove_all;  # available as a method

=head1 SEE ALSO

L<Gtk2::Container>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

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
