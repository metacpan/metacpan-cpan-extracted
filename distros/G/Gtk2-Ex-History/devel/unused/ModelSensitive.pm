# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-History is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-History.  If not, see <http://www.gnu.org/licenses/>.


package Gtk2::Ex::History::ModelSensitive;
use 5.008;
use strict;
use warnings;
use Gtk2 1.220;
use Gtk2::Ex::History;
use Scalar::Util;
use Glib::Ex::SignalIds;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 8;

sub new {
  my ($class, $target, $model) = @_;
  ### ModelSensitive: $target && "$target", $model && "$model"
  my $self = bless {}, $class;
  $self->set_target ($target);
  $self->set_model ($model);
  return $self;
}

sub set_target {
  my ($self, $target) = @_;
  Scalar::Util::weaken ($self->{'target'} = $target);
  _update_sensitive ($self);
}
sub set_model {
  my ($self, $model) = @_;
  Scalar::Util::weaken ($self->{'model'} = $model);
  $self->{'ids'} = $model && do {
    Scalar::Util::weaken (my $weak_self = $self);
    ### ModelSensitive connect
    Glib::Ex::SignalIds->new
        ($model,
         ($model->get_iter_first
          ? $model->signal_connect (row_deleted => \&_do_model_deleted,
                                    \$weak_self)
          : $model->signal_connect (row_inserted => \&_do_model_inserted,
                                    \$weak_self),
         ));
  };
  _update_sensitive ($self);
}

# 'row-inserted' handler for the model
# connected only when model is empty
sub _do_model_inserted {
  my ($model) = @_;
  my $ref_weak_self = $_[-1]; # userdata
  ### ModelSensitive _do_model_inserted()
  my $self = $$ref_weak_self || return;

  $self->{'ids'} = Glib::Ex::SignalIds->new
    ($model,
     $model->signal_connect (row_deleted => \&_do_model_deleted,
                             $ref_weak_self));
  _update_sensitive ($self);
}

# 'row-deleted' handler for the model
# connected only when model is non-empty
sub _do_model_deleted {
  my ($model) = @_;
  if (! $model->get_iter_first) {
    my $ref_weak_self = $_[-1];
    ### ModelSensitive _do_model_insdel
    my $self = $$ref_weak_self || return;

    $self->{'ids'} = Glib::Ex::SignalIds->new
      ($model,
       $model->signal_connect (row_inserted => \&_do_model_inserted,
                               $ref_weak_self));
    _update_sensitive ($self);
  }
}

sub _update_sensitive  {
  my ($self) = @_;
  ### ModelSensitive _update_sensitive: $self->{'target'} && "$self->{'target'}", $self->{'model'} && $self->{'model'}->get_iter_first

  if (my $target = $self->{'target'}) {
    $target->set_sensitive
      ($self->{'model'} && $self->{'model'}->get_iter_first);
  }
}

1;
__END__

=for stopwords treemodel Ryde Gtk2-Ex-History

=head1 NAME

Gtk2::Ex::History::ModelSensitive -- internal part of Gtk2::Ex::History

=head1 DESCRIPTION

This is an internal part of C<Gtk2::Ex::History>, expect it to change or
disappear.  It arranges for a button, action, etc, to be insensitive when
the treemodel in the corresponding direction is empty.

=head1 SEE ALSO

L<Gtk2::Ex::History>,
L<Gtk2::Ex::History::Button>,
L<Gtk2::Ex::History::Action>,
L<Gtk2::Ex::History::MenuToolButton>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-history/index.html>

=head1 LICENSE

Gtk2-Ex-History is Copyright 2010, 2011 Kevin Ryde

Gtk2-Ex-History is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-History is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-History.  If not, see L<http://www.gnu.org/licenses/>.

=cut
