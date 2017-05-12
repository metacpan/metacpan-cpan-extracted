# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::ToolItem::OverflowToDialog::Dialog;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use Scalar::Util;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 48;

use Glib::Object::Subclass
  'Gtk2::Dialog',
  signals => { map => \&_do_map_or_unmap,
               unmap => \&_do_map_or_unmap,
               destroy => \&_do_destroy,
             },
  properties => [ Glib::ParamSpec->object
                  ('toolitem',
                   'Tool item object',
                   'Blurb.',
                   'Gtk2::ToolItem',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;

  my $label = $self->{'label'} = Gtk2::Label->new ('');
  $label->show;
  $self->vbox->pack_start ($label, 0,0,0);

  my $child_vbox = $self->{'child_vbox'} = Gtk2::VBox->new;
  $child_vbox->show;
  # expand/fill child with dialog
  $self->vbox->pack_start ($child_vbox, 1,1,0);

  $self->set (destroy_with_parent => 1);
  $self->add_buttons ('gtk-close' => 'close');

  # connect to self instead of a class handler since as of Gtk2-Perl 1.223 a
  # Gtk2::Dialog class handler for 'response' is called with response IDs as
  # numbers, not enum strings like 'accept'
  $self->signal_connect (response => \&_do_response);
}

sub _do_destroy {
  my ($self) = @_;
  ### OverflowToDialog _do_destroy()

  if (my $toolitem = $self->{'toolitem'}) {
    # toolitem to create a new dialog next time required, even if someone
    # else is keeping the destroyed $self alive for a while
    delete $toolitem->{'dialog'};

    # put the child_widget back into the toolitem, or if toolitem maybe gone
    # then let the child destroy with the dialog
    Gtk2::Ex::ToolItem::OverflowToDialog::_update_child_position ($toolitem);
  }
  $self->signal_chain_from_overridden;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### ToolItem-Entry SET_PROPERTY: $pspec->get_name
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;

  if ($self->{'toolitem'}) {
    # so toolitem will destroy on unreferenced
    Scalar::Util::weaken ($self->{'toolitem'});

    $self->{'child_vbox'}->set (sensitive => $newval->get('sensitive'));
    if ($newval->find_property('tooltip_text')) { # new in Gtk 2.12
      $self->{'child_vbox'}->set (tooltip_text => $newval->get('tooltip_text'));
      ### initial tooltip: $self->{'child_vbox'}->get('tooltip_text')
    }
  }
  $self->update_transient_for; # new toolitem
  $self->update_text;          # new toolitem
}

sub _do_response {
  my ($self, $response) = @_;
  ### OverflowToDialog _do_response(): $response

  if ($response eq 'close') {
    $self->signal_emit ('close');
  }
}

sub _do_map_or_unmap {
  my ($self) = @_;
  # chain first to set $dialog->mapped flag
  # Or is it better to move the child first to establish the initial size?
  shift->signal_chain_from_overridden;
  if (my $toolitem = $self->{'toolitem'}) {
    Gtk2::Ex::ToolItem::OverflowToDialog::_update_child_position ($toolitem);
  }
}

# called by toolitem when overflow-mnemonic changes
sub update_text {
  my ($self) = @_;
  my $toolitem = $self->{'toolitem'};
  my $str = $toolitem && $toolitem->get('overflow-mnemonic');
  # Gtk 2.0.x gtk_label_set_label() didn't allow NULL, so empty ''
  if (! defined $str) { $str = ''; }
  $str = Gtk2::Ex::MenuBits::mnemonic_undo ($str);
  $self->{'label'}->set_label ($str);
  $self->set_title ($str);
}

# called by toolitem for hierarchy-changed
sub update_transient_for {
  my ($self) = @_;
  my $toolitem = $self->{'toolitem'};
  my $toplevel = $toolitem && $toolitem->get_toplevel;
  $self->set_transient_for ($toplevel && $toplevel->isa('Gtk2::Window')
                            ? $toplevel : undef);
}

sub present_for_menuitem {
  my ($self, $menuitem) = @_;
  if ($self->can('set_screen')) { # new in Gtk 2.2
    $self->set_screen ($menuitem->get_screen);
  }
  $self->present;
}

1;
__END__

=for stopwords Gtk Gtk2 Perl-Gtk ToolItem Gtk toolitem

=head1 NAME

Gtk2::Ex::ToolItem::OverflowToDialog::Dialog -- toolitem overflow dialog

=head1 DESCRIPTION

This is an internal part of C<Gtk2::Ex::ToolItem::OverflowToDialog> not
meant for other use.

=cut
