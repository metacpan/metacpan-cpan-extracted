# Copyright 2010, 2011, 2012, 2014 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

package Glib::Ex::ObjectBits;
use 5.008;
use strict;
use warnings;
use Carp;

# uncomment this to run the ### lines
#use Smart::Comments;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(set_property_maybe);

our $VERSION = 16;

sub set_property_maybe {
  my $object = shift;
  if (@_ & 1) {
    croak "set_property_maybe() expect even number of pname,value arguments";
  }
  for (my $i = 0; $i < @_; ) {
    ### set_property_maybe(): $_[$i]
    ### pspec(): $object->find_property($_[$i])
    if ($object->find_property($_[$i])) {
      $i += 2;
    } else {
      splice @_, $i, 2;
    }
  }
  $object->set_property (@_);
}

1;
__END__

=for stopwords Glib-Ex-ObjectBits Ryde tooltip Gtk mis-spell

=head1 NAME

Glib::Ex::ObjectBits -- misc Glib object helpers

=head1 SYNOPSIS

 use Glib::Ex::ObjectBits;

=head1 FUNCTIONS

=head2 Display

=over

=item C<< Glib::Ex::ObjectBits::set_property_maybe ($obj, $pname1,$value1, $pname2,$value2,  ...) >>

Set properties on C<$obj> if they exist.  Each C<$pname> is a property name
(a string) and those which exist on C<$obj> are set to their C<$value> with
C<< $obj->set_property() >>.

This is a handy way to apply properties which might only exist in a new
enough version of a library.  For example C<Gtk2::Widget> has a
C<tooltip-text> in Gtk 2.12 up,

    Glib::Ex::ObjectBits::set_property_maybe
      ($widget, tooltip_text => 'Some description.');

Things like this which are purely visual and don't affect actual operation
are good for a set-maybe.  Important things might want some sort of proper
fallback.

Properties which do always exist can be included in C<set_property_maybe()>,
if a single call looks better.  But be careful not to mis-spell a property
name, since C<set_property_maybe()> of course has no way to identify that.

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use Glib::Ex::ObjectBits 'set_property_maybe';
    # "tearoff-title" new in Gtk 2.10
    set_property_maybe ($combobox, tearoff_title => 'My Menu');

Importing C<set_property_maybe()> is good if making many such settings.  The
name is tolerably distinctive.

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes.

=head1 SEE ALSO

L<Glib::Object>

L<Glib::Ex::EnumBits>,
L<Glib::Ex::FreezeNotify>,
L<Glib::Ex::SignalBits>,
L<Glib::Ex::SignalIds>,
L<Glib::Ex::SourceIds>,
L<Glib::Ex::TieProperties>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2014 Kevin Ryde

Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ObjectBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
