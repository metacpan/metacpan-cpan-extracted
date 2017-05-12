package KGS::Listener::Roomlist;

use base KGS::Listener;

sub listen {
   my $self = shift;
   $self->SUPER::listen (@_, qw(upd_rooms));
}

sub inject_upd_rooms {
   my ($self, $msg) = @_;

   for (@{$msg->{rooms}}) {
      $self->{rooms}{$_->{name}} = $_;
   }
   $self->event_update_rooms;
}

sub event_update_rooms {}

1;



