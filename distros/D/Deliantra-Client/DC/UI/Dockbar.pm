package DC::UI::Dockbar;

use common::sense;

use DC::UI::Dockable;

our @ISA = DC::UI::Toplevel::;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      border_bg => [1, 1, 1, 1],
      x         => "max",
      y         => 0,
      child     => (my $nb = DC::UI::Notebook->new (expand => 1)),
      @_,
   );

   $self->{notebook} = $nb;

   $nb->connect (page_changed => sub {
      my ($nb, $page) = @_;
      $self->update_active ($page);
      0
   });

   $self
}

# This method is which you want to call to add a Dockable
sub add_dock {
   my ($self, $dockable) = @_;
   $self->{docks}->{"$dockable"} = $dockable;
   delete $self->{dock_windows}->{"$dockable"};

   $dockable->set_dockbar ($self);

   # TODO: capture the guards to remove these connections
   $dockable->connect (dock => sub {
      my ($dockable) = @_;
      #d# warn "DOCKABLE DOCK";
      $self->dock ($dockable);
      0
   });

   $dockable->connect (undock => sub {
      my ($dockable) = @_;
      #d# warn "DOCKABLE UNDOCK";
      $self->undock ($dockable);
      0
   });

   $dockable->connect (close_dock => sub {
      my ($dockable) = @_;
      $self->remove_dock ($dockable);
      0
   });

   $self->dock ($dockable);
}

# This method will remove the dockable from the Dockbar. Which means that the
# window for this dockable is also removed (if it was undocked).
sub remove_dock {
   my ($self, $dockable) = @_;

   $self->undock_window ($dockable);
   $self->undock_notebook ($dockable);
   delete $self->{docks}->{"$dockable"};
   $dockable->set_dockbar (undef);
}

# This method makes sure the dockable is 'docked' into the Dockbar
# and eg. removes the free floating window it maybe has.
sub dock {
   my ($self, $dockable) = @_;
   $self->undock_window ($dockable);

   # here the assumption is done that $dockable is inserted at the end of the
   # notebook tabs, so that the other tabs dont have to be updated
   $self->{notebook}->add ($dockable);
   $dockable->set_dockbar_pos ($self->{notebook}->page_index ($dockable));
   $self->update_active;
}

# (private) This method updates all docked tabs and tells them whether their
# tab is 'active'.
sub update_active {
   my ($self, $page) = @_;

   unless ($page) {
      $page = $self->{notebook}->get_current_page;
   }

   for ($self->{notebook}->pages) {
      $_->set_dockbar_tab_active ($_ eq $page);
   }
}

# This method undocks the dockable (if it isn't already undocked) and
# creates a floating window for it.
sub undock {
   my ($self, $dockable) = @_;
   return if $self->{dock_windows}->{"$dockable"};

   $self->undock_notebook ($dockable);
   my $win =
      $self->{dock_windows}->{"$dockable"} =
          DC::UI::Toplevel->new (
             title => $dockable->get_title,
             child => $dockable,
             force_w => 100, force_h => 100,
             x => 100, y => 100,
             has_close_button => 1,
          );

   $win->connect (delete => sub {
      $self->dock ($dockable);
      0
   });

   $win->show;
}

# (private) This method does the cleanup stuff when the dockable is docked
# into the dockbar and had a floating window.
sub undock_window {
   my ($self, $dockable) = @_;
   my $win =
      $self->{dock_windows}->{"$dockable"}
         or return;

   $win->remove ($dockable);
   delete $self->{dock_windows}->{"$dockable"};
   $win->hide; # XXX: neccessary?
}

# (private) This method does the cleanup stuff which is neccessary when the
# dockable is removed from the notebook.
sub undock_notebook {
   my ($self, $dockable) = @_;
   $self->{notebook}->remove ($dockable);
   my $nextpage = ($self->{notebook}->pages)[0];
   $self->{notebook}->set_current_page ($nextpage)
      if $nextpage;
   $dockable->set_dockbar_pos (undef);
   $dockable->set_dockbar_tab_active (undef);
   $self->update_dockbar_positions;
}

# (private) This method updates the position of the dockables in the dockbar.
sub update_dockbar_positions {
   my ($self) = @_;
   my $i = 0;
   for ($self->{notebook}->pages) {
      $_->set_dockbar_pos ($i++);
   }
}

# Returns all Dockables of this Dockbar
sub dockables {
   my ($self) = @_;
   values %{$self->{docks}}
}

# Returns whether the dockable is currently docked. (and not
# a floating window).
sub is_docked {
   my ($self, $dockable) = @_;
   return not exists $self->{dock_windows}->{"$dockable"};
}

# switching to a page
sub user_switch_to_page {
   my ($self, $page) = @_;
   $page = $page eq '0' ? 10 : $page;

   my @tabs = $self->{notebook}->pages;

   for (my $i = 0; $i < ($page - 1); $i++) {
      shift @tabs;
   }

   my $page = shift @tabs;
   return unless $page;

   $self->{notebook}->set_current_page ($page);
}

# This method activates the tab of the dockable if it is docked.
sub select_dockable {
   my ($self, $dockable) = @_;
   return unless exists $self->{docks}->{"$dockable"};
   $self->{notebook}->set_current_page ($dockable);
}

# close current tab
sub close_current_tab {
   my ($self) = @_;

   if ($self->{notebook}->get_current_page) {
      my $curdock = $self->{notebook}->get_current_page;
      $curdock->close;
   }
}

# "activates" the current page
sub activate_current {
   my ($self) = @_;

   if ($self->{notebook}->get_current_page) {
      $self->{notebook}->get_current_page->activate
   }
}

1
