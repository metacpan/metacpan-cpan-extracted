############################################################################
# Generate flowcharts from Regexp debug dumpes
#

package Graph::Regexp;

require 5.008001;
use Graph::Easy;
use Graph::Easy::Base;

$VERSION = 0.05;
@ISA = qw/Graph::Easy::Base/;

use strict;

# Perl 5.8.8, might be different for 5.10?
use constant MAX_MATCHES => 32767;

#############################################################################
#############################################################################

sub _init
  {
  my ($self, $args) = @_;

  $self->{options} = {};
  $self->{debug} = $args->{debug} || 0;
  $self->reset();
  $self;
  }

sub option
  {
  my $self = shift;
  $self->{options}->{$_[0]};
  }

sub graph
  {
  # decompose regexp dump and return as Graph::Easy object

  # allow Graph::Regexp->graph() calling style
  my $class = 'Graph::Regexp';
  $class = shift if @_ == 2; $class = ref($class) if ref($class);
  my $code = shift;

  my $self = $class->new();
  $self->reset();
  $self->parse($code);

  $self->{graph};			# return the Graph::Easy object
  }

sub as_graph
  {
  # return the internal Graph::Easy object
  my $self = shift;

  $self->{graph};
  }

sub as_ascii
  {
  # return the graph as ASCII
  my $self = shift;

  $self->{graph}->as_ascii();
  }

BEGIN
  {
  # make an alias for decompose
  *decompose = \&parse;
  }

sub parse
  {
  my ($self, $doc) = @_;

  $self->reset();				# clear data

  $self->_croak("Expected SCALAR ref, but got " . ref($doc))
   if ref($doc) && ref($doc) ne 'SCALAR';

  $self->_croak("Got filename '$doc', but can't read it: $!")
   if !ref($doc) && !-f $doc;

  # XXX TODO: filenames

  $self->_parse($$doc);

  $self;
  }

sub reset
  {
  # reset the internal structure
  my $self = shift;

  delete $self->{fail};
  delete $self->{success};
  $self->{graph} = Graph::Easy->new();

  $self->{stack} = [];
  $self->{entries} = {};

  $self;
  }

sub graph_label
  {
  # get/set the label of the graph
  my ($self) = shift;

  my $g = $self->{graph};
  if (@_ > 0)
    {
    $g->set_attribute('label',$_[0]);
    }
  $g->label();
  } 

#############################################################################
#############################################################################
# main parse routine, recursive

sub _setup_nodeclass
  {
  # add the attributes for one node class
  my ($self, $class, $title, $label) = @_;

  my $g = $self->{graph};

  $g->set_attribute("node.$class", 'title', $title);
  $g->set_attribute("node.$class", 'label', $label);
  }

sub _parse
  {
  # take the regexp string and decompose it into a tree, then turn this into
  # a graph.
  my ($self, $text) = @_;

  my $g = $self->{graph};

  # add the start node
  my $root = $g->add_node('0');
  $g->set_attribute('root','0');	# the first node is the root
  $root->set_attribute('label','START');
  $root->set_attribute('class','start');

  # add the final fail and success nodes
  $self->{fail} = $g->add_node('FAIL');
  $self->{success} = $g->add_node('SUCCESS');
  $self->{fail}->set_attribute('class','fail');
  $self->{success}->set_attribute('class','success');

  # this is a hack to workaround that Graph::Easy has not yet "end => '0'" for edges
  $self->{fail}->set_attribute('origin','SUCCESS');
  $self->{fail}->set_attribute('offset','0,2');

  $g->set_attribute('node.nothing', 'label', "\\''");
  $g->set_attribute('node.nothing', 'title', "Nothing (always matches)");

  # Special nodes:
  #  ^ (BOL)
  #  $ (EOL)
  #  \z (EOS)
  #  \Z (SEOL)
  #  \A (SBOL)
  #  \b \B (BOUND, NBOUND)
  #  \d \D (DIGIT, NDIGIT)
  #  \w \W (ALNUM, NALNUM)

  $self->_setup_nodeclass('bol',   'BOL (Begin Of Line)', '^');
  $self->_setup_nodeclass('eol',   'EOL (End Of Line)', '$');
  $self->_setup_nodeclass('eos',   'EOS (End Of String)', '\\z');
  $self->_setup_nodeclass('seol',  'SEOL (String end or End Of Line)', '\\Z');
  $self->_setup_nodeclass('sbol',  'SBOL (String begin or Begin Of Line)', '\\A');
  $self->_setup_nodeclass('bound',   'BOUND (Boundary)', '\\b');
  $self->_setup_nodeclass('nbound',  'NBOUND (Non-boundary)', '\\B');
  $self->_setup_nodeclass('digit',   'DIGIT (Digit)', '\\d');
  $self->_setup_nodeclass('ndigit',  'NDIGIT (Non-digit)', '\\D');
  $self->_setup_nodeclass('alnum',   'ALNUM (Alphanumeric)', '\\w');
  $self->_setup_nodeclass('nalnum',  'NALNUM (Non-alphanumeric)', '\\W');

  $g->set_attributes('node.fail', { fill => 'darkred', color => 'white' } );
  $g->set_attributes('node.success', { fill => 'darkgreen', color => 'white' } );

  $g->set_attributes('edge.match', { 
	'label' => 'match',
	'color' => 'darkgreen'
	} );
  $g->set_attributes('edge.always', { 
	'label' => 'always',
	} );
  $g->set_attributes('edge.fail', { 
	'label' => 'fail',
	'color' => 'darkred'
	} );

#  The general family of this object. These are any of: 
#   alnum, anchor, anyof, anyof_char, anyof_class, anyof_range, 
#   assertion, bol, branch, close, clump, digit, exact, flags, group, groupp,
#   minmod, open, prop, sol, eol, seol, sbol, quant, ref, reg_any,
#   star, plus ...

  # first we parse the following text:

#   1: OPEN1(3)
#   3:   BRANCH(6)
#   4:     EXACT <test>(9)
#   6:   BRANCH(9)
#   7:     EXACT <foo>(9)
#   9: CLOSE1(11)
#  11: EXACT <ab>(13)
#  13: PLUS(16)
#  14:   EXACT <c>(0)
#  16: EXACT <1>(18)

  # into entries like:

  #  { id => 1, level => 0, type => "open", next => 3, id => 1, }

  # to preserve the entries in their original order
  my $stack = $self->{stack};
  # to quickly find entries by their id
  my $entries = $self->{entries};

  $text =~ s/[\r\n]\z//;

  print STDERR "# Input: \n# '$text'\n" if $self->{debug};

  my @lines = split /\n/, $text; my $index = 0;
  for my $line (@lines)
    {
    # ignore all other lines
    next unless $line =~ /^\s+(\d+):(\s+)[A-Z]/;

    print STDERR "# Parsing line: '$line'\n" if $self->{debug} > 1;

    # level: ' ' => 0, '   ' => 1 etc
    my $entry = { level => (length($2)-1) / 2, id => $1 };

    # "7: EXACT <foo>(9)" => "EXACT <foo>(9)"
    $line =~ s/^\s+\d+:\s+//;
   
    # OPEN1(3)  or OPEN1 (3)
    if ($line =~ /^([A-Z][A-Z0-9]+)\s*\((\d+)\)/)
      {
      $entry->{class} = lc($1);
      $entry->{next} = $2;
      $entry->{exact} = '';
      }
    # EXACT <o>(16) or EXACT <o> (16)
    elsif ($line =~ /^([A-Z][A-Z0-9-]+)(\s*<(.+)>)?\s*\((\d+)\)/)
      {
      $entry->{class} = lc($1);
      my $t = $3;
      $entry->{next} = $4;
      $t =~ s/(\$|\@|\\)/\\$1/g;		# quote $, @ and \
      $entry->{exact} = "\\\"$t\\\"";
      $entry->{title} = "EXACT <$t>";
      }
    # TRIE-EXACT [bo](9)
    elsif ($line =~ /^TRIE-EXACT\s*(\[([^\]]+)\])\s*?\((\d+)\)/)
      {
      $entry->{class} = 'trie';
      $entry->{title} = "TRIE-EXACT <$1>";
      $entry->{exact} = "$1";
      $entry->{next} = $2;
      }
    # ANYOF[ab](8)
    elsif ($line =~ /^([A-Z][A-Z0-9-]+)\s*(\[([^\]]+)\])\s*?\((\d+)\)/)
      {
      $entry->{class} = lc($1);
      if ($entry->{class} eq 'anyof')
	{
        $entry->{exact} = "[$3]";
	}
      elsif ($entry->{class} eq 'nothing')
	{
        $entry->{exact} = "[$3]";
	}
      else
	{
        $entry->{exact} = "\"$3\"";
        }
      $entry->{title} = "EXACT <$3>";
      $entry->{next} = $4;
      }
    # CURLY {0,1}(22) or CURLY {0,1} (22)
    elsif ($line =~ /^([A-Z][A-Z0-9]+)\s*\{(\d+),(\d+)\}\s*\((\d+)\)/)
      {
      $entry->{class} = lc($1);
      $entry->{next} = $4;
      $entry->{min} = $2;
      $entry->{max} = $3;
      $entry->{exact} = "\{$entry->{min},$entry->{max}\}";
      }
    # CURLYM[1] {0,1}(22) or CURLY {0,1} (22) or CURLYX[1] {1,2}(22)
    elsif ($line =~ /^([A-Z][A-Z0-9]+)\[[^]]\]\s*\{(\d+),(\d+)\}\s*\((\d+)\)/)
      {
      $entry->{class} = lc($1);
      $entry->{next} = $4;
      $entry->{min} = $2;
      $entry->{max} = $3;
      $entry->{exact} = "\{$entry->{min},$entry->{max}\}";
      # make curlym, curly and curlyx all "curly"
      $entry->{class} = 'curly' if $entry->{class} =~ /^curly/;
      }
    # PLUS (22)
    elsif ($line =~ /^PLUS\s*\((\d+)\)/)
      {
      $entry->{class} = 'plus';
      $entry->{next} = $1;
      $entry->{min} = 1;
      $entry->{max} = MAX_MATCHES;
      $entry->{exact} = "\{$entry->{min},$entry->{max}\}";
      }
    $entry->{class} =~ s/[0-9]//g;	# OPEN1 => open
    $entry->{index} = $index++;

    push @$stack, $entry;
    $entries->{ $entry->{id} } = $entry;

    next if $entry->{class} =~ /(open|close|branch|end|succeed|curly|minmod|plus|star|whilem)/;

    # add the nodes right away
    # print STDERR "# adding node for $line\n";

    my $n = $g->add_node($entry->{id});
    $n->set_attribute('label', $entry->{exact}) if $entry->{exact} ne '';
    $n->set_attribute('class', $entry->{class});
    $n->set_attribute('title', $entry->{title}) if $entry->{title};

    $entry->{node} = $n;
    }

  # empty text => matches always
  if (keys %$entries == 0)
    {
    my $edge = $g->add_edge( $root, $self->{success});
    $edge->set_attribute('class','always');
    return $self;
    }

  # Now we take the stack of entries and transform it into a graph by
  # connecting all the nodes with "match" and "fail" edges.

  # Notes:

  #  Each tried (sub)expression in the regexp has exactly two outcomes:
  #  'match' or 'fail'.
  #  If a expression consists of more than on part than it is handled
  #  like an "and" (first and second part must match).
  #  F.i. in "[ab]foo", if [ab] matches, it goes to try "foo", If it
  #  it fails, it goes one level up. Likewise for "foo", match goes
  #  on to the next part and fail goes up.
  #  If we are already at level 0, the entire expression fails.

  #  Branches try each subexpression in order, that is if one subexpression
  #  fails, it goes to the next branch. If any of them matches, it goes
  #  on to the next part, and if all of them fail, it goes up.

  # /just(another|perl)hacker/ will result in:

#   1: EXACT <just>(3)
#   3: OPEN1(5)
#   5:   BRANCH(9)
#   6:     EXACT <another>(12)
#   9:   BRANCH(12)
#  10:     EXACT <perl>(12)
#  12: CLOSE1(14)
#  14: EXACT <hacker>(17)
#  17: END(0) 

  # [ just ] - match -> [ another ] - match -> [ hacker ] - match -> [ success ]
  #   |                   |                       ^   |
  #   | fail              | fail                  |   |
  #   |                   |                       |   | fail
  #   |                 [ perl ]    - match ------|   |
  #   |                   |                           |
  #   |                   | fail                      | 
  #   -------------------------------------------------------------> [ fail ]

  # XXX TODO: each OPEN/CLOSE pair should result in a subgroup. This is not
  #           yet possible since Graph::Easy doesn't allow nesting yet.

  # connect the root node to the first part
  my $next = $self->_find_node($stack->[0]);
  my $edge = $g->add_edge( $root, $next);

  # The "NOTHING" node has no predecessor and needs to be weeded out:
  #
  #  1: CURLYM[1] {0,32767}(15)
  #  5:   BRANCH(8)
  #  6:     EXACT <foo>(13)
  #  8:   BRANCH(11)
  #  9:     EXACT <bar>(13)
  # 13:   SUCCEED(0)
  # 14:   NOTHING(15)
  # 15: END(0)

  ###########################################################################
  ###########################################################################
  # main conversion loop

  # the entry/part we are trying
  my $i = 0;
  while ($i < @$stack)
    {
    my $entry = $stack->[$i];

    next unless exists $entry->{node};

    if ($entry->{class} eq 'nothing' && $entry->{node}->predecessors() == 0)
      {
      # a nothing node with no incoming connection, filter it out
      $g->del_node($entry->{node});
      next;
      }

    # the "match" egde goes to the next part
    my $next = $self->_find_next($entry);

    my $n = $next; $n = $self->{success} unless defined $n;

    my $edge = $g->add_edge( $entry->{node}, $n);
    $edge->set_attribute('class','match');

    if ($n == $self->{success})
      {
      $edge->set_attribute('end','back,0');
      }

    # nothing nodes do not have a fail edge, they match always
    if ( ($entry->{class} eq 'nothing') ||
         (defined $entry->{min} && $entry->{min} == 0) )
      {
      $edge->set_attribute('class','always');
      next;
      }
     
    # generate the fail edge:

    # if the next node is $self->{success}, then fail must be $self->{fail}
    my $fail = $self->{fail};
    # walked over end?
    if (!defined $next)
      {
      $fail = $self->_find_next_branching($entry);
      }
    # otherwise, find the next branching part
    elsif ($next != $self->{success})
      {
      $fail = $self->_find_next_branching($entry);
      }

    $edge = $g->add_edge( $entry->{node}, $fail);
    $edge->set_attribute('class','fail');
    $edge->set_attribute('end','back,0');

    } continue { $i++; }

  # if there are no incoming edges to fail, the regexp always matches (like //):
  $g->del_node($self->{fail}) if scalar $self->{fail}->incoming() == 0;

  $self;
  }

sub _find_next_branching
  {
  # Given an entry on the stack, go backwards to find the
  # last branch, then skip to the next part in that branch.
  # If there is no next part, try one level higher, until
  # we are at the upper-most level.
  my ($self, $entry) = @_;

  # Example:

  # starting with 14: EXACT <c>(19)

#   1: EXACT <0>(3)
#   3: OPEN1(5)
#   5:   BRANCH(8)
#   6:     EXACT <a>(35)
#   8:   BRANCH(32)
#   9:     EXACT <b>(11)
#  11:     OPEN2(13)
#  13:       BRANCH(16)			1 # look at next(16) is it a branch?
					  # yes it is, so go forward to it
#  14:         EXACT <c>(19)		0 # find 13: BRANCH(16)
#  16:       BRANCH(19)			2 # skip forward
#  17:         EXACT <d>(19)		3 # return this
#  19:     CLOSE2(21)
#  21:     ANYOF[i](35)
#  32:   BRANCH(35)
#  33:     EXACT <e>(35)
#  35: CLOSE1(37)
#  37: EXACT <g>(39)
#  39: END(0)

  # starting with 17: EXACT <d>(19)

#   1: EXACT <0>(3)
#   3: OPEN1(5)
#   5:   BRANCH(8)
#   6:     EXACT <a>(35)
#   8:   BRANCH(32)			2 # look at next(32) is it a branch?
					  # yes it is, so go forward to it
#   9:     EXACT <b>(11)
#  11:     OPEN2(13)
#  13:       BRANCH(16)
#  14:         EXACT <c>(19)
#  16:       BRANCH(19)			1 # look at next(16) is it a branch?
					  # no, 19 is not, so find 8: BRANCH(32)
#  17:         EXACT <d>(19)		0 # find 16: BRANCH(19)
#  19:     CLOSE2(21)
#  21:     ANYOF[i](35)
#  32:   BRANCH(35)
#  33:     EXACT <e>(35)		3 # return this:
#  35: CLOSE1(37)
#  37: EXACT <g>(39)
#  39: END(0)

  print STDERR "# find next branch for $entry->{id}\n" if $self->{debug};

  my $entries = $self->{entries};
  do {
    # find branch one level up
    my $branch = $self->_find_previous_branch($entry);

    print STDERR "#  prev branch for $entry->{id} should be at $branch->{id}\n"
	if $self->{debug} && $branch && defined $branch->{id};

    # no branch above us, fail completely
    return $self->{fail} unless defined $branch;

    # skip to next part
    $entry = $entries->{ $branch->{next} };

    print STDERR "# next branch should be at $entry->{id} ($entry->{class})\n"
	if $self->{debug};

    return $self->{fail} if $entry && $entry->{class} eq 'end';

    # loop ends if there is a next part in the current branch
    } while ($entry->{class} ne 'branch');

  # skip over the branch, open etc to the first real part
  $entry = $self->_find_node($entry);

  print STDERR "# next branch is at $entry->{id}\n"
	if $self->{debug};

  $entry;
  }

sub _find_previous_branch
  {
  # Given an entry on the stack, go backwards to find the
  # last branch.
  my ($self, $entry) = @_;

  my $entries = $self->{entries};
  my $stack = $self->{stack};

  my $index = $entry->{index};

 print STDERR "# Finding prev branch for entry $entry->{id}\n"
	if $self->{debug};

  # the branch must be this level or lower 
  my $level = $entry->{level};

  # go backwards until we find a BRANCH
  while ($index > 0)
    {
    $index--;
    my $e = $stack->[$index];

    print STDERR "#  Found $entry->{id} ($level vs $e->{level}\n" 
	if $self->{debug} && $entry && $entry->{class} eq 'branch';

    return $e if $e->{class} eq 'branch' && $e->{level} <= $level;
    }
  # the part we looked at is in the upper-most level, so there is
  # no next branch part we can skip to, meaning we fail completely.
  return;
  }

sub _find_node
  {
  # Given an entry on the stack, skip to next entry if the current
  # isnt a node itself.
  my ($self, $entry) = @_;

  # Example:

#   3: OPEN1(5)				# open => skip, go to next
#   5:   BRANCH(9)			# branch => skip, go to next
#   6:     EXACT <another>(12)		# return this

#   1: EXACT <just>(3)			# return this
#   3: OPEN1(5)
#   5:   BRANCH(9)
#   6:     EXACT <another>(12)
	
  print STDERR "#  find node for entry $entry->{id}\n"
	if $self->{debug};

  my $entries = $self->{entries};
  my $stack = $self->{stack};
  while (!exists $entry->{node})
    {
    print STDERR "#  at entry $entry->{id}\n"
	if $self->{debug};

    if ($entry->{class} =~ /^(open|branch|plus|star|curly)/)
      {
      $entry = $stack->[ $entry->{index} + 1 ];
      }
    else
      {
      $entry = $entries->{ $entry->{next} };
      }
    return $self->{success} unless ref $entry;		# walked over end
    }

  $entry->{node};
  }

sub _find_next
  {
  # Given an entry on the stack, find the next entry.
  my ($self, $entry) = @_;

  # Example:

#   1: EXACT <just>(3)			# go to 3
#   3: OPEN1(5)				# open => skip, go to next
#   5:   BRANCH(9)			# branch => skip, go to next
#   6:     EXACT <another>(12)		# return this

  print STDERR "# Skipping ahead for $entry->{id}:\n"
	if $self->{debug};
  my $entries = $self->{entries};
  my $stack = $self->{stack};
  do
    {
    print STDERR "#  at entry $entry->{id}\n"
	if $self->{debug};

    if ($entry->{class} =~ /^(open|branch|plus|star|curly)/)
      {
      $entry = $stack->[ $entry->{index} + 1 ];
      }
    else
      {
      $entry = $entries->{ $entry->{next} };
      }
    return unless ref $entry;		# walked over end

    print STDERR "#   next $entry->{id}\n"
	if $self->{debug} && ref($entry);
    } while (!exists $entry->{node});

  print STDERR "# return $entry->{id}\n"
	if $self->{debug};

  $entry->{node};
  }

1;
__END__

=head1 NAME

Graph::Regexp - Create graphical flowchart from a regular expression

=head1 SYNOPSIS

	# print out ASCII graph
	perl -Mre=debug -e '/just|another|perl|hacker/' 2>&1 | examples/regraph

	# the same, as PNG rendered via dot
	perl -Mre=debug -e '/me|you/' 2>&1 | examples/regraph as_graphviz | dot -Tpng -o me.png

=head1 DESCRIPTION

This module takes the debug dump of a regular expression (regexp) as
generated by Perl itself, and creates a flowchart from it as a L<Graph::Easy>
object.

This in turn can be converted it into all output formats currently
supported by C<Graph::Easy>, namely HTML, SVG, ASCII art, Unicode art,
graphviz code (which then can be rendered as PNG etc) etc.

X<graph>
X<Perl>
X<regexp>
X<code>
X<structure>
X<analysis>
X<ascii>
X<html>
X<svg>
X<flowchart>
X<diagram>
X<decompose>

=head2 Customizing the graph

Per default, the graph will have certain properties, like bold start/end
blocks, diamond-shaped branch-blocks and so on. You can change these
by setting class attributes on the returned graph object. The class
for each node is the same as it appears in the dump, in lowercase:

	start
	exact
	plus
	star
	trie
	curly
	end

etc.

=head1 EXPORT

Exports nothing.

=head1 METHODS

C<graph()> provides a simple function-style interface, while all
other methods are for an object-oriented model.

=head2 graph()

	my $graph = Graph::Regexp->graph( $dump );

Takes a regexp dump in $dump (as SCALAR) and returns a L<Graph::Easy> object.

This is a shortcut to avoid the OO interface described below and will
be equivalent to:

	my $parser = Graph::Regexp->new();
	$parser->parse( $dump );
	my $graph = $parser->as_graph();

Please see C<Graph::Easy> for further details on what to do with the
returned object.

=head2 new()

	my $parser = Graph::Regexp->new( $options );

Creates a new C<Graph::Regexp> object.

The optional C<$options> is a hash reference with parameters.

At the moment no options are defined.

=head2 option()

	my $option = $parser->option($name);

Return the option with the given name from the C<Graph::Regexp> object.

=head2 decompose()

	$parser->decompose( \$txt );		# \'...'
	$parser->decompose( $filename );	# 'regexp_dump.txt'

Takes Regexp dump (scalar ref in C<$txt>) or file (filename in C<$filename>) and 
creates a graph from it.

=head2 parse()

This is an alias for C<decompose()>.

=head2 reset()

	$parser->reset();

Reset the internal state of the parser object. Called automatically by
L<decompose()>.

=head2 as_graph()

	my $graph = $parser->as_graph();

Return the internal data structure as C<Graph::Easy> object.

=head2 as_ascii()

	print $parser->as_ascii();

Return the graph as ASCII art. Shortcut for C<$parser->as_graph->as_ascii()>.

=head2 graph_label()

	my $label = $parser->graph_label();
	$parser->graph_label('/^foo|bar/');

Set or get the label of the graph.

=head1 BUGS

Does not yet handle the new things like TRIE.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Flowchart>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL version 2 or later.
See the LICENSE file for information.

X<gpl>

=head1 AUTHOR

Copyright (C) 2006-2008 by Tels L<http://bloodgate.com>

X<tels>
X<bloodgate.com>

=cut
