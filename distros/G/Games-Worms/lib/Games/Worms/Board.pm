package Games::Worms::Board;

# A (base) class encapsulating a worm universe.

use strict;
use vars qw($Debug $VERSION %Default $Use_Error %Boards);
$VERSION = "0.60";
$Debug = 0;

$Use_Error = '';

%Boards = ();

#--------------------------------------------------------------------------

#
# We need methods Seg and Node that report the names of
# the classes our segments and nodes should belong to.
#
#--------------------------------------------------------------------------
# Constants for this universe

my $D60 = 3.14159 / 6;  # sixty degrees
my $SIN60 = sin($D60);  # the sin of 60 degrees, tweaked

#--------------------------------------------------------------------------
%Default = (
  'cells_wide' => 50,
  'cells_high' => 50,
  'tri_base' => 10,
  'aspect' => 1.3,
  'bg_color' => "#000000",
  'line_color' => "#202020",
);

# return a hash of the defaults in this class
sub Default { return %Default }

#--------------------------------------------------------------------------

sub new {
  my $c = shift;
  $c = ref($c) || $c;
  my $it = bless { $c->Default, @_ }, $c;

  # deriveds
  unless(defined $it->{'inner_border'}) {
    $it->{'inner_border'} = int($it->{'tri_base'} / 10);
    $it->{'inner_border'} = 3 if $it->{'inner_border'} < 3;
  }
  $it->{'worms'} ||= [];

  $it->{'tri_height'} =
    int($it->{'tri_base'} * $SIN60 * $it->{'aspect'} + .5);

  $it->{'canvas_width'} = 2 * $it->{'inner_border'} +
        ($it->{'cells_wide'} + .5) * $it->{'tri_base'};
  $it->{'canvas_height'} = 2 * $it->{'inner_border'} +
        $it->{'cells_high'} * $it->{'tri_height'};

  $it->init;
  return $it;
}

sub init { return; } 

#--------------------------------------------------------------------------

#sub worms { # return worms on this board (whether live or dead)
#  my $board = $_[0];
#  return @{$board->{'worms'}};
#}

#--------------------------------------------------------------------------

sub tick { # do system update tasks -- override in derived classes
  return;
}

#--------------------------------------------------------------------------

sub run {
  my($board, @Worm_names) = @_;

  $Games::Worms::Color_counter = 0;
  $board->{'generations'} = 0;
  @Worm_names = ('Games::Worms::Random2', 'Games::Worms::Random2',
                 'Games::Worms::Beeler', 'Games::Worms::Beeler',
                ) unless @Worm_names;

  my $n = 0;
  foreach my $w (@Worm_names) {
    my $rules = '';
    if($w =~ s</(.*)><>) {
      $rules = $1;
      $w = 'Games::Worms::Beeler' unless length $w;
    }

    unless(&_try_use($w)) {
      die "Can't use $w : $Use_Error\n";
    }
    $w->new(
      'current_node' =>
        $board->{'nodes'}[ rand(scalar( @{$board->{'nodes'}} )) ],
      'board' => $board,
      'rules' => $rules,
      'name' => $w . '(' . $n++ . ')',
    );
  }

  $board->worm_status_setup;

  while(1) {
    my @worms = grep {$_->is_alive} @{$board->{'worms'}};
    unless(@worms) { 
      print "All dead.\n" if $Debug;
      last;
    }
    foreach my $worm (@worms) { $worm->try_move }

  } continue {
    $board->{'generations'}++;
    $board->tick;
  }

  $board->end_game;
  return;
}

#--------------------------------------------------------------------------
# Something to do once everything's died -- override in derived class
sub end_game { return; }

#--------------------------------------------------------------------------
# Whatever needs to be done to set up the status for the newly created
#  worms -- override in derived class
sub worm_status_setup { return; }

#--------------------------------------------------------------------------
# Basically a wrapper around "use Modulename"
my %tried = ();
sub _try_use {
  # "Many men have tried..."  "They tried and failed?"  "They tried and died."
  my $module = $_[0];   # ASSUME sane module name!

  return $tried{$module} if exists $tried{$module};  # memoization

  { no strict;
    return($tried{$module} = 1)
     if defined(%{$class . "::VERSION"}) || defined(@{$class . "::ISA"});
    # we never use'd it, but there it is!
  }

  die "illegal module name \"$module\"\n"
    unless $module =~ m/^[-a-zA-Z0-9_:']+$/s;
  print " About to use $module ...\n" if $Debug;
  {
    local $SIG{'__DIE__'} = undef;
    eval "package Nullius; use $module";
  }
  if($@) {
    print "Error using $module \: $@\n" if $Debug > 1;
    $Use_Error = $@;
    return($tried{$module} = 0);
  } else {
    print " OK, $module is used\n" if $Debug;
    $Use_Error = '';
    return($tried{$module} = 1);
  }
}

#--------------------------------------------------------------------------
# Initialize space -- link up nodes and segments

sub init_grid {
  my $it = shift;

  my $Seg = $it->Seg; # class name we want to make segments in
  my $Node = $it->Node; # class name we want to make nodes in
  # die "No canvas?" unless $it->{'canvas'};

  my $cell = 0;

  # We use these two lists for comprehensive destruction.
  $it->{'nodes'} = [];
  $it->{'segments'} = [];

  # Set up the grid now. -- fill a space with rows of nodes.

  $it->{'node_space'} = [];  # this is a List of Lists.
   # usage: $node = $it->{'node_space'}[rownum][colnum]
  for(my $row = 0; $row < $it->{'cells_high'}; ++$row) {
    my $row_r = [];
    push @{$it->{'node_space'}}, $row_r;
    for(my $col = 0; $col < $it->{'cells_wide'}; ++$col) {
      my $node = $Node->new;
      push @$row_r, $node;
      push @{$it->{'nodes'}}, $node;
    }
    # Now link up each node in this row to its next, and back
    for(my $col = 0; $col < $it->{'cells_wide'}; ++$col) {
      my $here = $row_r->[$col];
      my $next = $row_r->[ ($col + 1) % scalar(@$row_r) ]; # % for wraparound
      $here->{'nodes_toward'}[3] = $next;
      $next->{'nodes_toward'}[0] = $here;
    }
  }

  # now link each node to its southern neighbor, and back
  for(my $row = 0; $row < $it->{'cells_high'}; ++$row) {
    my $here_row_r = $it->{'node_space'}[$row];
    my $next_row_r = $it->{'node_space'}[ ($row + 1) % scalar(@{$it->{'node_space'}})];
    for(my $col = 0; $col < $it->{'cells_wide'}; ++$col) {
      my $here = $here_row_r->[$col];
      my $south = $next_row_r->[$col];
      my $row_type_top = ((1 + $row) % 2);  # 1, 0, 1, 0, 1, 0, ...
      if($row_type_top) {  # Rows 0, 2, 4...
        $here->{'nodes_toward'}[4] = $south;
        $south->{'nodes_toward'}[1] = $here;
      } else {  # Rows 1, 3, 5...
        $here->{'nodes_toward'}[5] = $south;
        $south->{'nodes_toward'}[2] = $here;
      }
    }
  }

  # now link each node to its remaining neighbors
  for(my $row = 0; $row < $it->{'cells_high'}; ++$row) {
    my $here_row_r = $it->{'node_space'}[$row];
    my $next_row_r = $it->{'node_space'}[ ($row + 1) % scalar(@{$it->{'node_space'}})];
    for(my $col = 0; $col < $it->{'cells_wide'}; ++$col) {
      my $here = $here_row_r->[$col];
      my $row_type_top = ((1 + $row) % 2);  # 1, 0, 1, 0, 1, 0, ...
      if($row_type_top) {  # Rows 0, 2, 4...
        my $sw = $here->{'nodes_toward'}[4]{'nodes_toward'}[0];
        $here->{'nodes_toward'}[5] = $sw;
          $sw->{'nodes_toward'}[2] = $here;
      } else {  # Rows 1, 3, 5...
        my $se = $here->{'nodes_toward'}[5]{'nodes_toward'}[3];
        $here->{'nodes_toward'}[4] = $se;
          $se->{'nodes_toward'}[1] = $here;
      }
    }
  }

  my $Tri_height = $it->{'tri_height'};
  my $Tri_base = $it->{'tri_base'};
  my $Inner_Border = $it->{'inner_border'};

  # Create segments now, drawing them, and linking them to nodes.

  for(my $row = 0; $row < $it->{'cells_high'}; ++$row) {
    my $row_type_top = ((1 + $row) % 2);  # 1, 0, 1, 0, 1, 0, ...
    # There are two types of rows: top-type, and not.
    #
    print "Row $row; Row type top: $row_type_top\n" if $Debug > 2;
    for(my $col = 0; $col < $it->{'cells_wide'}; ++$col) {
      my $x_base = $Inner_Border + $col * $Tri_base;
      my $y_base = $Inner_Border + $row * $Tri_height;
      print " Row $row (t$row_type_top) Col $col | xb $x_base | yb $y_base\n"
        if $Debug > 2;
      my($s1, $s2, $s3);
      my $n = $it->{'node_space'}[$row][$col];
      if($row_type_top) { # rows 0,2,4,...
        #(top-type) 
        # 1 means draw this:          i.e., one item is:
        #           --- --- ---           N---n_d3   s1
        #           \ / \ / \ /            \ /      s2 s3
        #                                  n_d4
        my $n_d3 = $n->{'nodes_toward'}[3];
        my $n_d4 = $n->{'nodes_toward'}[4];

        $s1 = $Seg->new('coords' =>
                          [ $x_base, $y_base, $x_base + $Tri_base, $y_base ],
                        'board' => $it);
        # @{$s1->{'nodes'}} = ($n, $n_d3);
        $n->{'segments_toward'}[3] = $n_d3->{'segments_toward'}[0] = $s1;

        $s2 = $Seg->new('coords' =>
                          [ $x_base, $y_base,
                            $x_base + $Tri_base / 2, $y_base + $Tri_height ],
                        'board' => $it);
        # @{$s2->{'nodes'}} = ($n, $n_d4);
        $n->{'segments_toward'}[4] = $n_d4->{'segments_toward'}[1] = $s2;

        $s3 = $Seg->new( 'coords' =>
                            [ $x_base + $Tri_base / 2, $y_base + $Tri_height,
                                $x_base + $Tri_base, $y_base ],
                           'board' =>  $it);
        # @{$s3->{'nodes'}} = ($n_d3, $n_d4);
        $n_d3->{'segments_toward'}[5] = $n_d4->{'segments_toward'}[2] = $s3;

      } else { # rows 1,3,5,..
        #(top-type) 
        # 0 means draw this:          i.e., one item is:
        #             --- --- ---           N---nd_3     s1
        #           / \ / \ / \            / \        s2 s3
        #                                n_d5 n_d4
        my $n_d3 = $n->{'nodes_toward'}[3];
        my $n_d4 = $n->{'nodes_toward'}[4];
        my $n_d5 = $n->{'nodes_toward'}[5];

        $s1 = $Seg->new( 'coords' => 
                           [ $x_base + $Tri_base / 2, $y_base,
                             $x_base + $Tri_base * 1.5, $y_base ],
                         'board' => $it);
        # @{$s1->{'nodes'}} = ($n, $n_d3);
        $n->{'segments_toward'}[3] = $n_d3->{'segments_toward'}[0] = $s1;

        $s2 = $Seg->new('coords' =>
                           [ $x_base + $Tri_base / 2, $y_base,
                             $x_base, $y_base + $Tri_height ],
                        'board' => $it);
        # @{$s2->{'nodes'}} = ($n, $n_d5);
        $n->{'segments_toward'}[5] = $n_d5->{'segments_toward'}[2] = $s2;

        $s3 = $Seg->new('coords' =>
                           [ $x_base + $Tri_base, $y_base + $Tri_height,
                             $x_base + $Tri_base / 2, $y_base ],
                        'board' => $it);
        # @{$s3->{'nodes'}} = ($n, $n_d4);
        $n->{'segments_toward'}[4] = $n_d4->{'segments_toward'}[1] = $s3;

      }
      push @{$it->{'segments'}}, $s1, $s2, $s3;
    }
  }
  return;
}

#--------------------------------------------------------------------------
# Reset the grid, then draw
sub refresh_and_draw_grid {
  my $board = $_[0];
  if($board->{'segments'}) {
    foreach my $seg ( @{$board->{'segments'}} ) {
      $seg->refresh;
      $seg->draw;
    }
  } else {
    $board->init_grid;
    foreach my $seg ( @{$board->{'segments'}} ) {
      $seg->draw;
    }
  }
  return;
}

#--------------------------------------------------------------------------
# Null out contents of all segments, nodes, and worms

sub destroy {
  my $it = shift;
  print "Destroy called on $it\n" if $Debug;;
  if(ref($it->{'segments'})) {
    print "Destroying ", scalar(@{$it->{'segments'}}) ," segments...\n" if $Debug;
    foreach my $s (@{$it->{'segments'}}) { %$s = (); bless $s, 'DEAD'; }
  }
  if(ref($it->{'nodes'})) {
    print "Destroying ", scalar(@{$it->{'nodes'}}) ," nodes...\n" if $Debug;
    foreach my $s (@{$it->{'nodes'}}) { %$s = (); bless $s, 'DEAD'; }
  }
  if(ref($it->{'worms'})) {
    print "Destroying ", scalar(@{$it->{'worms'}}) ," worms...\n" if $Debug;
    foreach my $s (@{$it->{'worms'}}) { %$s = (); bless $s, 'DEAD'; }
  }
  %$it = ();
  bless $it, 'DEAD';
  print "Done destroying $it\n" if $Debug;

  return;
}

# *DESTROY = \&destroy;

#--------------------------------------------------------------------------

1;

__END__

