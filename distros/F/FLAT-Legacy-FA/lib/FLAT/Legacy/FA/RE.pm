# $Revision: 1.5 $ $Date: 2006/03/02 21:00:28 $ $Author: estrabd $

package FLAT::Legacy::FA::RE;

use base 'FLAT::Legacy::FA';
use strict;
use Carp;

use FLAT::Legacy::FA::NFA;
use FLAT::Legacy::FA::DFA;
use Data::Dumper;

sub new {
  my $class = shift;
  bless {
    _CAT_STATE => 0,
    _CURRENT_STR => [],
    _DONE => 0,
    _EPSILON => 'epsilon',
    _ERROR => 0,
    _FOLLOW_POS => {},
    _LOOKAHEAD => '',
    _OR_STATE => 0,
    _PARSE_TREE => undef,
    _POS_COUNT => 0,
    _RE_END_SYMBOL => '#',
    _RE => '',
    _SYMBOL_POS  => [],
    _TERMINALS => [qw(a b c d e f g h i j k l m n o p q r s t u v w x y z 
                      A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 
		      0 1 2 3 4 5 6 7 8 9 + - = ? & [ ] { } . ~ ^ @ % $
		      : ; < >)],
    _TRACE => 0,
    _SYMBOLS => [],
  }, $class;
}

sub set_epsilon {
  my $self = shift;
  my $e = shift;
  chomp($e);
  $self->{_EPSILON} = $e;
  return;
}

sub get_epsilon_symbol {
  my $self = shift;
  return $self->{_EPSILON};
}

sub set_re {
  my $self = shift;
  my $re = shift;
  chomp($re);
  # reset stuff
  $self->{_CAT_STATE} = 0;
  $self->{_CURRENT_STR} = [];
  $self->{_DONE} = 0;
  $self->{_ERROR} = 0;
  $self->{_FOLLOW_POS} = {};
  $self->{_LOOKAHEAD} = '';
  $self->{_OR_STATE} = 0;
  $self->{_PARSE_TREE} = undef;
  $self->{_POS_COUNT} = 0;
  $self->{_SYMBOL_POS}  = [];
  $self->{_TRACE} = 0;
  $self->{_SYMBOLS} = [];
  $self->{_RE} = $re;
  # load up current string stack
  $self->set_current($re);
  my @re = split(//,$re);
  # load up symbol position stack, and store unique terminal symbols encountered
  foreach (@re) {
    if ($self->is_terminal($_)) {
      push(@{$self->{_SYMBOL_POS}},$_);
      if (!$self->is_member($_,@{$self->{_SYMBOLS}})) {
        push(@{$self->{_SYMBOLS}},$_);
      }
    }
  }
  push(@{$self->{_SYMBOL_POS}},$self->{_RE_END_SYMBOL});
  return;
}

sub get_re {
  my $self = shift;
  return $self->{_RE};
}

sub set_current {
  my $self = shift;
  my $re = shift;
  chomp($re);
  @{$self->{_CURRENT_STR}} = split(//,$re);
  return;
}

sub reset_current {
  my $self = shift;
  @{$self->{_CURRENT_STR}} = split(//,$self->get_re());
  return;
}

sub get_current {
  my $self = shift;
  return $self->{_CURRENT_STR};
}

sub minimize {
  my $self = shift;
  return;
}

sub shrink {
  my $self = shift;

  return;
}

sub to_nfa {
  my $self = shift;
  # parse re if _PARSE_TREE is not defined
  if (!defined($self->{_PARSE_TREE})) {
    $self->parse();
  } 
  # sync NFA's epsilon symbol with RE's
  my $NFA = $self->thompson($self->get_parse_tree());
  return $NFA;
}

sub thompson {
  my $self = shift;
  my $tree = shift;
  my $NFA_l = undef;
  my $NFA_r = undef;
  if ($tree->{symbol} ne $self->{_RE_END_SYMBOL}) {
    # dive into tree recursively_RE_END_SYMBOL
    # go left
    if (defined($tree->{left}) ) {
      $NFA_l = $self->thompson($tree->{left});
    }
    # go right
    if (defined($tree->{right})) {
      $NFA_r = $self->thompson($tree->{right});
    }
    # kleene - terminal always returned from left
    if (defined($NFA_l) && $tree->{symbol} eq '*') {
      $NFA_l->kleene();
    }
    # Checks to see if current node is a leaf or not
    if (defined($tree->{pos})) {
      # create a minimal NFA with 1 symbol, 
      $NFA_l = FLAT::Legacy::FA::NFA->jump_start($tree->{symbol});
    } elsif(defined($NFA_l) && defined($NFA_r)) {
      # ORs and CATs
      if ($tree->{symbol} eq '|') {      # or
	$NFA_l->or_nfa($NFA_r);
      } elsif ($tree->{symbol} eq '.') { # cat
	$NFA_l->append_nfa($NFA_r);
      }
    }
  }
  return $NFA_l;
}

#Currently BREAKS on a*(b|cd)m!!!!!!!!!!!!!!
sub to_dfa_BROKEN {
  my $self = shift;
  # parse re if _PARSE_TREE is not defined
  if (!defined($self->{_PARSE_TREE})) {
    $self->parse();
  }
  # calculate firstpos and lastpos, add to _PARSE_TREE`
  my $pt = $self->lastpos($self->firstpos($self->get_parse_tree()));
  # calculate follow positions
  $self->followpos($pt);
  #print Dumper($self->{_FOLLOW_POS}); 
  # BEGIN SUBSET CONSTRUCTION - based on what is in NFA.pm
  my @Dstates = (); # stack of new states to find transitions for 
  # New DFA object reference
  my $DFA = FLAT::Legacy::FA::DFA->new();
  # Initialize DFA start state by performing e-closure on the NFA start state
  my @Start = @{$pt->{firstpos}};
  # Add this state to Dstates - subsets stored as anonymous arrays (no faking here!)
  push(@Dstates,[sort(@Start)]);
  # Serialize subset into new state name - i.e, generate string-ified name
  my $ns = join('_',@Start);
  # Add start state to DFA (placeholder Dtran not used)
  $DFA->set_start($ns);
  # Add new state (serialized name) to DFA state array
  $DFA->add_state($ns);
  # Check if start state is also final state (i.e., contains state accepting '#'), if so add
  foreach my $s (@Start) {
    if ($s == ($#{$self->{_SYMBOL_POS}}+1) && !$DFA->is_final($ns)) {
      $DFA->add_final($ns);
    }
  }
  # Loop until Dstate stack is exhausted
  while (@Dstates) {
    # pop next state off to check
    my @T = @{pop @Dstates};
    # Serialize subset into a string name
    my $CURR_STATE = join('_',@T);
    # loop over each input symbol
    foreach my $symbol ($self->get_symbols()) {
      # Obviously do not add the epsilon symbol to the dfa
      # Add symbol - add_symbol ensures set of symbols is unique
      $DFA->add_symbol($symbol);
      # Get new subset of transition states
      my @new = $self->move($symbol,(@T));
      # Serialize name of new state
      $ns = join('_',@new);
      # Add transition as long as $ns is not empty string
      if ($ns !~ m/^$/) {
        $DFA->add_transition($CURR_STATE,$symbol,$ns);
	# Do only if this is a new state and it is not an empty string
	if (!$DFA->is_state($ns)) {
          # add subset to @Dstates as an anonymous array
          push(@Dstates,[@new]);
          $DFA->add_state($ns);
          # check to see if any NFA final states are in
	  # the new DFA states
	  foreach my $s (@new) {
	    if ($s == ($#{$self->{_SYMBOL_POS}}+1) && !$DFA->is_final($ns)) {
	      $DFA->add_final($ns);
	    }
	  }	  
	}
      }
    }
  }
  return $DFA;
}

sub get_transition_on {
  my $self = shift;
  my $state = shift;
  my $symbol = shift;
  my @ret = undef;
  if (@{$self->{_SYMBOL_POS}}[$state-1] eq $symbol) {
    @ret = @{$self->{_FOLLOW_POS}->{$state}};
  }
  return @ret;
}

sub move {
  my $self = shift;
  my $symbol = shift;
  my @subset = @_; # could be one state, could be a sub set of states...
  my @T = ();
  # Loop over subset until exhausted
  while (@subset) {
    # get a state from the subset
    my $state = pop @subset;
    # get all transitions for $t, and put the in @u
    my @u = $self->get_transition_on($state,$symbol);
    foreach (@u) {
      if (defined($_)) {
        # Add to new subset if not there already
	if (!$self->is_member($_,@T)) {
          push(@T,$_);
	}
      }
    }
  }
  # Returns ref to sorted subset array instead of list to preserve subset
  return sort(@T); 
}

sub firstpos {
  my $self = shift;
  my $tree = shift;
  # dive into tree recursively
  if (defined($tree->{left}) ) {$self->firstpos($tree->{left});}
  if (defined($tree->{right})) {$self->firstpos($tree->{right});}
  # Denotes leaves - fp_nullable is false by definition
  if (defined($tree->{pos})) {
    if ($tree->{symbol} eq $self->get_epsilon_symbol()) {
      $tree->{firstpos} = [];             # empty anonymous array
      $tree->{fp_nullable} = 1;           # true by definition
    } else {
      $tree->{firstpos} = [$tree->{pos}]; # anonymous array
      $tree->{fp_nullable} = 0;           # false by definition    
    }
  } else {
    # All other nodes
    if ($tree->{symbol} eq '|') {      # or
      # firstpos(left) UNION firstpos(right) - always
      push(@{$tree->{firstpos}},@{$tree->{left}->{firstpos}},@{$tree->{right}->{firstpos}});
      # determine fp_nullable-ness of this node
      $tree->{fp_nullable} = 0;
      if ($tree->{left}->{fp_nullable} == 1 || $tree->{right}->{fp_nullable} == 1) {
        # set fp_nullable if either left or right trees are fp_nullable
        $tree->{fp_nullable}++;
      }      
    } elsif ($tree->{symbol} eq '.') { # cat
      # determine firstpos
      if ($tree->{left}->{fp_nullable} == 1) {
        push(@{$tree->{firstpos}},@{$tree->{left}->{firstpos}},@{$tree->{right}->{firstpos}});
      } else {
        push(@{$tree->{firstpos}},@{$tree->{left}->{firstpos}}); 
      }
      # determine fp_nullable-ness of this node
      $tree->{fp_nullable} = 0;
      if ($tree->{left}->{fp_nullable} == 1 && $tree->{right}->{fp_nullable} == 1) {
        $tree->{fp_nullable} = 1;
      }      
    } elsif ($tree->{symbol} eq '*') { # kleene star (closure)
      $tree->{fp_nullable} = 1;
      push(@{$tree->{firstpos}},@{$tree->{left}->{firstpos}});
    }
  }
  return $tree;
}

sub lastpos {
  my $self = shift;
  my $tree = shift;
  # dive into tree recursively
  if (defined($tree->{left}) ) {$self->lastpos($tree->{left});}
  if (defined($tree->{right})) {$self->lastpos($tree->{right});}
  # Denotes leaves - lp_nullable is false by definition
  if (defined($tree->{pos})) {
    if ($tree->{symbol} eq $self->get_epsilon_symbol()) {
      $tree->{lastpos} = [];              # empty anonymous array
      $tree->{lp_nullable} = 1;           # true by definition
    } else {
      $tree->{lastpos} = [$tree->{pos}];  # anonymous array
      $tree->{lp_nullable} = 0;           # false by definition    
    }
  } else {
    # All other nodes
    if ($tree->{symbol} eq '|') {      # or
      # lastpos(left) UNION lastpos(right) - always
      push(@{$tree->{lastpos}},@{$tree->{left}->{lastpos}},@{$tree->{right}->{lastpos}});
      # determine lp_nullable-ness of this node
      $tree->{lp_nullable} = 0;
      if ($tree->{left}->{lp_nullable} == 1 || $tree->{right}->{lp_nullable} == 1) {
        # set lp_nullable if either left or right trees are lp_nullable
        $tree->{lp_nullable} = 1;
      }      
    } elsif ($tree->{symbol} eq '.') { # cat
      # determine lastpos
      if ($tree->{right}->{lp_nullable} == 1) {
        push(@{$tree->{lastpos}},@{$tree->{left}->{lastpos}},@{$tree->{right}->{lastpos}});
      } else {
        push(@{$tree->{lastpos}},@{$tree->{right}->{lastpos}}); 
      }
      # determine lp_nullable-ness of this node
      $tree->{lp_nullable} = 0;
      if ($tree->{left}->{lp_nullable} == 1 && $tree->{right}->{lp_nullable} == 1) {
        $tree->{lp_nullable}++;
      }      
    } elsif ($tree->{symbol} eq '*') { # kleene star (closure)
      $tree->{lp_nullable} = 1;
      push(@{$tree->{lastpos}},@{$tree->{left}->{lastpos}});
    }
  }
  return $tree;
}

sub followpos {
  my $self = shift;
  my $tree = shift;
  if (defined($tree->{left})) {
    $self->followpos($tree->{left});
  }
  if (defined($tree->{right})) {
    $self->followpos($tree->{right});
  }
  # Works on one, depth first traversal
  if (!defined($tree->{pos}) && $tree->{symbol} ne '|') {
    if ($tree->{symbol} eq '.') {
      foreach (@{$tree->{left}->{lastpos}}) {
         push(@{$self->{_FOLLOW_POS}{$_}},@{$tree->{right}->{lastpos}}); 
      }     
    } elsif ($tree->{symbol} eq '*') {
      foreach (@{$tree->{lastpos}}) {
        push(@{$self->{_FOLLOW_POS}{$_}},@{$tree->{firstpos}});
      }
    }
  }
}

sub get_followpos {
  my $self = shift;
  return $self->{_FOLLOW_POS};
}

################################################################
# Recursive Descent routines - parse tree is constructed here  # 
################################################################

sub parse {
  my $self = shift;
  # load up first lookahead char
  $self->nexttoken();
  # PARSE
  $self->set_parse_tree($self->R());
  $self->cat_endmarker();
  $self->reset_current();
  return;
}

sub cat_endmarker {
  my $self = shift;
  $self->{_PARSE_TREE} = {symbol=>'.',left=>$self->{_PARSE_TREE},right=>{symbol=>$self->{_RE_END_SYMBOL},pos=>$self->get_next_pos()}};
  return; 
}

sub match {
  my $self = shift;
  my $match = shift;
  chomp($match);
  if ($self->{_TRACE}) {print "match!: '$match'\n"};
  if ($self->lookahead() eq $match) {
    $self->nexttoken();
  } else {
    $self->set_error();
    $self->set_done();
  }
  # returns the symbol passed to it.
  return $match;
}

sub lookahead {
  my $self = shift;
  return $self->{_LOOKAHEAD};
}

sub nexttoken {
  my $self = shift;
  $self->{_LOOKAHEAD} = '';
  if (@{$self->{_CURRENT_STR}}) {
    $self->{_LOOKAHEAD} = shift(@{$self->{_CURRENT_STR}});
  }
  return;
}

sub R {
  my $self = shift;
  my $tree = undef;
  if ($self->{_TRACE}) {print ">R "};
  if (!$self->done()) {
    $tree = $self->O();
  }
  if ($self->{_TRACE}) {print "R> "};
  return $tree;
}

sub O {
  my $self = shift;
  my $tree = shift;
  if ($self->{_TRACE}) {print ">O "};  
  if (!$self->done()) {
    $tree = $self->C();
    $tree = $self->O_prime($tree);
  }
  if ($self->{_TRACE}) {print "O> "};  
  return $tree;
}

sub O_prime {
  my $self = shift;
  my $tree = shift;
  if ($self->{_TRACE}) {print ">O' "};  
  # first rule that contains a terminal symbol
  my $look = $self->lookahead();
  if (!$self->done()) {
    if ($look eq '|') {
      $self->match('|');
      # handles epsilon "or"
      if (!defined($tree)) {
        $tree = {symbol=>$self->get_epsilon_symbol(),pos=>-1};
      }
      my $C = $self->C();
      if (defined($C)) {
        $tree = {symbol=>'|',left=>$tree,right=>$C};
      } else {
	$tree = {symbol=>'|',left=>$tree,right=>{symbol=>$self->get_epsilon_symbol(),pos=>-1}};
      }
      $tree = $self->O_prime($tree);
    }
  }
  if ($self->{_TRACE}) {print "O'> "};
  return $tree;
}

sub C {
  my $self = shift;
  my $tree = shift;
  if ($self->{_TRACE}) {print ">C "};
  if (!$self->done()) {   
    $tree = $self->S();
    $tree = $self->C_prime($tree);
  }
  if ($self->{_TRACE}) {print "C> "};
  return $tree;
}

sub C_prime {
  my $self = shift;
  my $tree = shift;
  if ($self->{_TRACE}) {print ">C' "};
  my $look = $self->lookahead();
  if (!$self->done()) {
    if ($self->get_cat_state() == 1) {
      $self->toggle_cat_state();
      my $S = $self->S();
      if (defined($tree)) {
	if (defined($S)) {
          $tree = {symbol=>'.',left=>$tree,right=>$S};
	}
      } else {
	if (defined($S)) {
          $tree = $S;
	}
      }
      $tree = $self->C_prime($tree);      
    }
  }
  if ($self->{_TRACE}) {print "C'> "};
  return $tree;
}

sub S {
  my $self = shift;
  my $tree = shift;
  if ($self->{_TRACE}) {print ">S "};  
  if (!$self->done()) {
    $tree = $self->L($tree);
    $tree = $self->S_prime($tree);
  }
  if ($self->{_TRACE}) {print "S> "};  
  return $tree;
}

sub S_prime {
  my $self = shift;
  my $tree = shift;
  if ($self->{_TRACE}) {print ">S' "};  
  my $look = $self->lookahead();
  if (!$self->done()) {
    if ($look eq '*') {
      $self->match('*');
      $tree = {symbol=>'*',left=>$self->S_prime($tree),right=>undef};
    }
  }
  if ($self->{_TRACE}) {print "S'> "};  
  return $tree;
}

sub L {
  my $self = shift;
  my $tree = shift;
  if ($self->{_TRACE}) {print ">L "};  
  my $term = $self->lookahead();
  if (!$self->done()) {
    if ($term eq '(') {
      $self->match('(');      
      $tree = $self->R();
      $self->match(')');
      if (!defined($tree)) {
        $tree = {symbol=>$self->get_epsilon_symbol(),pos=>-1};
      }
      $self->toggle_cat_state();      
    } else {
      foreach my $terminal ($self->get_terminals()) {
        if ($term eq $terminal) {
          $self->match($term);
	  #set position automatically
	  $tree = {symbol=>$term,pos=>$self->get_next_pos()};
          $self->toggle_cat_state();
	  last;
        }
      }
    }
  }
  if ($self->{_TRACE}) {print "L> "};  
  return $tree;
}

sub get_next_pos {
  my $self = shift;
  return ++$self->{_POS_COUNT};
}

sub get_curr_pos {
  my $self = shift;
  return $self->{_POS_COUNT};
}

sub set_parse_tree {
  my $self = shift;
  $self->{_PARSE_TREE} = shift;
  return;
}

sub get_parse_tree {
  my $self = shift;
  return $self->{_PARSE_TREE};
}

sub get_terminals {
  my $self = shift;
  return @{$self->{_TERMINALS}};
}

sub is_terminal {
  my $self = shift;
  return $self->is_member(shift,$self->get_terminals());
}

sub is_member {
  my $self = shift;
  my $test = shift;
  my $ret = 0;
  if (defined($test)) {
    # This way to test if something is a member is significantly faster..thanks, PM!
    if (grep {$_ eq $test} @_) {
      $ret++;
    }
  }
  return $ret;
}

sub get_symbols {
  my $self = shift;
  return @{$self->{_SYMBOLS}}; 
}

sub trace_on {
  my $self = shift;
  $self->{_TRACE} = 1;
  return;
}

sub trace_off {
  my $self = shift;
  $self->{_TRACE} = 0;
  return;
}

sub trace {
  my $self = shift;
  return $self->{_TRACE};
}

sub toggle_cat_state {
  my $self = shift;
  if ($self->get_cat_state == 0) {$self->{_CAT_STATE}++} else {$self->{_CAT_STATE} = 0}; 
  return;
}

sub get_cat_state {
  my $self = shift;
  return $self->{_CAT_STATE}; 
}

sub set_error {
  my $self = shift;
  $self->{_ERROR}++;
}

sub get_error {
  my $self = shift;
  return $self->{_ERROR};
}

sub set_done {
  my $self = shift;
  $self->{_DONE}++;
} 

sub done {
  my $self = shift;
  return $self->{_DONE};
}

sub DESTROY {
  return;
}

1;

__END__

=head1 NAME

RE - A regular expression base class

=head1 SYNOPSIS

    use FLAT::Legacy::FA::RE;
    use FLAT::Legacy::FA::NFA;
    my $re = RE->new();
    $re->set_re('a|b|(hi)*');
    my $nfa = $re->to_nfa();
    print $nfa->info(); # see stuff on NFA
    my $dfa = $nfa->to_dfa(); 
    print $dfa->info(); # see stuff on DFA
    my @removed = $dfa->minimize();
    print $dfa->info(); # see stuff on minimized DFA
    print "Removed ".($#removed+1)." states\n";

=head1 DESCRIPTION

This module implements a regular expression
parser, and supports the conversion of a RE to
a deterministic finite automata.  A homegrown recursive
descent parser is used to build the parse tree, and the method
used to conver the regular expression to a DFA uses no intermediate
NFA.

Recursive Descent-safe Regex Grammar:

 R  -> O

 O  -> CO'

 O' -> '|' CO' | epsilon

 C  -> SC'

 C' -> .SC' | epsilon

 S  -> LS'

 S' -> *S' | epsilon

 L  -> a | b | c |..| 0 | 1 | 2 |..| (R) | epsilon

 Terminal symbols: a,b,c,..,z,0,1,2,..,9,|,*,(,)

 NOTE: Concatenation operator, '.', is not a terminal symbol
 and should not be included in the regex

 FAQ:
   Q: Does this support Perl regular expressions?
   A: No, just the regular expression using the terminal symbols
      listed above.

B<Valid terminal characters include:>

I<a b c d e f g h i j k l m n o p q r s t u v w x y z>

I<A B C D E F G H I J K L M N O P Q R S T U V W X Y Z>

I<0 1 2 3 4 5 6 7 8 9 + - = ? & [ ] { } . ~ ^ @ % $>

I<: ; < >>

=head1 AUTHOR

Brett D. Estrade - <estrabd AT mailcan DOT com>

=head1 CAVEATS

Currently, all states are stored as labels.  There is also
no integrity checking for consistency among the start, final,
and set of all states.

=head1 BUGS

C<to_dfa> is broken, and is now listed as C<to_dfa_BROKEN> so there
is no confusion.  I am currently debating whether or not to fix it,
or reimplement it in FLaT 1.0.

=head1 AVAILABILITY

Perl FLaT Project Website at L<http://perl-flat.sourceforge.net/pmwiki>

=head1 ACKNOWLEDGEMENTS

This suite of modules started off as a homework assignment for a compiler
class I took for my MS in computer science at the University of Southern
Mississippi.  It then became the basis for my MS research. and thesis.

Mike Rosulek has joined the effort, and is heading up the rewrite of
Perl FLaT, which will soon be released as FLaT 1.0.

=head1 COPYRIGHT

This code is released under the same terms as Perl.

=cut
