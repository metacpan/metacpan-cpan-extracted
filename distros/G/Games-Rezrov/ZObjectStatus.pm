package Games::Rezrov::ZObjectStatus;

use strict;
#use SelfLoader;
use Carp qw(confess);

use Games::Rezrov::MethodMaker qw(
				  is_player
				  is_current_room
				  is_toplevel_child
				  in_inventory
				  in_current_room
				  parent_room
				  toplevel_child
				 );

1;

#__DATA__

sub new {
  confess unless @_ == 3;
  my ($type, $id, $object_cache) = @_;
  my $self = {};
  bless $self, $type;

  my $pid = Games::Rezrov::StoryFile::player_object() || -1;
  my $current_room = Games::Rezrov::StoryFile::current_room() || -1;
  my $zo = $object_cache->get($id);
  my $levels = 0;
  my $last;

  my $oid = $zo->object_id();
  $self->is_player($pid == $oid);
  $self->is_current_room($current_room == $oid);

  while (1) {
    last unless defined $zo;
    my $oid = $zo->object_id();
    $self->in_inventory(1) if $oid == $pid;
    if ($levels and $object_cache->is_room($oid)) {
      $self->in_current_room(1) if ($oid == $current_room);
      $self->parent_room($zo);
      $self->toplevel_child($last);
      last;
    }
    $levels++;
    $last = $zo;
    $zo = $object_cache->get($zo->get_parent_id());
  }
  $self->is_toplevel_child($levels == 1);
  
  return $self;
}
