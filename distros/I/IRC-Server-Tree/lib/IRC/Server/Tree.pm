package IRC::Server::Tree;
$IRC::Server::Tree::VERSION = '0.061001';
## Array-type object representing a network map.

use strictures 1;
use Carp;

use Scalar::Util 'blessed', 'reftype';
use Storable     'dclone' ;

sub new {
  my $class = shift;

  my $self;

  BUILD: {
    last BUILD unless @_;

    if (@_ > 1) {
      ## Got a tree as a list
      ## (or the user did something dumb and will regret it later)
      $self = [ @_ ];
      last BUILD
    }

    my ($opt) = @_;

    if (blessed $opt && $opt->isa('IRC::Server::Tree') ) {
      ## Got a Tree. Clone it to break refs.
      $self = dclone($opt);
      last BUILD
    }

    if (reftype $opt eq 'ARRAY') {
      ## Got a Tree as a raw ARRAY.
      ## No clone; keep refs to allow darker forms of magic
      $self = $opt;
      last BUILD
    }

  }

  $self = [] unless $self;
  bless $self, $class
}

sub add_node_to_parent_ref {
  my ($self, $parent_ref, $name, $arrayref) = @_;

  $arrayref = [ @$arrayref ] if blessed $arrayref;

  push @$parent_ref, $name, ($arrayref||=[]);

  $arrayref
}

sub add_node_to_top {
  my ($self, $name, $arrayref) = @_;

  $self->add_node_to_parent_ref( $self, $name, $arrayref )
}

sub add_node_to_name {
  my ($self, $parent_name, $name, $arrayref) = @_;

  ## Can be passed $self like add_node_to_parent_ref
  ## Should just use add_node_to_top instead, though
  if ($parent_name eq $self) {
    return $self->add_node_to_top($name, $arrayref)
  }

  my $index_route =
    $self->trace_indexes($parent_name)
    or carp "Cannot add node to nonexistant parent $parent_name"
    and return;

  my $cur_ref = $self;

  while (my $idx = shift @$index_route) {
    $cur_ref = $cur_ref->[$idx]
  }

  ## Now in the ref belonging to our named parent.
  $self->add_node_to_parent_ref($cur_ref, $name, $arrayref || [] )
}

sub __t_add_to_hash {
  my ($parent_hash, $name, $node_ref) = @_;

  $parent_hash->{$name} = {}
    unless exists $parent_hash->{$name};

  my @list = @$node_ref;

  while (my ($nextname, $nextref) = splice @list, 0, 2 ) {
    __t_add_to_hash( $parent_hash->{$name}, $nextname, $nextref )
  }
}

sub as_hash {
  my ($self, $parent_ref) = @_;

  $parent_ref = $self unless defined $parent_ref;

  my $mapref = {};

  my @list = @$parent_ref;

  while (my ($name, $node_ref) = splice @list, 0, 2 ) {
    __t_add_to_hash( $mapref, $name, $node_ref )
  }

  $mapref
}

sub as_list {
  my ($self, $parent_ref) = @_;
  $parent_ref ||= $self;
  @{ $parent_ref }
}

sub child_node_for {
  my ($self, $server_name, $parent_ref) = @_;

  $parent_ref = $self unless defined $parent_ref;

  my $index_route =
    $self->trace_indexes($server_name, $parent_ref)
    or return;

  ## Recurse the list indexes.
  my $cur_ref = $parent_ref;

  while (my $idx = shift @$index_route) {
    $cur_ref = $cur_ref->[$idx]
  }

  $cur_ref
}

sub del_node_by_name {
  my ($self, $name, $parent_ref) = @_;

  ## Returns deleted node.

  my $index_route =
    $self->trace_indexes($name, $parent_ref)
    or carp "Cannot del nonexistant node $name"
    and return;

  my $idx_for_ref  = pop @$index_route;
  my $idx_for_name = $idx_for_ref - 1;

  my $cur_ref = $parent_ref || $self;
  while (my $idx = shift @$index_route) {
    $cur_ref = $cur_ref->[$idx]
  }

  ## Should now be in top-level container and have index values
  ## for the name/ref that we're deleting.
  my ($del_name, $del_ref) = splice @$cur_ref, $idx_for_name, 2;

  $del_ref
}

sub names_beneath {
  my ($self, $ref_or_name) = @_;

  ## Given either a ref (such as from del_node_by_name)
  ## or a name (ref is retrived), get the names of
  ## all the nodes in the tree under us.

  my $ref;
  if      (!$ref_or_name) {
    $ref = $self
  } elsif (ref $ref_or_name) {
    $ref = $ref_or_name || $self
  } else {
    $ref = $self->child_node_for($ref_or_name)
  }

  return unless $ref;

  my @list = @$ref;
  my @names;

  ## Iter and accumulate names.
  while (my ($node_name, $node_ref) = splice @list, 0, 2) {
    push(@names, $node_name);
    push(@names, @{ $self->names_beneath($node_ref) || [] });
  }

  [ @names ]
}

sub trace {
  my ($self, $server_name, $parent_ref, $dfs) = @_;

  ## A list of named hops to the target.
  ## The last hop is the target's name.

  $parent_ref = $self unless defined $parent_ref;

  my $index_route =
    $dfs ?
      $self->trace_indexes_dfs($server_name, $parent_ref)
      : $self->trace_indexes($server_name, $parent_ref) ;

  return unless $index_route;

  $self->path_by_indexes($index_route, $parent_ref)
}

sub trace_dfs {
  my ($self, $server_name, $parent_ref) = @_;

  $parent_ref = $self unless defined $parent_ref;

  my $index_route = $self->trace_indexes_dfs($server_name, $parent_ref)
    or return;

  $self->path_by_indexes($index_route, $parent_ref)
}

sub path_by_indexes {
  my ($self, $index_array, $parent_ref) = @_;
  ## Walk a trace_indexes array and retrieve names.
  ## Used by ->trace()

  my @indexes = @$index_array;

  my @names;
  my $cur_ref = $parent_ref || $self;
  while (my $idx = shift @indexes) {
    push @names, $cur_ref->[ $idx - 1 ];
    $cur_ref = $cur_ref->[$idx];
  }

  [ @names ]
}

sub trace_indexes {
  my ($self, $server_name, $parent_ref) = @_;

  ## An example of breadth-first search.
  ##
  ## We explore each path in the current node, and as we find new paths,
  ## we queue them to be explored after the current iteration.
  ##
  ## This is in contrast to depth-first techniques, where you recursively
  ## explore each deeper reference as you hit it, with the path-so-far
  ## included in the call, until you have the path desired.
  ## See trace_indexes_dfs() for a DFS alternative.
  ##
  ## This is useful for cases like an IRC server tree, where there is
  ## an essentially arbitrary structure to the tree; any node may have
  ## any arbitrary number of child nodes (ad infinitum) and we have no
  ## actual hints as to the possible path. Therefore we cannot predict
  ## the most performant path-finding mechanism -- but we can optimize
  ## towards finding paths closest to us more quickly.
  ##
  ## Defaults to operating on $self
  ## Return indexes into arrays describing the path
  ## Return value is the full list of indexes to get to the array
  ## belonging to the named server
  ##  i.e.:
  ##   1, 3, 1
  ##   $parent_ref->[1] is a ref belonging to an intermediate hop
  ##   $parent_ref->[1]->[3] is a ref belonging to an intermediate hop
  ##   $parent_ref->[1]->[3]->[1] is the ref belonging to the target hop
  ## Subtracting one from an index will get you the NAME value.

  ## A start-point.
  my @queue = ( '' => ($parent_ref || $self) );

  ## Our seen routes.
  my %route;

  my $parent_idx = 0;

  PARENT: while (my ($parent_name, $parent_ref) = splice @queue, 0, 2) {

    return [ $parent_idx+1 ] if $parent_name eq $server_name;

    my @leaf_list = @$parent_ref;
    my $child_idx = 0;

    CHILD: while (my ($child_name, $child_ref) = splice @leaf_list, 0, 2) {

      unless ( $route{$child_name} ) {
        $route{$child_name} =
          [ @{ $route{$parent_name}||[] }, $child_idx+1 ];

        return \@{$route{$child_name}} if $child_name eq $server_name;

        push @queue, $child_name, $child_ref;
      }

      $child_idx += 2;
    }  ## CHILD

    $parent_idx += 2;
  }  ## PARENT

  return
}

=pod

=for Pod::Coverage trace_indexes_dfs

=cut

sub trace_indexes_dfs {
  my ($self, $server_name, $parent_ref, $route) = @_;

  ## Depth first node finder.
  ##  For every child node found, call self with current route.

  $route      = [] unless $route;
  $parent_ref = $self unless $parent_ref;

  my @list = @$parent_ref;

  my $cur_idx = 1;
  while (my ($name, $subnode) = splice @list, 0, 2) {
    return [ @$route, $cur_idx ] if $name eq $server_name;

    my $next = $self->trace_indexes_dfs(
      $server_name, $subnode,
      [ @$route, $cur_idx ]
    );
    return $next if $next;

    $cur_idx += 2;
  }

  return
}

sub print_map {
  my ($self, $parent_ref) = @_;

  $parent_ref = $self unless defined $parent_ref;

  my $indent = 1;

  my $recurse_print;
  $recurse_print = sub {
    my ($name, $ref) = @_;
    my @nodes = @$ref;

    if ($indent == 1 || scalar @nodes) {
      $name = "* $name";
    } else {
      $name = "` $name";
    }

    print {*STDOUT} ( (' ' x $indent) . "$name\n" );

    while (my ($next_name, $next_ref) = splice @nodes, 0, 2) {
      $indent += 3;
      $recurse_print->($next_name, $next_ref);
      $indent -= 3;
    }
  };

  my @list = @$parent_ref;
  warn "No refs found\n" unless @list;
  while (my ($parent_name, $parent_ref) = splice @list, 0, 2) {
    $recurse_print->($parent_name, $parent_ref);
    $indent = 1;
  }

  return 1
}

1;

=pod

=head1 NAME

IRC::Server::Tree - Manipulate an IRC "spanning tree"

=head1 SYNOPSIS

  ## Basic path-tracing usage:
  my $tree = IRC::Server::Tree->new;

  $tree->add_node_to_top($_) for qw/ peerA peerB /;

  $tree->add_node_to_name('peerA', 'leafA');
  $tree->add_node_to_name('peerA', 'leafB');

  $tree->add_node_to_name('peerB', 'hubA');
  $tree->add_node_to_name('hubA', 'peerB');

  ## ARRAY of hop names between root and peerB:
  my $hop_names = $tree->trace( 'peerB' );

See L<IRC::Server::Tree::Network> for a simpler and more specialized 
interface to the tree.

See the DESCRIPTION for a complete method list.

=head1 DESCRIPTION

An IRC network is defined as a 'spanning tree' per RFC1459; this module 
is an array-type object representing such a tree, with convenient path 
resolution methods for determining route "hops" and extending or shrinking 
the tree.

See L<IRC::Server::Tree::Network> for higher-level 
(and simpler) methods pertaining to manipulation of an IRC network 
specifically; a Network instance also provides an optional 
memory-for-speed tradeoff via memoization of traced paths.

An IRC network tree is essentially unordered; any node can have any 
number of child nodes, with the only rules being that:

=over

=item *

The tree remains a tree (it is acyclic; there is only one route between 
any two nodes, and no node has more than one parent)

=item *

No two nodes can share the same name.

=back

Currently, this module doesn't enforce the listed rules for performance 
reasons, but things will break if you add non-uniquely-named nodes. Be 
warned. In fact, this module doesn't sanity 
check very much of anything; an L<IRC::Server::Tree::Network> does much 
more to validate the tree and passed arguments.

A new Tree can be created from an existing Tree:

  my $new_tree = IRC::Server::Tree->new( $old_tree );

In principle, the general structure of the tree is your average deep 
array-of-arrays:

  $self => [
    hubA => [
      leafA => [],
      leafB => [],
    ],

    hubB => [
      leafC => [],
      leafD => [],
    ],
  ],

The methods provided below can be used to manipulate the tree and 
determine hops in a path to an arbitrary node using either breadth-first 
or depth-first search.

Currently routes are not memoized; that's left to a higher layer or 
subclass.

=head2 new

Create a new network tree:

  my $tree = IRC::Server::Tree->new;

Create a new network tree from an old one or part of one (see 
L</child_node_for> and L</del_node_by_name>):

  my $tree = IRC::Server::Tree->new( $old_tree );

(Note that this will clone the old Tree object.)

Optionally create a tree from an ARRAY, if you really know what 
you're doing:

  my $tree = IRC::Server::Tree->new(
    [
      hubA => [
        hubB => [
          hubBleaf1 => [],
        ],
        leaf1 => [],
        leaf2 => [],
      ],
    ],
  );

=head2 add_node_to_parent_ref

  ## Add empty node to parent ref:
  $tree->add_node_to_parent_ref( $parent_ref, $new_name );
  ## Add existing node to parent ref:
  $tree->add_node_to_parent_ref( $parent_ref, $new_name, $new_ref );

Adds an empty or preexisting node to a specified parent reference.

Also see L</add_node_to_top>, L</add_node_to_name>

=head2 add_node_to_top

  $tree->add_node_to_top( $new_name );
  $tree->add_node_to_top( $new_name, $new_ref );

Also see L</add_node_to_parent_ref>, L</add_node_to_name>

=head2 add_node_to_name

  $tree->add_node_to_name( $parent_name, $name );
  $tree->add_node_to_name( $parent_name, $name, $new_ref );

Adds an empty or specified node to the specified parent name.

For example:

  $tree->add_node_to_top( 'MyHub1' );
  $tree->add_node_to_name( 'MyHub1', 'MyLeafA' );

  ## Existing nodes under our new node
  my $new_node = [ 'MyLeafB' => [] ];
  $tree->add_node_to_name( 'MyHub1', 'MyHub2', $new_node );

=head2 as_hash

  my $hash_ref = $tree->as_hash;
  my $hash_ref = $tree->as_hash( $parent_ref );

Get a (possibly deep) HASH describing the state of the tree underneath 
the specified parent reference, or the entire tree if none is specified.

For example:

  my $hash_ref = $tree->as_hash( $self->child_node_for('MyHub1') );

Also see L</child_node_for>

=head2 as_list

  my @tree = $tree->as_list;
  my @tree = $tree->as_list( $parent_ref );

Returns the tree in list format.

(L</as_hash> is likely to be more useful.)

=head2 child_node_for

  my $child_node = $tree->child_node_for( $parent_name );
  my $child_node = $tree->child_node_for( $parent_name, $start_ref );

Finds and returns the named child node from the tree.

Starts at the root of the tree or the specified parent reference.

=head2 del_node_by_name

  $tree->del_node_by_name( $parent_name );
  $tree->del_node_by_name( $parent_name, $start_ref );

Finds and deletes the named child from the tree.

Returns the deleted node.

=head2 names_beneath

  my $names = $tree->names_beneath( $parent_name );
  my $names = $tree->names_beneath( $parent_ref );

Return an ARRAY of all names in the tree beneath the specified parent 
node.

Takes either the name of a node in the tree or a reference to a node.

=head2 path_by_indexes

  my $names = $tree->path_by_indexes( $index_route );
  my $names = $tree->path_by_indexes( $index_route, $parent_ref );

Given an array of index hops as retrieved by L</trace_indexes>, retrieve 
the name for each hop.

This is mostly used internally by L</trace>.

=head2 print_map

  $tree->print_map;
  $tree->print_map( $start_ref );

Prints a visualization of the network map to STDOUT.

=head2 trace

  my $names = $tree->trace( $parent_name );
  my $names = $tree->trace( $parent_name, $start_ref );
  my $names = $tree->trace( $parent_name, $start_ref, 'dfs' );

Returns an ARRAY of the names of every hop in the path to the 
specified parent name.

Starts tracing from the root of the tree unless a parent node reference 
is also specified.

The last hop returned is the target's name.

Specifying a true value as a third argument is the same as calling 
L</trace_dfs>. Defaults to breadth-first as described in 
L</trace_indexes>.

=head2 trace_dfs

A convenience method for using depth-first tracing. This is likely to be less
efficient than the default breadth-first approach for most network layouts.

This is the same as specifying a true third argument to L</trace>.

=head2 trace_indexes

Primarily intended for internal use. This is the BFS/DFS search 
that other methods use to find a node. There is nothing very 
useful you can do with this externally except count hops; it is documented 
here to show how path resolution works.

Returns an ARRAY consisting of the index of every hop taken to get to 
the node reference belonging to the specified node name starting from 
the root of the tree or the specified parent node reference.

Given a network:

  hubA
    leafA
    leafB
    hubB
      leafC
      leafD

C<< trace_indexes(B<'leafD'>) >> would return:

  [ 1, 5, 1 ]

These are the indexes into the node references (arrays) owned by each 
hop, including the last hop. Retrieving their names requires 
subtracting one from each index; L</trace> handles this.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
