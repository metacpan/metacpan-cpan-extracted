#############################################################################
# Generate flowcharts from Perl code.
#
#############################################################################

package Devel::Graph;

use Graph::Easy;
use Graph::Easy::Base;
use Graph::Flowchart;
use Graph::Flowchart::Node qw/
  N_IF N_THEN N_ELSE N_JOINT N_BLOCK N_BODY
  N_SUB N_RETURN
  N_BREAK N_LAST N_GOTO N_CONTINUE N_NEXT
  N_FOR N_WHILE N_UNTIL
  /;

$VERSION = '0.12';

@ISA = qw/Graph::Easy::Base/;
@EXPORT_OK = qw/graph/;

use strict;
use PPI;

#############################################################################
#############################################################################

sub _init
  {
  my ($self, $args) = @_;

  $self->{options} = {};

  $self->{opt}->{strip_pod} = 1;
  $self->{opt}->{strip_pod} = ($args->{strip_pod} ? 1 : 0)
    if defined $args->{strip_pod};

  $self->{fatal_errors} = $args->{fatal_errors};
  $self->{fatal_errors} = 1 unless defined $self->{fatal_errors};

  $self->{debug} = $args->{debug} || 0;

  $self->reset();

  $self;
  }

sub option
  {
  my $self = shift;

  $self->{opt}->{$_[0]};
  }

sub debug
  {
  my $self = shift;

  $self->{debug} = $_[0] if @_;
  $self->{debug};
  }

sub graph
  {
  # decompose code and return as Graph::Easy object

  # allow the following styles:
  # Devel::Graph->graph($code);		@_ == 2  $class
  # Devel::Graph::graph($code);		@_ == 1
  # $grapher->graph($code);		@_ == 2  ref($self) == $class

  my $self = 'Devel::Graph';
  $self = shift if @_ == 2;
  my $code = shift;

  if (! ref($self) )
    {
    $self = $self->new();
    }
  $self->reset();
  $self->decompose($code);
  $self->{flow}->finish();

  $self->{flow}->as_graph();			# return the Graph::Easy object
  }

sub as_graph
  {
  # return the internal Graph::Easy object
  my $self = shift;

  $self->{flow}->as_graph();
  }

sub as_ascii
  {
  # return the flowchart as ASCII
  my $self = shift;

  $self->{flow}->as_graph()->as_ascii();
  }

sub as_flowchart
  {
  # return the internal Graph::Flowchart object
  my $self = shift;

  $self->{flow};
  }

sub decompose
  {
  my ($self, $code) = @_;

  $self->error("Expected SCALAR ref, but got " . ref($code))
   if ref($code) && ref($code) ne 'SCALAR';

  $self->error("Got filename '$code', but can't read it: $!")
   if !ref($code) && !-f $code;

  my $doc = PPI::Document->new($code);

  $self->error("Couldn't create PPI::Document from $code")
   unless ref($doc);

  $doc->prune('PPI::Token::Pod') if $self->{opt}->{strip_pod};

  $self->_parse($doc);

  $self;
  }

sub finish
  {
  my $self = shift;

  $self->{flow}->finish();
  }

sub reset
  {
  # reset the internal structure
  my $self = shift;

  Graph::Easy::Base->_reset_id();

  $self->{cur_group} = undef;
  $self->{stack} = [];
  $self->{flow} = Graph::Flowchart->new();
  $self->{flow}->{graph}->seed(0);

  $self;
  }

#############################################################################
#############################################################################
# _parse helper routines

sub _find_first
  {
  # return the first child of $element matching any of the given types
  my $self = shift;
  my $element = shift;

  for my $child (@{$element->{children}})
    {
    for my $type (@_)
      {
      return $child if $child->isa($type);
      }
    }

  undef;
  }

sub _find_second
  {
  # return the first child of $element matching any of the given types
  my $self = shift;
  my $element = shift;

  $self->error("Got non-object as element: $element") unless ref $element;

  my @blocks;
  for my $child (@{$element->{children}})
    {
    for my $type (@_)
      {
      push @blocks, $child if $child->isa($type);
      return $blocks[-1] if scalar @blocks == 2;
      }
    }

  undef;
  }

sub _find_on_stack
  {
  my ($self, $type) = @_;

  my $stack = $self->{stack};

  for my $e (@$stack)
    {
    return $e if $e->{_type} == $type;
    }

  undef;
  }

#############################################################################
#############################################################################

sub _parse_compound
  {
  my ($self, $element, $type) = @_;

  # work around bug in PPI
  $type = $element->type() unless defined $type;

  $self->error("Cannot determine type of compound element $element")
    unless defined $type;

  # closures (bug #29346)
  return $self->_parse($element->children)
    if $type eq 'continue';

  return $self->_parse_loop($element)
    if $type eq 'for' || $type eq 'foreach';
 
  $self->error("Cannot find condition: possible syntax error in $element")
    unless defined $self->_find_first($element,'PPI::Structure::Condition');

  # ignoring whitespace and comments, find the condition
  my @blocks;

  my $condition = $element->clone();

  my $in_cond = 0;
  my @children = @{$condition->{children}};

  for my $child (@children)
    {
    next unless $child->significant();

    if ($child->isa('PPI::Structure::Block'))
      {
      push @blocks, $child;
      $in_cond = 2;
      }

    $child->remove() unless $in_cond == 1;

    $in_cond = 1 if $in_cond == 0 && $child->isa('PPI::Token::Word');
    }

  ########################################################################
  ########################################################################
  # work around bug in PPI for "unless" having type() return 'if'
  if ($type eq 'if')
    {
    my $c = $element->find_first('PPI::Token::Word');
    $type = 'unless' if $c eq 'unless';
    }
  ########################################################################
  ########################################################################

  ########################################################################
  ########################################################################
  # work around bug in PPI for "until" having type() return 'while'
  if ($type eq 'while')
    {
    my $c = $element->find_first('PPI::Token::Word');
    $type = 'until' if $c eq 'until';
    }
  ########################################################################
  ########################################################################

  $condition = $self->_normalize_condition($condition);

  return $self->_parse_if($type, $condition, @blocks)
    if $type =~ /^(if|unless)\z/;

  return $self->_parse_while($type, $condition, @blocks)
    if $type =~ /^(until|while)\z/;

  $self->error("Unknown conditional type $type");
  }

sub _normalize_condition
  {
  my ($self, $condition) = @_;

  my $text = $condition->content();

  $text =~ s/^\s+//;
  $text =~ s/\s+\z//;

  $text;
  }

sub _parse_if
  {
  my ($self, $type, $condition, $block, $else_block) = @_;

  $self->error('Undefined block in if expression') unless defined $block;

  my $flow = $self->{flow};

  # cur => if => then => joint
  #        |--------------^
  
  my $if = $flow->add_new_block('if ' . $condition, N_IF());

  my @edges = ('true','false');
  @edges = ('false','true') if $type eq 'unless';

  # cur => if => then
  my $then = $flow->add_joint(); 
  my $then_edge = $flow->connect($if,$then,$edges[0]);

  $flow->current_block($then);

  # fill in the "then" block
  $self->_parse($block);
  my $last_then = $flow->add_new_joint();

  if ($else_block)
    {
    # cur => if =====> then => joint
    #        --false-> else => ---^

    my $else_joint = $flow->add_joint();

    my $else_edge = $flow->connect($if,$else_joint,$edges[1]);
    $flow->current_block($else_joint);

    $self->_parse($else_block);
    
    my $l_joint = $flow->add_new_joint();

    $flow->connect($l_joint,$last_then);
    }
  else
    {
    # connect the "if" block with the newly added joint
    # cur => if => then => joint
    #        ----false--------^
  
    # add a dummy-joint
    $flow->connect($if,$last_then,$edges[1]);
    }
  $flow->current($last_then);
  }

sub _parse_sub
  {
  my ($self, $sub) = @_;

  my $name = $self->_find_second($sub, 'PPI::Token::Word');
  
  my $flow = $self->{flow};

  $flow->add_group("sub $name:");

  # remember pos before sub
  my $cur = $flow->current();

  # entry point
  my $joint = $flow->add_joint(); $joint->{_label} = $name;
  $flow->current($joint);

  # recurse into our children, but ignore:
  # whitespace and comments and Null (";")
  foreach my $child (@{$sub->{children}})
    {
    $self->_parse($child) if $child->significant();
    }

  # continue at pos before sub
  $flow->current($cur);
  $flow->no_group();

  }

sub _parse_while
  {
  # add while() or until() loops
  my ($self, $type, $condition, $body, $continue) = @_;

  #  |----------- false ------------v
  # while () -- true --> body -> continue    * 
  #  ^----------------------------|

  my $flow = $self->{flow};
  my $t = N_WHILE; $t = N_UNTIL if $type eq 'until';
  my @edges = ('true','false');
  @edges = ('false','true') if $type eq 'until';

  my $while = $flow->add_new_block( "$type $condition", $t);
  my $body_block = $flow->add_joint();

  # -- true -->
  my $true = $flow->connect($while,$body_block, $edges[0]);
  # make the true edge start at the right side (perpendicular to flow)
  $true->set_attribute('start','right') if $type eq 'until';

  $body_block->set_attributes( {
    offset => '-2,0',
    origin => $while->name(),
    });

  $flow->current($body_block);

  # insert the body
  $self->_parse($body);

  if (defined $continue)
    {
    # connect the body to the continue block
    my $cont_block = $flow->add_new_joint();
    $self->_parse($continue);
    }

  # connect body (or continue) back to while
  my $back = $flow->connect($flow->current(), $while);
  # make the back edge end at the right side (perpendicular to flow)
  $back->set_attribute('end','right,1');

  # connect body to next
  my $next = $flow->add_joint();

  my $forward = $flow->connect($while, $next, $edges[1]);

  # make that edge go forwards 
  $forward->set_attribute('flow','forward');

  $flow->current($next);
  }

sub _parse_loop
  {
  my ($self, $element) = @_;

#  PPI::Statement::Compound
#    PPI::Token::Word    'for'
#    PPI::Structure::ForLoop     ( ... )
#      PPI::Statement::Variable
#        PPI::Token::Word        'my'
#        PPI::Token::Symbol      '$i'
#        PPI::Token::Operator    '='
#        PPI::Token::Number      '0'
#        PPI::Token::Structure   ';'
#      PPI::Statement
#        PPI::Token::Symbol      '$i'
#        PPI::Token::Operator    '<'
#        PPI::Token::Number      '10'
#        PPI::Token::Structure   ';'
#      PPI::Statement
#        PPI::Token::Symbol      '$i'
#        PPI::Token::Operator    '++'
#    PPI::Structure::Block       { ... }
#      PPI::Statement
#        PPI::Token::Symbol      '$b'
#        PPI::Token::Operator    '++'
#        PPI::Token::Structure   ';'

#  PPI::Statement::Compound
#    PPI::Token::Word    'for'
#    PPI::Token::Word    'my'
#    PPI::Token::Symbol          '$i'
#    PPI::Structure::ForLoop     ( ... )
#      PPI::Statement
#        PPI::Token::Symbol      '@list'
#    PPI::Structure::Block       { ... }
#      PPI::Statement
#        PPI::Token::Word        'print'
#        PPI::Token::Symbol      '$foo'

  my $loop = $self->_find_first($element, 'PPI::Structure::ForLoop');

  my (@bodies, @blocks, @var);
  # get the stuff inside the ()
  foreach my $child (@{$loop->{children}})
    {
    push @blocks, $child if $child->isa('PPI::Statement');
    }
  # get the body (and continue) block
  foreach my $child (@{$element->{children}})
    {
    push @bodies, $child if $child->isa('PPI::Structure::Block');
    }
  # get the variable in front of the () for foreach loops
  foreach my $child (@{$element->{children}})
    {
    push @var, $child->content() if $child->isa('PPI::Token::Word') || $child->isa('PPI::Token::Symbol');
    }
  shift @var;	# remove the "for" so that "for my $i" results in "my $i";

  my $flow = $self->{flow};
  if (@blocks == 1)
    {
    # 'for my $var (@list)'

    my $v = join(" ", @var);
    $blocks[0] = 'for ' . $v . " ($blocks[0])";
    push @blocks, '';

    #  |-----last------v
    # for ---> body    *
    #  ^--------|
    
    # XXX TODO: 
    # technically, we need to parse $blocks[0]!

    my $for_block = $flow->add_new_block($blocks[0], N_FOR());
    my $body_block = $flow->add_new_joint();

    # insert the '*' for "next"
    my $next = $flow->add_joint();

    # insert the body
    $self->_parse($bodies[0]);

    # connect the body back to the for
    my $cur = $flow->current();
    if ($cur->{_type} == N_JOINT)
      {
      # XXX TODO: if current is a joint, eliminate it
      # move all incoming edges to point directly to 'for'
      $flow->connect($cur, $for_block, 'next');
      }
    else
      {
      $flow->connect($cur, $for_block, 'next');
      }

    my $last = $flow->connect($for_block, $next, 'last');
    $last->set_attribute('flow','forward');
   
    $flow->current($next);

    return;
    }

  # init -> if $while --> body --> cont --> (back to if)

  # XXX TODO: 
  # technically, we need to parse $blocks[x]!

  my $next = $flow->add_joint();
  my $for_block = $flow->add_new_block('for: ' . $blocks[0], N_FOR());
  my $while_block = $flow->add_new_block('while ' . $blocks[1], N_WHILE());
  
  my $body_block = $flow->add_joint();

  $flow->connect($while_block, $body_block, 'true');

  # insert the body
  $flow->current($body_block);
  $self->_parse($bodies[0]);

  my $cur = $flow->current();
  my $cont_block = $flow->add_new_block($blocks[2], N_BLOCK());

  my $false = $flow->connect($while_block, $next, 'false');
  $false->set_attribute('flow','forward');

  $flow->connect($cont_block, $while_block, 'continue');

  $flow->current($next);
  }

sub _parse_conditional
  {
  # parse a statement with a trailing condition/loop
  my ($self, $element) = @_;

# PPI::Statement
#    PPI::Token::Word    'print'
#    PPI::Token::Symbol          '$a'
#    PPI::Token::Operator        '++'
#    PPI::Token::Word    'if'				<-- type
#    PPI::Structure::Condition   ( ... )		<-- condition start
#      PPI::Statement::Expression
#        PPI::Token::Symbol      '$a'
#        PPI::Token::Operator    '<'
#        PPI::Token::Number      '9'
  
  # gather all elements up to the condition
  my @blocks;
  my $condition;

  for my $child (@{$element->{children}})
    {
    next unless $child->significant();		# ignore whitespace etc
    push @blocks, $child;
    $condition = $child->snext_sibling(), last 
     if $child->isa('PPI::Token::Word') && $child =~ /^(if|unless|until|while)\z/;
    }

  my $type = pop @blocks;			# if, unless, until, or while

  # make a copy and delete the condition and the word before it
  # to get only the block of the condition:

  my $block = $element->clone();
  my $c = $block->find_first('PPI::Structure::Condition');
  my $t = $c->sprevious_sibling();
  $c->delete();
  $t->delete();

  # delete trailing whitespace in $block (so that "$c = 123 ;" turns in "$c = 123;"
  for my $child (reverse @{$block->{children}})
    {
    # remove the trailing ";" because otherwise:
    # "print $a++ if (...)" would turn into 		"print $a++"
    # while "print $a++ if (...);" would turn into 	"print $a++;"

    # stop at the first significant child other than the ";"
    $child->delete() && next if $child->isa('PPI::Token::Structure') && $child eq ';';
    last if $child->significant(); 
    $child->delete();
    }
  
  return $self->_parse_if($type, $condition, $block)
    if $type =~ /^(if|unless)\z/;

  return $self->_parse_while($type, $condition, $block)
    if $type =~ /^(until|while)\z/;

  $self->error("Unknown conditional type $type");
  }

my $types = {
  'return' => N_RETURN(),
  'last' => N_LAST(),
  'break' => N_BREAK(),
  'continue' => N_CONTINUE(),
  'goto' => N_GOTO(),
  'next' => N_NEXT(),
  };

sub _parse_break
  {
  my ($self, $element) = @_;

  # find the type of the break statement
  my $type = $self->_find_first($element, 'PPI::Token::Word');

  my $flow = $self->{flow};

  my $target;
  if ($type ne 'return')
    {
    my $t = $types->{"$type"};
    $self->error("Unrecognized break type $type") unless defined $t;

    # ignore first Token::Word
    $target = $self->_find_second($element, 'PPI::Token::Word');
    $flow->add_jump(
	$element->content(),		# "last FOO;"
	$t, 				# N_BREAK etc
	'',
	$target->content());		# "FOO"
    }
  else
    {
    $flow->add_new_block($element->content(), N_RETURN(), '');
    }
  }

#############################################################################

sub _parse_expression
  {
  my ($self, $element) = @_;

  my $flow = $self->{flow};

  $flow->add_new_block( $element->content(), N_BLOCK());
  }

#############################################################################
#############################################################################
# main parse routine, recursive

sub _error
  {
  require Carp;

  Carp::confess($_);
  }

sub _parse
  {
  # take a PPI::ELement and descend into it recursively
  no warnings 'recursion';
  my ($self, $element) = @_;

#  print STDERR "parsing ", ref($element)," ($element)\n";

  $self->error('Encountered an undefined element while parsing')
    unless defined $element;

  # handle 'if', 'while', 'for', 'until' as compound statements
  # Example: until ($a < 9) { $b++; }
  return $self->_parse_compound($element)
    if $element->isa('PPI::Statement::Compound');

  # handle sub 
  return $self->_parse_sub($element)
    if $element->isa('PPI::Statement::Sub');

  # handle next, last, return and break
  return $self->_parse_break($element)
    if $element->isa('PPI::Statement::Break');

  # Example: "$a = 9 if ($b == 9);" - note the "()"!
  return $self->_parse_conditional($element)
    if (ref($element) eq 'PPI::Statement' && $element->find_any('PPI::Structure::Condition'));

  # Example: "$a = 9 if $b == 9;" - note the missing "()"!
  if (ref($element) eq 'PPI::Statement')
    {
    my $c = $element->find_first('PPI::Token::Word');
    return $self->_parse_conditional($element) if $c =~ /^(if|unless)\z/;
    }

  # handle normal expressions like:
  # "$a == 1"
  # "use strict;"
  return $self->_parse_expression($element)
    if ( $element->isa('PPI::Statement')   );
#        ($element->isa('PPI::Statement::Expression')) ||
#        ($element->isa('PPI::Statement::Include'))    );

  # recurse into our children, but ignore whitespace, comments, Null (";") etc:
  if ($element->isa('PPI::Node'))
    {
    foreach my $child (@{$element->{children}})
      {
      $self->_parse($child) if $child->significant();
      }
    }
  }

1;
__END__

=head1 NAME

Devel::Graph - Turn Perl code into a graphical flowchart

=head1 SYNOPSIS

	use Devel::Graph;
	my $grapher = Devel::Graph->new();

	my $graph = $grapher->decompose( \'if ($b == 1) { $a = 9; }' );
	print $graph->as_ascii();

	# Will result in something like this:

	################
	#    start     #
	################
	  |
	  |
	  v
	+--------------+
	| if ($b == 1) |--+
	+--------------+  |
	  |               |
	  | true          |
	  v               |
	+--------------+  |
	|   $a = 9;    |  | false
	+--------------+  |
	  |               |
	  |               |
	  v               |
	################  |
	#     end      # <+
	################

	# Alternatively, read in code from a file
	my $graph_2 = $grapher->decompose( 'lib/Foo.pm' );
	print $graph_2->as_ascii();

=head1 DESCRIPTION

This module decomposes Perl code into blocks and generates a
L<Graph::Flowchart> object out of these. The resulting object represents the
code in a flowchart manner and it can return an L<Graph::Easy> object.

This in turn can be converted it into all output formats currently
supported by C<Graph::Easy>, namely HTML, SVG, ASCII art, Unicode art,
graphviz code (which then can be rendered as PNG etc) etc.

=head2 Parsing

The parsing is done by L<PPI>, so everything that is supported
properly by PPI should work.

X<graph>
X<Perl>
X<code>
X<structure>
X<analysis>
X<ascii>
X<html>
X<svg>
X<flowchart>
X<diagram>
X<decompose>

=head2 Customizing the flowchart

Per default, the flowchart will have certain properties, like bold start/end
blocks, diamond-shaped C<if>-blocks and so on. You can change these
by setting class attributes on the returned graph object:

	use Devel::Graph;
	my $g = Devel::Graph->graph( '$a = 9 if $b == 1' );

	$g->set_attribute('node.if', 'fill', 'red');    # if blocks: red
	$g->set_attribute('node.for', 'fill', 'blue');  # for blocks: blue
	$g->set_attribute('edge.true', 'style', 'bold');# true edges: bold
	print $g->as_html_file();

Subclasses for C<node> include C<if>, C<for>, C<start>, C<end>, C<continue> etc.
For a list of all possible classes see C<Graph::Flowchart>, and for a list
of all possible attributes and their values, see L<Graph::Easy>.

=head1 EXPORT

Exports nothing.

=head1 METHODS

C<graph()> provides a simple function-style interface, while all
other methods are for an object-oriented model.

=head2 graph()

	my $graph = Devel::Graph->graph( \$code );
	my $graph = Devel::Graph->graph( $filename );

Takes Perl code in $code (as SCALAR ref or scalar filename) and returns a flowchart
as C<Graph::Easy> object. It will strip all POD before composing the flowchart.

This is a shortcut to avoid the OO interface described below, you should better
use this:

	my $code = \'$a = 9;';
	my $flow = Devel::Graph->new();
	$flow->decompose( $code );
	$flow->finish();
	my $graph = $grapher->as_graph();

Please see C<Graph::Easy> for further details on what to do with the
returned object.

=head2 new()

	my $flow = Devel::Graph->new( $options );
	my $flow_2 = Devel::Graph->new( { strip_pod => 0 } );

Creates a new C<Devel::Graph> object.

The optional C<$options> is a hash reference with parameters. The following
arguments are valid:

	strip_pod	Strip all POD before doing the graph. Defaults to true.
			POD sections are usually very large, resulting in huge
			nodes, that can, f.i. crash graphviz or result in
			poor output quality.
	debug		Defaults to false. When set to true, enables debug output.
	fatal_errors	Defaults to true. When set to true, errors are fatal.

=head2 option()

	my $option = $flow->option($name);

Return the option with the given name from the Devel::Graph object.

=head2 debug()

	my $debug = $grapher->debug();	# get
	$grapher->debug(1);		# enable
	$grapher->debug(0);		# disable

Enable, disable or read out the debug status. When the debug status is true,
additional debug messages will be printed on STDERR.

=head2 decompose()

	$flow->decompose( \$code );		# \'$a = 1;'
	$flow->decompose( $filename );		# 'lib/Package.pm'

Takes Perl code (scalar ref in C<$code>) or Perl file (filename in C<$code>) and 
decomposes it into blocks and updates the internal structures with a flowchart
representing this code.

If called more than one time, the code will be added to the flowchart. To
get a new, empty flowchart, use C<reset()>.

=head2 finish()

	$flow->finish();

Finish the flowchart by attaching an end node to the current node.

=head2 reset()

	$flow->reset();

Reset the internal state of the object, so that decompose() will create
a new flowchart.

=head2 as_graph()

	my $graph = $flow->as_graph();

Return the internal data structure as C<Graph::Easy> object.

=head2 as_ascii()

	print $flow->as_ascii();

Return the flow chart as ASCII art. Shortcut for
C<$grapher->as_graph->as_ascii()>.

=head2 as_flowchart()

	my $chart = $flow->as_flowchart();

Return the internal data structure as C<Graph::Flowchart> object.

=head1 BUGS

Not all Perl constructs are implemented yet, especially the more esoteric
Perl constructs.

Also, things like C<<$a = 9 if $b == 9>> (no C< () > around
the condition) are buggy and/or incomplete, due to the way PPI
parses the code.

Help in testing and bugreports are always welcome!

X<bugs>

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Flowchart>, L<PPI>, L<B::Graph>.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL version 2.
See the LICENSE file for information.

X<gpl>

=head1 AUTHOR

Copyright (C) 2004-2007 by Tels L<http://bloodgate.com>

X<tels>
X<bloodgate.com>

=cut
