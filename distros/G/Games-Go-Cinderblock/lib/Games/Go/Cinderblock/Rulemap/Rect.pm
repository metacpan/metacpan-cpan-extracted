package Games::Go::Cinderblock::Rulemap::Rect;
use 5.14.0;
use Moose;
extends 'Games::Go::Cinderblock::Rulemap';

has h  => ( #height
   is => 'ro',
   isa => 'Int',
   default => '19'
);
has w  => ( #width
   is => 'ro',
   isa => 'Int',
   default => '19'
);
has wrap_v => ( #cylinder/torus
   is => 'ro',
   isa => 'Bool',
   default => 0,
);
has wrap_h => (
   is => 'ro',
   isa => 'Bool',
   default => 0,
);

# LoL of all 0's
sub empty_board{ 
   my $self = shift;
   my @rows = 
      map {
         [ map {0} (1..$self->w) ]
      } (1..$self->h);
   return \@rows;
}

sub copy_board{
   my ($self, $board) = @_;
   return [ map {[@$_]} @$board ];
}

sub node_to_string{node_to_id(@_)}
sub node_from_string{node_from_id(@_)}

#turns [13,3] into 13*w+3
#see also &pretty_coordinates
sub node_to_id{ 
   my ($self, $node) = @_;
   #return join '-', @$node;
   return $node->[0] * $self->w + $node->[1]
}
sub node_from_id{ #return undef if invalid
   my ($self, $string) = @_;
   my $row = $string / $self->w;
   my $col = $string % $self->w;
   return [$row,$col];
   #return unless $string =~ /^(\d+)-(\d+)$/;
   #return unless $1 < $self->h;
   #return unless $2 < $self->w;
   #return $node->[0] * $self->w + $node->[1]
   #return [$1,$2];
}
sub stone_at_node{ #0 if empty, b black, w white, r red, etc
   my ($self, $board, $node) = @_;
   my ($row, $col) = @$node;
   return $board->[$row][$col];
}
sub set_stone_at_node{
   my ($self, $board, $node, $side) = @_;
   my ($row, $col) = @$node;
   $board->[$row][$col] = $side;
}
sub all_nodes{ #return list coordinates
   my ($self) = @_;
   my @nodes;
   for my $i (0..$self->h-1){
      push @nodes, map {[$i,$_]} (0..$self->w-1)
   }
   return @nodes;
}

sub node_liberties{goto \&adjacent_nodes}
sub adjacent_nodes{
   my ($self, $node) = @_;
   my ($row, $col) = @$node;
   my @nodes;
   if ($self->wrap_v){
      push @nodes, [($row-1)% $self->h, $col];
      push @nodes, [($row+1)% $self->h, $col];
   }
   else{
      push @nodes, [$row-1, $col] unless $row == 0;
      push @nodes, [$row+1, $col] unless $row == $self->h-1;
   }
   
   if ($self->wrap_h){
      push @nodes, [$row, ($col-1)% $self->w];
      push @nodes, [$row, ($col+1)% $self->w];
   }
   else{
      push @nodes, [$row, $col-1] unless $col == 0;
      push @nodes, [$row, $col+1] unless $col == $self->w-1;
   }
   return @nodes;
}


my @cletters = qw/a b c d e f g h j k l m n o p q r s t u v w x y z/;

sub pretty_coordinates{ #convert 1-1 to b18, etc
   my ($self, $node) = @_;
   my ($row,$col) = $node =~ /^(\d+)-(\d+)$/;
   $col = $cletters[$col];
   $row = $self->h - $row;
   
   return "$col$row";
}

use Scalar::Util::Numeric qw(isint);

sub node_is_valid{
   my ($self, $node) = @_;
   my ($row,$col) = @$node;
   #check bounds
   return 0 if 
      $row < 0
      or $col < 0
      or $row >= ($self->h)
      or $col >= ($self->w);
   #check integeritude.. for row & col.
   return 0 unless isint $row;
   return 0 unless isint $col;
   return 1;
}
1;
