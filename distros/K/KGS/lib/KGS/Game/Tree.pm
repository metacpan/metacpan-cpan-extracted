package KGS::Game::Tree;

use Gtk2::GoBoard::Constants;

use KGS::Constants;

# exclusion masks... the bit on the left excludes (removes) the ones on the right
my %exclude_type = (
   &MARK_TRIANGLE => MARK_SQUARE | MARK_TRIANGLE | MARK_CIRCLE | MARK_LABEL,
   &MARK_SQUARE   => MARK_SQUARE | MARK_TRIANGLE | MARK_CIRCLE | MARK_LABEL,
   &MARK_CIRCLE   => MARK_SQUARE | MARK_TRIANGLE | MARK_CIRCLE | MARK_LABEL,
   &MARK_LABEL    => MARK_SQUARE | MARK_TRIANGLE | MARK_CIRCLE | MARK_LABEL,
   &MARK_SMALL_B  => MARK_SMALL_B | MARK_SMALL_W |                   MARK_MOVE,
   &MARK_SMALL_W  => MARK_SMALL_B | MARK_SMALL_W |                   MARK_MOVE,
   &MARK_GRAYED   =>                                                 MARK_MOVE | MARK_GRAYED,
   &MARK_B        =>                               MARK_B | MARK_W | MARK_MOVE | MARK_GRAYED, #d# was !MARK_GRAYED here
   &MARK_W        =>                               MARK_B | MARK_W | MARK_MOVE | MARK_GRAYED, #d# was !MARK_GRAYED here
);

sub init_tree {
   my ($self) = @_;
   $self->{tree} = [ {
      id   => 0,
      move => -1,
   } ];
}

sub update_tree {
   my ($self, $tree) = @_;

   my $node = $self->{curnode};

   my $up_tree;
   my $up_move;

   #Carp::cluck KGS::Listener::Debug::dumpval $tree;#d#

   #warn "update_tree = ".KGS::Listener::Debug::dumpval $tree;#d#

   for (@$tree)  {
      my ($type, @arg) = @$_;
      if ($type eq "add_node") {
         $up_tree = 1;
         $node = $self->{tree}[$arg[0] + 1]
            or die "FATAL: referencing nonexistent node $arg[0]+1!";

         my $new = {
            id     => scalar @{$self->{tree}},
            parent => $node->{id},
            move   => $node->{move} + 1,
         };

         push @{$self->{tree}}, $new;
         push @{$node->{children}}, $new->{id};

         $node = $new;

      } elsif ($type eq "set_node") {
         $node = $self->{tree}[$arg[0] + 1]
            or die "set_node to undefined tree node $arg[0]+1";

      } elsif ($type eq "set_current") {
         $up_tree = 1;
         $node = $self->{tree}[$arg[0] + 1]
            or die "set_current to undefined tree node $arg[0]+1";

         $self->{curnode} = $node;

      } elsif ($type eq "mark") {
         $up_tree = 1;

         my $bit = $arg[1];
         my $ref = $node->{"$arg[2],$arg[3]"} ||= [];

         $ref->[0] &= ~$exclude_type{$bit};
         $ref->[0] |= $bit if $arg[0];
         $ref->[1] |= $exclude_type{$bit};

         $ref->[2] = $arg[4] if $bit == MARK_LABEL;

      } elsif ($type eq "set_stone" or $type eq "move") {
         $up_tree = 1;

         if ($type eq "move") {
            $self->{lastmove_time}   = $KGS::Protocol::NOW;
            $self->{lastmove_colour} = $arg[0];
            $up_move = $arg[1] == 255 if $self->{loaded};
         }

         if ($arg[1] < 255) {
            my $ref = $node->{"$arg[1],$arg[2]"} ||= [];

            my $bit = $arg[0] == COLOUR_BLACK ? MARK_B
                    : $arg[0] == COLOUR_WHITE ? MARK_W
                    : 0;

            $ref->[0] &= ~$exclude_type{$bit || MARK_B};
            $ref->[0] |= $bit | ($type eq "move" ? MARK_MOVE : 0);
            $ref->[1] |= $exclude_type{$bit || MARK_B};
         } else {
            warn "PLEASE REPORT: pass coordinates but type is $type" if $type ne "move";#d#

            $node->{pass} = 1;
         }

      } elsif ($type eq "comment") {
         if (!defined $arg[0]) {
            delete $node->{comment};
         } else {
            $self->event_update_comments ($node, $arg[0], !exists $node->{comment});
            $node->{comment} .= $arg[0];
         }

      } elsif ($type eq "set_timer") {
         $up_tree = 1;#d#
         $node->{timer}[$arg[0]] = [$arg[1], $arg[2]];

      } elsif ($type eq "score") {
         $up_tree = 1;
         $node->{score}[$arg[0]] = $arg[1];

      } elsif ($type eq "player") {
         $node->{player}[$arg[0]] = $arg[1];

      } elsif ($type eq "rank") {
         $node->{rank}[$arg[0]] = $arg[1];

      } elsif ($type eq "more") {
         die;

      } elsif ($type eq "done") {
         die;
         $self->{loaded} = 1;
         # nop

      } else {
         $node->{$type} = $arg[0]; # rules, date etc..

         $self->event_update_rules ($arg[0]) if $type eq "rules";
      }
   }

   $self->{curnode} = $node;

   $self->event_move ($up_move) if defined $up_move;

   return $up_tree;
}

sub get_path {
   my ($self) = @_;

   my @nodes;

   my $node = $self->{curnode};

   for(;;) {
      push @nodes, $node;
      last unless $node->{parent};
      $node = $self->{tree}[$node->{parent}];
   }

   [reverse @nodes];
}

sub gen_move_tree {
   my ($self, $colour, $x, $y) = @_;

   [#d#
      #NYI#
      [add_node => 0],
   ];
}

sub event_move            { }
sub event_update_tree     { }
sub event_update_comments { }
sub event_update_rules    { }

1;

