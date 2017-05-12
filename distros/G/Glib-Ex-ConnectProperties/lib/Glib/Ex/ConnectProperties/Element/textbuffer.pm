# Copyright 2012 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


package Glib::Ex::ConnectProperties::Element::textbuffer;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 19;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant pspec_hash =>
  do {
    my $bool = Glib::ParamSpec->boolean ('empty',     # name
                                         '',          # nick
                                         '',          # blurb
                                         1,           # default, unused
                                         'readable'); # read-only
    # anon hash
    ({
      'empty'      => $bool,
      'not-empty'  => $bool,
      # dummy name and dummy range, just want an "int" type
      'char-count' => Glib::ParamSpec->int ('char-count',  # name, unused
                                            '',            # nick, unused
                                            '',            # blurb, unused
                                            0,             # min, unused
                                            2**31-1,       # max, unused
                                            0,             # default, unused
                                            'readable'),   # read-only

     })
  };

# "notify::text" doesn't seem to be emitted, as of gtk circa 2.24.8
use constant read_signal => 'changed';

sub get_value {
  my ($self) = @_;
  my $textbuf = $self->{'object'};
  my $pname = $self->{'pname'};
  my $char_count = $textbuf->get_char_count;
  if ($pname eq 'empty') {
    return $char_count == 0;
  } elsif ($pname eq 'not-empty') {
    return $char_count != 0;
  } else {
    return $char_count;
  }
}

1;
__END__

=for stopwords Glib-Ex-ConnectProperties TextBuffer ConnectProperties Gtk Ryde

=head1 NAME

Glib::Ex::ConnectProperties::Element::textbuffer -- TextBuffer character count

=for test_synopsis my ($textbuf,$another);

=head1 SYNOPSIS

 Glib::Ex::ConnectProperties->new([$textbuf, 'textbuffer#empty'],
                                  [$another, 'something']);

=head1 DESCRIPTION

This element class implements ConnectProperties access to the following
attributes of a L<Gtk2::TextBuffer>.

    textbuffer#empty           boolean, read-only
    textbuffer#not-empty       boolean, read-only
    textbuffer#char-count      integer, read-only

For example C<textbuffer#not-empty> might be connected up to make a "clear"
button sensitive only when there is in fact something to clear

    Glib::Ex::ConnectProperties->new
      ([$textbuf, 'textbuffer#not-empty'],
       [$button,  'sensitive', write_only => 1]);

These attributes use C<$textbuf-E<gt>get_char_count()>.  C<Gtk2::TextBuffer>
doesn't offer this count from a property as such, only a method.

The full text string is available from the C<text> property on the
TextBuffer in the usual way.  But Gtk circa 2.24.8 doesn't seem to emit a
C<notify> for changes to it, only the C<changed> signal.  If accessing
C<text> with ConnectProperties it may be necessary to use C<read_signal
=E<gt> "changed"> instead of the usual notify.

=head1 SEE ALSO

L<Glib::Ex::ConnectProperties>,
L<Glib::Ex::ConnectProperties::Element::model_rows>,
L<Gtk2::TextBuffer>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-connectproperties/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012 Kevin Ryde

Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ConnectProperties.  If not, see L<http://www.gnu.org/licenses/>.

=cut
