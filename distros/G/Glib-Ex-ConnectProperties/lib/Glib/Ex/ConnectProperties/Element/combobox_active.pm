# Copyright 2011, 2012 Kevin Ryde

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


package Glib::Ex::ConnectProperties::Element::combobox_active;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Gtk2;
use Gtk2::Ex::ComboBoxBits 32; # v.32 for get_active_text()

use base 'Glib::Ex::ConnectProperties::Element';
our $VERSION = 19;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant pspec_hash =>
  {
   exists => Glib::ParamSpec->boolean ('has-active', # name
                                       '',           # nick
                                       '',           # blurb
                                       0,            # default, unused
                                       'readable'),  # read-only
   iter => Glib::ParamSpec->boxed ('iter', # name
                                   '',     # nick
                                   '',     # blurb
                                   'Gtk2::TreeIter', # obj type
                                   Glib::G_PARAM_READWRITE),
   path => Glib::ParamSpec->boxed ('path',  # name
                                   '',      # nick
                                   '',      # blurb
                                   'Gtk2::TreePath', # boxed type
                                   Glib::G_PARAM_READWRITE),
   text => Glib::ParamSpec->string ('text',  # name
                                    '',      # nick
                                    '',      # blurb
                                    '',      # default
                                    Glib::G_PARAM_READWRITE),
  };

use constant read_signal => 'changed';

my %get_method = (exists => sub { !! $_[0]->get_active_iter },
                  iter   => 'get_active_iter',
                  path   => \&Gtk2::Ex::ComboBoxBits::get_active_path,
                  text   => 'get_active_text',
                 );
sub get_value {
  my ($self) = @_;
  ### combobox_active get_value()
  my $method = $get_method{$self->{'pname'}};
  return $self->{'object'}->$method;
}

my %set_method = (iter => (eval{Gtk2->VERSION(1.240);1}
                           ? 'set_active_iter'
                           # no $iter==undef support until Perl-Gtk2 1.240
                           : sub {
                             my ($combobox, $iter) = @_;
                             if ($iter) {
                               $combobox->set_active_iter($iter);
                             } else {
                               $combobox->set_active(-1);
                             }
                           }),
                  path => \&Gtk2::Ex::ComboBoxBits::set_active_path,
                  text => \&Gtk2::Ex::ComboBoxBits::set_active_text,
                 );
sub set_value {
  my ($self, $value) = @_;
  ### combobox_active set_value()
  my $method = $set_method{$self->{'pname'}};
  return $self->{'object'}->$method ($value);
}

1;
__END__

# 'combobox-active#exists'
# 'combobox-active#iter'
# 'combobox-active#path'
# 'combobox-active#text'


# maybe ...
# 'combobox-active#column-N'



# maybe ...
#
# 'path-string' => Glib::ParamSpec->string ('path-string',
#                                           '',  # nick
#                                           '',  # blurb
#                                           '',  # default, unused
#                                           Glib::G_PARAM_READWRITE),
#                   'path-string' => \&_combobox_get_active_path_string,
#                   'path-string' => \&_combobox_set_active_path_string,
# sub _combobox_get_active_path_string {
#   my ($combobox) = @_;
#   my $path;
#   return (($path = _combobox_get_active_path($_[0]))
#           && $path->to_string);
# }
# sub _combobox_set_active_path_string {
#   my ($combobox, $str) = @_;
#   Gtk2::Ex::ComboBoxBits::set_active_path
#       ($combobox, Gtk2::TreePath->new_from_string($str));
# }

=for stopwords Glib-Ex-ConnectProperties ConnectProperties combobox ComboBox toplevel Ryde

=head1 NAME

Glib::Ex::ConnectProperties::Element::combobox_active -- combobox active item

=for test_synopsis my ($combobox,$another);

=head1 SYNOPSIS

 Glib::Ex::ConnectProperties->new([$combobox, 'combobox-active#exists'],
                                  [$another,  'something']);

=head1 DESCRIPTION

This element class implements ConnectProperties access to the "active" item
of a L<Gtk2::ComboBox>.  These elements require the
C<Gtk2::Ex::ComboBoxBits> helper module.

    combobox-active#exists     boolean, read-only
    combobox-active#path       Gtk2::TreePath
    combobox-active#iter       Gtk2::TreeIter
    combobox-active#text       string

For just toplevel rows the plain ComboBox C<active> property is enough.
C<combobox-active#path> and C<combobox-active#iter> are good for a combobox
with sub-rows.

C<combobox-active#text> is for use with a "simplified text" ComboBox as
created by C<< Gtk2::ComboBox->new_text() >> etc.

=head1 SEE ALSO

L<Glib::Ex::ConnectProperties>,
L<Glib::Ex::ConnectProperties::Element::tree_selection>,
L<Gtk2::ComboBox>

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
