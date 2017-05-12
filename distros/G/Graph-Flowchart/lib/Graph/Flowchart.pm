#############################################################################
# Generate flowcharts as a Graph::Easy object
#

package Graph::Flowchart;

$VERSION = '0.11';

use strict;

use Graph::Easy;
use Graph::Flowchart::Node qw/
  N_IF N_THEN N_ELSE
  N_END N_START N_BLOCK N_JOINT
  N_FOR N_CONTINUE N_GOTO
  /;

#############################################################################
#############################################################################

sub new
  {
  my $class = shift;

  my $self = bless {}, $class;

  my $args = $_[0]; $args = { @_ } if ref($args) ne 'HASH';

  $self->_init($args);
  }

sub _init
  {
  my ($self, $args) = @_;

  $self->{graph} = Graph::Easy->new();

  # make the chart flow down
  my $g = $self->{graph};
  $g->set_attribute('flow', 'down');

  # set class defaults
  $g->set_attribute('node.joint', 'shape', 'point');
  $g->set_attribute('node.start', 'border-style', 'bold');
  $g->set_attribute('node.end', 'border-style', 'bold');
  for my $s (qw/block if for/)
    {
    $g->set_attribute("node.$s", 'border-style', 'solid');
    }
#  $g->set_attribute('edge.true', 'flow', 'front');
#  $g->set_attribute('edge.false', 'flow', 'front');
   
  # add the start node
  $self->{_last} = $self->new_block ('start', N_START() );

  $g->add_node($self->{_last});
#  $g->debug(1);

  $self->{_first} = $self->{_last};
  $self->{_cur} = $self->{_last};
  
  $self->{_group} = undef;

  $self;
  }

sub as_graph
  {
  # return the internal Graph::Easy object
  my $self = shift;

  $self->{graph};
  }

sub as_ascii
  {
  my $self = shift;

  $self->{graph}->as_ascii();
  }

sub as_html_file
  {
  my $self = shift;

  $self->{graph}->as_html_file();
  }

sub as_boxart
  {
  my $self = shift;

  $self->{graph}->as_boxart();
  }

#############################################################################

sub last_block
  {
  # get/set the last block
  my $self = shift;

  $self->{_last} = $_[0] if ref($_[0]) && $_[0]->isa('Graph::Flowchart::Node');

  $self->{_last};
  }

sub current_block
  {
  # get/set the current insertion point
  my $self = shift;

  $self->{_cur} = $_[0] if ref($_[0]) && $_[0]->isa('Graph::Flowchart::Node');

  $self->{_cur};
  }

sub current
  {
  # get/set the current insertion point
  my $self = shift;

  $self->{_cur} = $_[0] if ref($_[0]) && $_[0]->isa('Graph::Flowchart::Node');

  $self->{_cur};
  }

sub first_block
  {
  # get/set the first block
  my $self = shift;

  $self->{_first} = $_[0] if ref($_[0]) && $_[0]->isa('Graph::Flowchart::Node');

  $self->{_first};
  }

sub make_current
  {
  # set the current insertion point, and convert it to a joint
  my $self = shift;

  $self->{_cur} = $_[0] if ref($_[0]) && $_[0]->isa('Graph::Flowchart::Node');

  $self->{_cur}->{_type} = N_JOINT();

  $self->{_cur};
  }

#############################################################################

sub add_group
  {
  # add a group, and set it as current.
  my ($self, $name) =@_;

  my $g = $self->{graph};

  $self->{_group} = $g->add_group($name);
  }
  
sub no_group
  {
  # we are now outside the group, so forget it
  my $self = shift;

  $self->{_group} = undef;
  }

#############################################################################

sub new_block
  {
  my ($self, $text, $type, $label) = @_;

  Graph::Flowchart::Node->new( $text, $type, $label, $self->{_group} );
  }

#############################################################################

sub merge_blocks
  {
  # if possible, merge the given two blocks
  my ($self, $first, $second) = @_;

  # see if we should merge the blocks

  return $second
	if ( ($first->{_type} != N_JOINT()) &&
	     ($first->{_type} != $second->{_type} ) );

  my $label = $first->label();
  $label .= '\n' unless $label eq '';
  $label .= $second->label();

# print STDERR "# merge $first->{name} ", $first->label(), " $second->{name} ", $second->label(),"\n";

  $first->sub_class($second->sub_class()) if $first->{_type} == N_JOINT;

  # quote chars
  $label =~ s/([^\\])\|/$1\\\|/g;	# '|' to '\|' ("|" marks an attribute split)
  $label =~ s/([^\\])\|/$1\\\|/g;	# do it twice for "||"

  $first->set_attribute('label', $label);

  $first->{_type} = $second->{_type};

  # drop second node from graph
  my $g = $self->{graph};
  $g->merge_nodes($first, $second);

  $self->{_cur} = $first;
  }

#############################################################################

sub connect
  {
  my ($self, $from, $to, $edge_label, $edge_class) = @_;

  my $g = $self->{graph};
  my $edge = $g->add_edge($from, $to);

  $edge->set_attribute('label', $edge_label) if defined $edge_label;
  $edge->sub_class($edge_class) if defined $edge_class;

  $edge;
  }

sub insert_block
  {
  # Insert a block to the current (or $where) block. Any outgoing connections
  # from $where are moved to the new block (unless they are merged).
  my ($self, $block, $where) = @_;

  # XXX TODO: if $where is a N_BLOCK() and $block a scalar, then
  # simple append $block to $where->label() and spare us the
  # creation of a new block, and then merging it into $where.

  $block = $self->new_block($block, N_BLOCK() ) unless ref $block;

  $where = $self->{_cur} unless defined $where;
  my $g = $self->{graph};
  $g->add_edge($where, $block);

  my $old = $block;
  $block = $self->merge_blocks($where, $block);

  if ($block != $old)
    {
    # where not merged, so move outgoing connections from $where to $block

    for my $e (values %{$where->{edges}})
      {
      # move the edge, unless is an incoming edge or a selfloop
      $e->start_at($block) if $e->{from} == $where && $e->{to} != $where;
      }
    }
 
  $self->{_cur} = $block;			# set new _cur and return it
  }

sub add_block
  {
  # Add a block to the current (or $where) block. Any outgoing connections
  # are left where they are, e.g. starting at $where.

  my ($self, $block, $where, $edge_label) = @_;

  # XXX TODO: if $where is a N_BLOCK() and $block a scalar, then
  # simple append $block to $where->label() and spare us the
  # creation of a new block, and then merging it into $where.

  $block = $self->new_block($block, N_BLOCK() ) unless ref $block;

  $where = $self->{_cur} unless defined $where;
  my $g = $self->{graph};
  $g->add_edge($where, $block, $edge_label);

  $block = $self->merge_blocks($where, $block);

  $self->{_cur} = $block;			# set new _cur and return it
  }
	
sub add_new_block
  {
  # shortcut for "add_block(new_block(...))"
  my ($self, $text, $type, $label, $where, $edge_label) = @_;

  my $block = $self->new_block($text, $type, $label);

  $self->add_block($block,$where);
  }

sub insert_new_block
  {
  # shortcut for "insert_block(new_block(...))"
  my ($self, $text, $type, $label, $where) = @_;

  my $block = $self->new_block($text, $type, $label);

  $self->insert_block($block,$where);
  }

sub add_new_joint
  {
  # shortcut for "add_block(new_block(.., N_JOINT()))"
  my ($self, $where) = @_;

  my $block = $self->new_block('', N_JOINT());
  $self->add_block($block,$where);
  }

sub insert_new_joint
  {
  # shortcut for "insert_block(new_block(.., N_JOINT()))"
  my ($self, $where) = @_;

  my $block = $self->new_block('', N_JOINT());
  $self->insert_block($block,$where);
  }

sub add_joint
  {
  my $self = shift;

  my $g = $self->{graph};

  my $joint = $self->new_block('', N_JOINT());
  $g->add_node($joint);

  # connect the requested connection points to the joint
  for my $node ( @_ )
    {
    $g->add_edge($node, $joint);
    }

  $joint;
  }

sub find_target
  {
  my ($self, $label) = @_;

  my $g = $self->{graph};

  for my $n (values %{$g->{nodes}})
    {
    return $n if defined $n->{_label} && $n->{_label} eq $label;	# found
    }
  undef;					# not found
  }

sub collapse_joints
  {
  # find any left-over joints and remove them
  my ($self) = @_;

  my $g = $self->{graph};

  my @joints;
  for my $n (values %{$g->{nodes}})
    {
    push @joints, $n if $n->{_type} == N_JOINT();
    }

  for my $j (@joints)
    {
    # a joint should have only one successor
    my @out = $j->outgoing();
    next if @out != 1;

    my $o = $out[0]->{to};

    # get the label from the outgoing edge, if any
    my $label = $out[0]->label();

    # "next" to ", next"
    $label = ', ' . $label if $label ne '';

    # get all incoming edges
    my @in = $j->incoming();

    # now for each incoming edge, add one bypass
    for my $e (@in)
      {
      my $from = $e->{from}; 
      my $l = $e->label() . $label;

      $g->add_edge($e->{from}, $o, $l);
      }
    
    # finally get rid of the joint (including all edges)
    $g->del_node($j);
    }

  $self;
  }

#############################################################################

sub start_node
  {
  # return the START node
  my $self = shift;

  $self->{_first};
  }

sub end_node
  {
  # return the END node (or, before finish is called, the current last node)
  my $self = shift;

  $self->{_last};
  }

sub finish
  {
  my ($self, $where) = @_;

  my $end = $self->new_block ( 'end', N_END() );
  $end = $self->add_block ($end, $where);
  $self->{_last} = $end;

  $self->collapse_joints();

  # If there is only one connection from START, and it goes to END, delete
  # both blocks. This makes things like "sub foo { $a++; }" look better.
  my $start = $self->{_first};

  my $g = $self->{graph};

  # if we only have two node, then we parsed something like '' and let it be:
  if ($g->nodes() > 2)
    {
    # XXX TODO: use ->edges() and Graph::Easy 0.50
    my @edges = values %{$start->{edges}};
    if (@edges == 1 && $edges[0]->to() == $end)
      {
      $g->del_node($start);
      $g->del_node($end);
      }
    }

  $self;
  }

#############################################################################
#############################################################################
# convience methods, for constructs like if, for etc

sub add_jump
  {
  my ($self, $text, $type, $label, $target, $where) = @_;

  # find target if it was not specified as block
  $target = $self->find_target($target) unless ref($target);

  if (!defined $target)
    {
    $target = $self->new_block ('', N_JOINT(), $target);
    $self->{graph}->add_node($target);
    }

  my $jump = $self->insert_new_block($text, $type);

  my $l = $target->{_label}; $l = '' unless defined $l;
  $l = ' '.$l if $l ne '';

  # connect to the target block
  my $edge = $self->connect($jump, $target, "$type$l", $type);
  $self->{_cur} = $target;

  return ($jump,$target) if wantarray;

  $jump;
  }

sub add_if_then
  {
  my ($self, $if, $then, $where) = @_;
 
  $if = $self->new_block($if, N_IF()) unless ref $if;
  $then = $self->new_block($then, N_THEN()) unless ref $then;

  $where = $self->{_cur} unless defined $where;

  $if = $self->insert_block ($if, $where);

  $self->connect($if, $then, 'true', 'true');

  # then --> '*'
  $self->{_cur} = $self->add_joint($then);

  # if -- false --> '*'
  $self->connect($if, $self->{_cur}, 'false', 'false');

  return ($if, $then, $self->{_cur}) if wantarray;

  $self->{_cur};
  }

sub add_if_then_else
  {
  my ($self, $if, $then, $else, $where) = @_;

  return $self->add_if_then($if,$then,$where) unless defined $else;
 
  $if = $self->new_block($if, N_IF()) unless ref $if;
  $then = $self->new_block($then, N_THEN()) unless ref $then;
  $else = $self->new_block($else, N_ELSE()) unless ref $else;

  $where = $self->{_cur} unless defined $where;

  $if = $self->insert_block ($if, $where);
  
  $self->connect($if, $then, 'true', 'true');
  $self->connect($if, $else, 'false', 'false');

  # then --> '*', else --> '*'
  $self->{_cur} = $self->add_joint($then, $else);

  return ($if, $then, $else, $self->{_cur}) if wantarray;
  $self->{_cur};
  }

#############################################################################
# for loop

sub add_for
  {
  # add a for (my $i = 0; $i < 12; $i++) style loop
  my ($self, $init, $while, $cont, $body, $where) = @_;
 
  $init = $self->new_block($init, N_FOR()) unless ref $init;
  $while = $self->new_block($while, N_IF()) unless ref $while;
  $cont = $self->new_block($cont, N_CONTINUE()) unless ref $cont;
  $body = $self->new_block($body, N_BLOCK()) unless ref $body;

  # init -> if $while --> body --> cont --> (back to if)

  $where = $self->{_cur} unless defined $where;

  $init = $self->add_block ($init, $where);
  $while = $self->add_block ($while, $init);
  
  # Make the for-head node a bigger because it has two edges leaving it, and
  # one coming back and we want two of them on one side for easier layouts:
  $while->set_attribute('rows',2);

  $self->connect($while, $body, 'true', 'true');

  $self->connect($body, $cont);
  $self->connect($cont, $while);

  my $joint = $self->add_joint();
  $self->connect($while, $joint, 'false', 'false');

  $self->{_cur} = $joint;

  ($joint, $body, $cont);
  }

sub add_foreach
  {
  # add a for (@list) style loop
  my ($self, $list, $body, $cont, $where) = @_;
 
  $list = $self->new_block($list, N_FOR()) unless ref $list;
  $body = $self->new_block($body, N_BLOCK()) unless ref $body;
  $cont = $self->new_block($cont, N_CONTINUE()) if defined $cont && !ref $cont;

  # list --> body --> cont --> (back to list)

  $where = $self->{_cur} unless defined $where;

  $list = $self->add_block ($list, $where);

  # Make the for-head node a bigger because it has two edges leaving it, and
  # one coming back and we want two of them on one side for easier layouts:
  $list->set_attribute('rows',2);

  $self->connect($list, $body, 'true', 'true');

  if (defined $cont)
    {
    $self->connect($body, $cont);
    $self->connect($cont, $list);
    }
  else
    {
    $self->connect($body, $list);
    }

  my $joint = $self->add_joint();
  $self->connect($list, $joint, 'false', 'false');

  $self->{_cur} = $joint;

  ($joint, $body, $cont);
  }

#############################################################################
# while loop

sub add_while
  {
  # add a "while ($i < 12) { body } continue { cont }" style loop
  my ($self, $while, $body, $cont, $where) = @_;
 
  $while = $self->new_block($while, N_IF()) unless ref $while;

  # no body?
  $body = $self->new_block( '', N_JOINT()) if !defined $body;
  $body = $self->new_block($body, N_BLOCK()) unless ref $body;

  $cont = $self->new_block($cont, N_CONTINUE()) if defined $cont && !ref $cont;

  # if $while --> body --> cont --> (back to if)

  $where = $self->{_cur} unless defined $where;

  $while = $self->add_block ($while, $where);
  
  # Make the head node a bigger because it has two edges leaving it, and
  # one coming back and we want two of them on one side for easier layouts:
  $while->set_attribute('rows',2);

  $self->connect($while, $body, 'true', 'true');

  if (defined $cont)
    {
    $cont = $self->add_block ($cont, $body);
    $self->connect($cont, $while);
    }
  else 
    { 
    $self->connect($body, $while);
    }

  my $joint = $self->add_joint();
  $self->connect($while, $joint, 'false', 'false');

  $self->{_cur} = $joint;

  ($joint, $body, $cont);
  }

sub add_until
  {
  # add a "until ($i < 12) { body } continue { cont }" style loop
  my ($self, $while, $body, $cont, $where) = @_;
 
  $while = $self->new_block($while, N_IF()) unless ref $while;

  # no body?
  $body = $self->new_block( '', N_JOINT()) if !defined $body;
  $body = $self->new_block($body, N_BLOCK()) unless ref $body;

  $cont = $self->new_block($cont, N_CONTINUE()) if defined $cont && !ref $cont;

  # if $while --> body --> cont --> (back to if)

  $where = $self->{_cur} unless defined $where;

  $while = $self->add_block ($while, $where);
  
  # Make the head node a bigger because it has two edges leaving it, and
  # one coming back and we want two of them on one side for easier layouts:
  $while->set_attribute('rows',2);

  $self->connect($while, $body, 'false', 'false');

  if (defined $cont)
    {
    $cont = $self->add_block ($cont, $body);
    $self->connect($cont, $while);
    }
  else 
    { 
    $self->connect($body, $while);
    }

  my $joint = $self->add_joint();
  $self->connect($while, $joint, 'true', 'true');

  $self->{_cur} = $joint;

  ($joint, $body, $cont);
  }

1;
__END__

=head1 NAME

Graph::Flowchart - Generate easily flowcharts as Graph::Easy objects

=head1 SYNOPSIS

	use Graph::Flowchart;

	my $flow = Graph::Flowchart->new();

	print $flow->as_ascii();

=head1 DESCRIPTION

This module lets you easily create flowcharts as Graph::Easy
objects. This means you can output your flowchart as HTML,
ASCII, Boxart (unicode drawing) or SVG.

X<graph>
X<ascii>
X<html>
X<svg>
X<boxart>
X<unicode>
X<flowchart>
X<diagram>

=head2 Classes

The nodes constructed by the various C<add_*> methods will set the subclass
of the node according to the following list:

=over 2

=item start

The start block.

=item end

The end block, created by C<finish()>.

=item block

Orindary code blocks, f.i. from C<$b = 9;>.

=item if, for, while, until

Blocks for the various constructs for conditional and loop constructs.

=item sub

For sub routine declarations.

=item use

For C<use>, C<no> and C<require> statements.

=item goto, break, return, next, last, continue

Blocks for the various constructs for jumps/returns.

=item true, false, goto, call, return, break, next, continue

Classes for edges of the true and false if-branches, and for goto, as well
as sub routine calls.

=back

Each class will get some default attributes, like C<if> constructs having
a diamond-shape.

You can override the graph appearance most easily by changing the
(sub)-class attributes:

	my $chart = Graph::Flowchart->new();

	$chart->add_block('$a = 9;');
	$chart->add_if_then('$a == 9;', '$b = 1;');
	$chart->finish();

	my $graph = $chart->as_graph();

Now C<$graph> is a C<Graph::Easy> object and you can manipulate the
class attributes like so:

	$graph->set_attribute('node.if', 'fill', 'red');
	$graph->set_attribute('edge.true', 'color', 'green');
	print $graph->as_html_file();

This will color all conditional blocks red, and edges that represent
the C<true> branch green.
 
=head1 EXPORT

Exports nothing.

=head1 METHODS

All block-inserting routines on the this model will insert the
block on the given position, or if this is not provided,
on the current position. After inserting the blocks, the current
position will be updated.

In addition, the newly inserted block(s) might be merged with
blodcks at the current position.

=head2 new()

	my $grapher = Graph::Flowchart->new();

Creates a new C<Graph::Flowchart> object.

=head2 as_graph()

	my $graph = $grapher->as_graph();

Return the internal data structure as C<Graph::Easy> object.

=head2 as_ascii()

	print $grapher->as_ascii();

Returns the flow chart as ASCII art drawing.

=head2 as_boxart()

	print $grapher->as_boxart();

Returns the flow chart as a Unicode boxart drawing.

=head2 as_html_file()

	print $grapher->as_html_file();

Returns the flow chart as entire HTML page.

=head2 current_block()

	my $insertion = $grapher->current_block();	# get
	$grapher->current_block( $block);		# set

Get or set the current block in the flow chart, e.g. where new code blocks
will be inserted by the C<add_*> methods.

Needs a C<Graph::Flowchart::Node> as argument, which is usually
an object returned by one of the C<add_*> methods.

=head2 current()

C<current()> is an alias for C<current_block()>.

=head2 make_current()

	$grapher->make_current($block);

Set the given block as current, and convert it to a joint.

=head2 first_block()

	my $first = $grapher->first_block();		# get
	$grapher->first_block( $block );		# set

Get or set the first block in the flow chart, usually the 'start' block.

Needs a C<Graph::Flowchart::Node> as argument, which is usually
an object returned by one of the C<add_*> methods.

=head2 last_block()

	my $last = $grapher->last_block();		# get
	$grapher->last_block( $block);			# set

Get or set the last block in the flow chart, usually the block where you
last added something via one of the C<add_*> routines.

Needs a C<Graph::Flowchart::Node> as argument, which is usually
an object returned by one of the C<add_*> methods.

The returned block will only be the last block if you call C<finish()>
beforehand.

=head2 start_node()

	my $start = $grapher->start_node();

Returns the START node. See also L<first_block()>.

=head2 end_node()

	my $end = $grapher->end_node();

Returns the END node. See also L<last_block()>.

=head2 finish()

	my $last = $grapher->finish( $block );
	my $last = $grapher->finish( );

Adds an end-block. If no parameter is given, uses the current position,
otherwise appends the end block to the given C<$block>. See also
C<current_block>. Will also update the position of C<last_block> to point
to the newly added block, and return this block.

=head2 new_block()

	my $block = $grapher->new_block( $text, $type );
	my $block = $grapher->new_block( $text, $type, $label );

Creates a new block from the given text and type. The type is one
of the C<N_*> from C<Graph::Flowchart::Node>.

The optional label gives the label name, which can be used by goto
constructs as target node. See also C<find_target()>.

=head2 find_target()

	my $target = $grapher->find_target( $label );

Given the label C<$label>, find the block that has this text as label
and returns it. Returns undef if the block doesn't exists yet.

=head2 add_group()

	$grapher->add_group($group_name);

Add a group to the flowchart, and set it as current.

=head2 no_group()

	$grapher->no_group();

Forget the current group.

=head2 add_block()

	my $current = $grapher->add_block( $block );
	my $current = $grapher->add_block( $block, $where );

Add the given block. See C<new_block> on creating the block before hand.

The optional C<$where> parameter is the point where the code will be
inserted. If not specified, it will be appended to the current block,
see C<current_block>.

Returns the newly added block as current.

Example:

        +---------+
    --> | $a = 9; | -->
        +---------+

=head2 add_new_block()

	my $new = $grapher->add_new_block( $text, $type, $label, $where);

Creates a new block, and adds it to the flowchart. Might merge the new block
into the current one, and then returns the new current block.

=head2 add_new_joint()

	my $joint = $grapher->add_new_joint();
	my $joint = $grapher->add_new_joint($where);

Is a shortcut for C<< add_block(new_block('', N_JOINT())) >> and creates and
adds a joint to the flowchart. The optional parameter C<$where> takes the
block where to attach the join to.

=head2 insert_block

	my $new = $grapher->insert_block($block, $where);

Insert a block to the current (or C<$where>) block. Any outgoing connections
from C<$where> are moved to the new block (unless the blocks are merged).

=head2 insert_new_block

	my $new = $grapher->insert_new_block($where);

A short cut for:

	my $block = $grapher->new_block( ... );
	my $new = $grapher->insert_block($block, $where);

See C<insert_block()>.

=head2 insert_new_joint

	my $new = $grapher->insert_new_joint($where);

A short cut for:

	my $joint = $grapher->add_joint( ... );
	my $new = $grapher->insert_block($joint, $where);

See C<insert_block()>.

=head2 connect()

	my $edge = $grapher->connect( $from, $to );
	my $edge = $grapher->connect( $from, $to, $edge_label );
	my $edge = $grapher->connect( $from, $to, $edge_label, $edge_class );

Connects two blocks with an edge, setting the optional edge label and edge
class.

Returns the C<Graph::Easy::Edge> object for the connection.

=head2 merge_blocks()

	$grapher->merge_blocks($first,$second);

If possible, merge the given two blocks into one block, keeping all connections
to the first, and all from the second. Any connections between the two
blocks is dropped.

Example:

        +---------+     +---------+
    --> | $a = 9; | --> | $b = 2; | -->
        +---------+     +---------+

This will be turned into:

        +---------+ 
    --> | $a = 9; | -->
        | $b = 2; | 
        +---------+

=head2 collapse_joints()

	$grapher->cleanup_joints();

Is called automatically by finish(). This will collapse any left-over joint nodes:

                +---+             +-------+
    -- false --> | * | -- next --> | $b++; | -->
                +---+             +-------+

Will be turned into:

                       +-------+
    -- false, next --> | $b++; | -->
                       +-------+

=head1 ADDITIONAL METHODS
 
Note that the following routines will not work when used recursively, because
they add the entire structure already connect, at once.

If you want a if-then-else, which
contains another if-then-else, for instance, you need to construct
the blocks first, and then connect them manually.

Pleasee C<Devel::Graph> on how to do this.

=head2 add_if_then()

	my $current = $grapher->add_if_then( $if, $then);
	my $current = grapher->add_if_then( $if, $then, $where);

Add an if-then branch to the flowchart. The optional C<$where> parameter
defines at which block to attach the construct.

Returns the new current block, which is a C<joint>.

Example:

                                             false
          +--------------------------------------------+
          |                                            v
        +-------------+  true   +---------+
    --> | if ($a = 9) | ------> | $b = 1; | ------->   *   -->
        +-------------+         +---------+

=head2 add_if_then_else()

	my $current = $grapher->add_if_then_else( $if, $then, $else);
	my $current = $grapher->add_if_then_else( $if, $then, $else, $where);

Add an if-then-else branch to the flowchart.

The optional C<$where> parameter defines at which block to attach the
construct.

Returns the new current block, which is a C<joint>.

Example:

        +-------------+
        |   $b = 2;   | --------------------------+
        +-------------+                           |
          ^                                       |
          | false                                 |
          |                                       v
        +-------------+  true   +---------+
    --> | if ($a = 9) | ------> | $b = 1; | -->   *   -->
        +-------------+         +---------+

If C<$else> is not defined, works just like C<add_if_then()>.

=head2 add_for()

	my ($current,$body,$continue) = $grapher->add_for( $init, $while, $cont, $body, $continue);
	my ($current,$body,$continue) = $grapher->add_for( $init, $while, $cont, $body, $continue, $where);

Add a C<< for (my $i = 0; $i < 12; $i++) { ... } continue {} >> style loop.

The optional C<$where> parameter defines at which block to attach the
construct.

This routine returns three block positions, the current block (e.g. after
the loop), the block of the loop body and the position of the (optional)
continue block.

Example:

        +--------------------+  false        
    --> |   for: $i < 10;    | ------->  *  -->
        +--------------------+
          |                ^
          | true           +----+
          v                     |
        +---------------+     +--------+
        |     $a++;     | --> |  $i++  |
        +---------------+     +--------+

=head2 add_foreach()

	my ($current,$body,$continue) = $grapher->add_foreach( $list, $body, $cont);
	my ($current,$body,$continue) = $grapher->add_foreach( $list, $body, $cont, $where);

Add a C<for my $var (@lies) { ... }> style loop.

The optional C<$where> parameter defines at which block to attach the
construct.

This routine returns three block positions, the current block (e.g. after
the loop), the block of the loop body and the position of the (optional)
continue block.

Example:

        +----------------------+  false        
    --> |   for my $i (@list)  | ------->  *  -->
        +----------------------+
          |                ^
          | true           +----+
          v                     |
        +---------------+     +--------+
        |     $a++;     | --> |  $i++  |	# body and continue block
        +---------------+     +--------+

=head2 add_while()

  	my ($current,$body, $cont) = 
	  $grapher->add_while($while, $body, $cont, $where) = @_;

To skip the continue block, pass C<$cont> as undef.

This routine returns three block positions, the current block (e.g. after
the loop), the block of the loop body and the continue block.


Example of a while loop with only the body (or only the C<continue> block):


        +----------------------+  false  
    --> |   while ($b < 19)    | ------->  *  -->
        +----------------------+
          |                  ^
          | true             |
          v                  |
        +-----------------+  |
        |      $b++;      |--+
        +-----------------+

Example of a while loop with body and continue block (note similiarity to for
loop):

        +--------------------+  false        
    --> | while ($i < 10)    | ------->  *  -->
        +--------------------+
          |                ^
          | true           +----+
          v                     |
        +---------------+     +--------+
        |     $a++;     | --> |  $i++  |
        +---------------+     +--------+

=head2 add_until()

  	my ($current,$body, $cont) = 
	  $grapher->add_until($until, $body, $cont, $where) = @_;

To skip the continue block, pass C<$cont> as undef.

Works just like while, but reverses the C<true> and C<false> edges
to represent a C<until () BLOCK continue BLOCK> loop.

See also C<add_while()>.

=head2 add_jump()

	my $jump = $grapher->add_jump ( $text, $type, $label, $target);
	my ($jump,$target) = $grapher->add_jump ( $text, $type, $label);

Adds a jump block, with a connection to C<$target>. If C<$target> is just
the label name, will try to find a block with that label. If no block
can be found, will create it.

The type is one of:

	goto
	break
	return
	last
	next
	continue

=head2 add_joint()

	my $joint = $grapher->add_joint( @blocks );

Adds a joint (an unlabeled, star-shaped node) to the flowchart and then
connects each block in the given list to that joint. This is used
f.i. by if-then-else constructs that need a common joint where all
the branches join together again.

When adding a block right after a joint, they will be merged together
and the joint will be effectively replaced by the block.

Example:

    -->   *   -->

=head1 SEE ALSO

L<Graph::Easy>, L<Devel::Graph>.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL version 2 or later.
See the LICENSE file for information.

X<gpl>

=head1 AUTHOR

Copyright (C) 2004-2007 by Tels L<http://bloodgate.com>

X<tels>
X<bloodgate.com>

=cut
