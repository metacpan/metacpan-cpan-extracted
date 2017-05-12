package DC::UI::Dockable;

use common::sense;

our @ISA = DC::UI::Bin::;


# A dockable can be docked into a DC::UI::Dockbar
# Attributes:
# 'can_close' says: This dockable has a close button as tab.
# 'can_undock' says that the dockable tab has a 'undock' button.
# 'title' is the title of the tab label or the title of the undocket window

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      title      => "unset",
      can_close  => 1,
      can_undock => 0, # temporarily deactivated!
      @_,
   );

   $self->init;

   $self
}

# a setup method for the constructor
sub init {
   my ($self) = @_;

   my $bb = $self->{c_tab} = DC::UI::ButtonBin->new (tooltip => $self->{tooltip});
   $bb->add (my $vb = DC::UI::Box->new);
   $vb->add (
      my $b =
         $self->{tab_label} =
            DC::UI::Label->new (expand => 1, valign => 0.5, align => 0, padding_x => 8, padding_y => 4)
   );

   if ($self->{can_close}) {
      $vb->add (
         my $ib = DC::UI::ImageButton->new (path => 'x1_close.png', scale => 0.3)
      );
      $ib->connect (activate => sub {
         $self->close;
         0
      });
   }

   if ($self->{can_undock}) {
      $vb->add (
         my $ib2 = DC::UI::ImageButton->new (path => 'x1_close.png', scale => 0.3)
      );
      $ib2->connect (activate => sub {
         $self->emit ("undock");
         0
      });
   }


   $self->set_title ($self->{title});
}

# This sets the title of the dockable. The title is displayed
sub set_title {
   my ($self, $title) = @_;
   $self->{title} = $title;
   $self->update_tab;
}

# Returns the title
sub get_title { $_[0]->{title} }

# This method activates the tab of the dockable if it is docked
sub select_my_tab {
   my ($self) = @_;
   if ($self->is_docked) {
      $self->{dockbar}->select_dockable ($self);
   }
}

# (private) This method is used by Dockbar to tell the dockable
# it's position in the dockbar (if it has one, if it has no position,
# $pos is undef).
sub set_dockbar_pos {
   my ($self, $pos) = @_;
   $self->{dockbar_pos} = $pos;
   $self->update_tab;
}

# (private) This method tells the dockable that it is 'active', which means:
# it is docked and it's tab has been activated and it is currently shown.
sub set_dockbar_tab_active {
   my ($self, $active) = @_;
   $self->{dockbar_active} = $active;
   $self->update_tab;
}

# (private) This method updates the tab and other things of the dockable
# whenever something has been changed (title, color, ...)
sub update_tab {
   my ($self) = @_;
   # TODO: set color according to dockbar_active

   my $oldcolor = $self->{tab_label}->{fg};
   if ($self->is_docked_active) {
      $self->{tab_label}->{fg} = $self->{active_fg}   || [1, 1, 1];
   } else {
      $self->{tab_label}->{fg} = $self->{inactive_fg} || [1, 1, 1,];
   }
   if (join (',', @$oldcolor) ne join (',', @{$self->{tab_label}->{fg}})) {
      # update colors
      $self->{tab_label}->realloc;
      $self->{tab_label}->update;
   }

   $self->{tab_label}->set_markup (
      $self->get_title
      . (defined $self->{dockbar_pos}
            ? "-" . ($self->{dockbar_pos} + 1)
            : "")
   );
}

# This method sets the active foreground color of the dockable tab
sub set_active_fg {
   my ($self, $fg) = @_;
   $self->{active_fg} = $fg;
   $self->update_tab;
}

# This method sets the inactive foreground color of the dockable tab
sub set_inactive_fg {
   my ($self, $fg) = @_;
   $self->{inactive_fg} = $fg;
   $self->update_tab;
}

# (private) This method is used by the Dockbar to tell the Dockable which
# Dockbar it belongs to. Do not call this method yourself, use the dockbars
# add_dock and remove_dock methods instead.
sub set_dockbar {
   my ($self, $dockbar) = @_;
   $self->{dockbar} = $dockbar;
   Scalar::Util::weaken $self->{dockbar};
}

# This method is called when someone wants to 'activate' the dockable,
# the meaning of being 'activated' is given by subclasses that inherit
# from Dockable. Eg. In ChatView the 'activation' means that the entry field
# of for chat is activated for input.
sub activate {
   my ($self) = @_;
   $self->emit ("activate");
}

# Returns whether this dockable is docked on a Dockbar.
sub is_docked {
   my ($self) = @_;
   $self->{dockbar} or return 0;
   return $self->{dockbar}->is_docked ($self);
}

# Returns whether this dockable is docked _and_ it's tab
# is active.
sub is_docked_active {
   my ($self) = @_;
   $self->{dockbar} or return 0;
   return $self->{dockbar_active};
}

# This method is called when the Dockable wants to be closed, which means
# that it's window is closed or tab is removed from the dockbar and it
# is removed from the dockbar.
sub close {
   my ($self) = @_;
   return if !$self->{can_close};
   $self->emit ("close_dock");
}

1
