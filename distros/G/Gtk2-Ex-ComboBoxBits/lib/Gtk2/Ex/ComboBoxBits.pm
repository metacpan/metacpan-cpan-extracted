# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::ComboBoxBits;
use 5.008;
use strict;
use warnings;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(get_active_path
                    set_active_path
                    set_active_text
                    find_text_iter);

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 32;

#------------------------------------------------------------------------------

sub get_active_path {
  my ($combobox) = @_;
  my ($model, $iter);
  return (($model = $combobox->get_model)
          && ($iter = $combobox->get_active_iter)
          && $model->get_path ($combobox->get_active_iter));
}

sub set_active_path {
  my ($combobox, $path) = @_;
  ### set_active_path()

  # Non-existent rows go to set_active(-1) since the Perl-Gtk2
  # set_active_iter() doesn't accept undef (NULL) until 1.240.
  # If ready to demand that version could
  #   $combobox->set_active_iter ($model && $path && $model->get_iter($path));

  if ($path) {
    if ($path->get_depth == 1) {
      # top-level row using set_active()
      $combobox->set_active ($path->get_indices);
      return;
    }

    if (my $model = $combobox->get_model) {
      if (my $iter = $model->get_iter($path)) {
        $combobox->set_active_iter ($iter);
        return;
      }
    }
  }
  # path=undef, or no model, or path not in model
  # FIXME: ->set_active(-1) spits a warning in gtk 2.28 if no model,
  # want Gtk2 1.240 for ->set_active_iter(undef)
  if ($combobox->get_model) {
    $combobox->set_active (-1);
  }
}

#------------------------------------------------------------------------------

sub set_active_text {
  my ($combobox, $str) = @_;
  ### ComboBoxBits set_active_text(): $str

  if (defined $str && (my $iter = find_text_iter ($combobox, $str))) {
    ### $iter
    $combobox->set_active_iter ($iter);
  } else {
    # As of Gtk 2.20 set_active() throws a g_log() warning if there's no
    # model set.  Prefer to quietly do nothing to make no active item when
    # already no active item.
    if ($combobox->get_model) {
      # pending perl-gtk 1.240 set_active_iter() accepting undef
      $combobox->set_active (-1);
    }
  }
  ### set_active_text() active num now: $combobox->get_active
}

sub find_text_iter {
  my ($combobox, $str) = @_;
  ### ComboBoxBits find_text_iter(): $str
  my $ret;
  if (my $model = $combobox->get_model) {
    $model->foreach (sub {
                       my ($model, $path, $iter) = @_;
                       ### get_value: $model->get_value ($iter, 0)
                       if ($str eq $model->get_value ($iter, 0)) {
                         ### found at: $path->to_string
                         $ret = $iter->copy;
                         return 1; # stop
                       }
                       return 0; # continue
                     });
  }
  ### $ret
  return $ret;
}

1;
__END__

# sub _text_to_nth {
#   my ($combobox, $str) = @_;
#   if (my @indices = _text_to_indices($combobox, $str)) {
#     return $indices[0];
#   } else {
#     return -1;
#   }
#   return $n;
# }
# sub _text_to_indices {
#   my ($combobox, $str) = @_;
#   my @ret;
#   if (my $model = $combobox->get_model) {
#     $model->foreach (\&_text_to_nth_foreach, \$n);
#   }
#   return @ret;
# }
# sub _text_to_nth_foreach {
#   my ($model, $path, $iter, $aref) = @_;
#   if ($str eq $model->get_value ($iter, 0)) {
#     @$aref = $path->get_indices;
#     return 1; # stop
#   }
#   return 0; # continue
# }

=for stopwords Gtk2-Ex-ComboBoxBits ComboBox Ryde Gtk

=head1 NAME

Gtk2::Ex::ComboBoxBits -- misc Gtk2::ComboBox helpers

=head1 SYNOPSIS

 use Gtk2::Ex::ComboBoxBits;

=head1 FUNCTIONS

=head2 Active Path

=over

=item C<< $path = Gtk2::Ex::ComboBoxBits::get_active_path ($combobox) >>

Return a C<Gtk2::TreePath> to the active item in C<$combobox>, or C<undef>
if empty or no model or nothing active.

=item C<< Gtk2::Ex::ComboBoxBits::set_active_path ($combobox, $path) >>

Set the active item in C<$combobox> to the given C<Gtk2::TreePath>
position.  If C<$path> is empty or C<undef> or there's no such row in the
model then C<$combobox> is set to nothing active.

Some versions of ComboBox have a feature where if there's no model in
C<$combobox> then a toplevel active item is remembered ready for a model set
later.  Not sure if that's documented, but C<set_active_path> tries to
cooperate by using C<set_active> for toplevels, and C<set_active_iter> for
sub-rows (which don't get the same remembering).

=back

=head2 Text Combos

The following are for use on a simplified "text" ComboBox as created by
C<< Gtk2::ComboBox->new_text() >>.

=over

=item C<< $str = Gtk2::Ex::ComboBoxBits::set_active_text ($combobox, $str) >>

C<$combobox> must be a simplified "text" type ComboBox.  Set the entry
C<$str> active.

The corresponding "get" is C<< $combobox->get_active_text() >>, see
L<Gtk2::ComboBox>.

=item C<< $iter = Gtk2::Ex::ComboBoxBits::find_text_iter ($combobox, $str) >>

Return a C<Gtk2::TreeIter> which is the row for C<$str> in a text style
combobox.  If C<$str> is not in C<$combobox> then return C<undef>.

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use Gtk2::Ex::ComboBoxBits 'set_active_text';

This can be handy if using C<set_active_text> many times.
C<Gtk2::Ex::ComboBox::Text> imports it to use as an object method.

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-comboboxbits/index.html>

=head1 LICENSE

Copyright 2010, 2011 Kevin Ryde

Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-ComboBoxBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
