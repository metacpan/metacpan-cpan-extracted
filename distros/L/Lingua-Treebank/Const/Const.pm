package Lingua::Treebank::Const;

use 5.008;
use strict;
use warnings;
use Carp;

use Lingua::Treebank;
our $VERSION = '0.16'; # stay in sync automatically
our $VERBOSE = $Lingua::Treebank::VERBOSE;
our $BF_TRAVERSAL;
##################################################################
use constant {
    TAG      => 1,
    ANNOT    => 2,
    WORD     => 3,
    PARENT   => 4,
    CHILDREN => 5,
    NUM      => 6,
    HEADCHILD => 7, # only used after Headfinder
};
use overload
  '""'     => \&stringify,
  '0+'     => \&numerify, # find location in memory
  fallback => 1, # numeric tests measure memory location
  ;
##################################################################
our $INDENT_CHAR = ' ' x 4;
our $CHILD_PROLOG = "\n";
our $CHILD_EPILOG = "";
our $STRINGIFY = 'as_penn_text';
##################################################################
sub numerify {
    my $self = shift;
    my $num = $self->[NUM];
    confess "no numeric value!?" unless defined $num;
    return $num;
}
## the approach below is not portable. assign a new number from
## $__NUMID for every constituent at new() instead.
# sub numerify {
#     my $self = shift;
#     if (not defined $self->[NUM]) {
# 	# fetch out the number indicating the location in memory
# 	my $refstr= overload::StrVal( $self );
# 	if ($refstr =~ m{\( 0x ([0-9a-fA-F]+) \) $}x) { #
#             # }
# 	    # cache it for later to save the regex
# 	    $self->[NUM] = hex $1;
# 	}
# 	else {
# 	    confess "numerify wasn't able to extract a numeric ref";
# 	}
#     }
#     return $self->[NUM];
#}
our $__NUMID = 100;  # never be small, just to be sure
sub _next_numid {
  # for assigning unique numeric values to each new constituent;
  # invoked from the ->new() method
  my $class = shift;
  ++$__NUMID;
  return $__NUMID;
}
##################################################################
sub stringify {
    my $self = shift;
    if ($STRINGIFY eq 'as_penn_text') {
	return $self->as_penn_text();
    }
    elsif ($STRINGIFY eq 'words') {
	return join ' ', map { $_->word() } $self->get_all_terminals();
    }
    elsif ($STRINGIFY eq 'preterm_tags') {
	return join ' ', map { $_->tag() } $self->get_all_terminals();
    }
    else {
	carp "don't recognize \$",
	  __PACKAGE__, "::STRINGIFY value of $STRINGIFY";
    }
}

##################################################################
sub edges {
    my $self = shift;
    return
      map { join ',', @{$_} }
	$self->edges_data(@_);
}
sub edges_data {
    my $self = shift;
    my (%args) = @_;
    my %ignore;
    my $do_terminal =
      (defined $args{'keepterminal'} ? $args{'keepterminal'} : 1);
    if (defined $args{ignore}) {
	%ignore = map {$_ => 1} @{$args{ignore}};
    }
    my %coindex;
    %coindex = %{$args{coindex}} if defined $args{coindex};

    my (@edges) = $self->_edges_driver(0);
    my (@returns);
    for (@edges) {
	next if $ignore{$_->[0]};

	next if (not $do_terminal and $_->[0] =~ /::/);

	$_->[1] = $coindex{$_->[1]} if defined $coindex{$_->[1]};
	$_->[2] = $coindex{$_->[2]} if defined $coindex{$_->[2]};
	push @returns, $_;
    }
    return @returns;
}
sub _edges_driver {
    my $self = shift;
    my $start_index = shift;

    if ($self->is_terminal()) {
	return ([$self->tag() . '::' . $self->word(),
		 $start_index,
		 $start_index + 1]);
    }
    my @edges;
    my $l_idx = $start_index;
    for (@{$self->children()}) {
       push @edges, $_->_edges_driver($l_idx);
       $l_idx = $edges[-1][-1];
    }

    # don't forget the edge for myself
    push @edges, [$self->tag(), $start_index, $l_idx];
    return @edges;
}
##################################################################
sub shared_edges {
    my $self = shift;
    my $other = shift;
    my %args = @_;

    my %is_phantom = map {$_ => 1} @{$args{phantom}};

    my %coindex; # those trees that need coindexation
    if (scalar keys %is_phantom) {
	for ($self->edges_data(%args)) {
	    if ($is_phantom{$_->[0]}) {
		$coindex{$_->[1]} = $_->[2];
	    }
	}
    }

    my %edges;
    for ($self->edges(%args, coindex => \%coindex)) {
	$edges{$_}++;
    }
    my %other_edges;
    for ($other->edges(%args, coindex => \%coindex)) {
	$other_edges{$_}++;
    }
    use List::Util 'min';
    my @to_return;
    for (keys %edges) {
	push @to_return, ($_) x min ($edges{$_} || 0, $other_edges{$_} || 0);
    }
    return @to_return;
}
##################################################################
sub list_constituents {
    my $self = shift;
    if ($self->is_terminal()) {
	return ($self);
    }
    else {
	my @list;
	for (@{$self->children()}) {
	    push @list, $_->list_constituents();
	}
	return $self, @list;
    }
}
##################################################################
# High-power generic function for crawling the tree. Most of the other
# functions could probably be implemented in terms of this one.
sub walk {
    my ($self, $action, $stop_criterion, $state, $bf_traversal) = @_;

    croak "walk()'s first non-self arg not defined"
      unless (defined $action);
    if (ref $action eq '') {
	$action = $self->can($action);
	if (not defined $action) {
	    croak "couldn't find method $action to call from within walk"
	}
    }
    elsif (not ref $action eq 'CODE') {
	croak "walk()'s first non-self arg not CODE-ref"
    }

    if (defined $stop_criterion) {
	if (ref $stop_criterion eq '') {
	    $stop_criterion = $self->can($stop_criterion);
	    croak "couldn't find method $stop_criterion ",
	      " to call from within walk()"
		if (not defined $stop_criterion);
	}
	elsif (not ref $stop_criterion eq 'CODE') {
	    croak "walk()'s stop criterion arg not a CODE-ref";
	}
    }

    my @children = ();
    my @stack = ($self);

    if (not defined $bf_traversal) {
	$bf_traversal = $BF_TRAVERSAL;
    }

  NODE:
    while (1) {
	# take one off the front of the line
	my $node = shift @stack;
	return if not defined $node;

	&{$action}($node, $state);

	if ( defined $stop_criterion
	     and &{$stop_criterion}($node, $state) ) {
	    # don't put the children on the agenda
	    next NODE;
	}

	# else include node's children
	if ($bf_traversal) {
	    # children go in the back of the line
	    push @stack, @{$node->children()};
	}
	else { # depth-first traversal
	    # children go in the front of the line
	    unshift @stack, @{$node->children()};
	}
    }
}
##################################################################
sub find_common_ancestor {

    # returns lowest common ancestor, or undef if there is none.

    my __PACKAGE__ $self = shift;
    my __PACKAGE__ $cousin = shift;

    # error checking
    croak "cousin arg not defined" if not defined $cousin;
    croak "cousin not a " . __PACKAGE__
      unless UNIVERSAL::isa($cousin, __PACKAGE__);

    my __PACKAGE__ $matriarch = $self->root();
    if ( $cousin->root() != $matriarch ) {
	return; # no common ancestor
    }

    my @self_lineage   = $self->path_up_to( $matriarch );
    my @cousin_lineage = $cousin->path_up_to( $matriarch );

    while (@self_lineage and @cousin_lineage) {
	my __PACKAGE__ $self_gramma   = pop @self_lineage;
	my __PACKAGE__ $cousin_gramma = pop @cousin_lineage;
	if ($self_gramma == $cousin_gramma) {
	    $matriarch = $self_gramma;
	}
	else {
	    # stop looking -- once unshared, thereafter its a waste to
	    # keep looking. No incestuous trees here, one would hope.
	    last;
	}
    }

    return $matriarch;
}
##################################################################
sub equiv_to {
    my __PACKAGE__ $self  = shift;
    my __PACKAGE__ $other = shift;

    if ($self->is_terminal()) {
	return 0 unless $other->is_terminal();

	if ($self->tag() ne $other->tag()) {
	    return 0;
	}
	if ($self->word() ne $other->word()) {
	    return 0;
	}

	# otherwise it all passes:
	return 1;
    }
    else {
	# self non-terminal
	return 0 if $other->is_terminal();

	# different number of children
	return 0 if (@{ $self->children() } != @{ $other->children() });

	foreach my $idx ( 0 .. $#{ $self->children() } ) {
	    my __PACKAGE__ $lchild = $self->children($idx);
	    my __PACKAGE__ $rchild = $other->children($idx);
	    if (not $lchild->equiv_to($rchild)) {
		return 0;
	    }
	}
	# otherwise it all passes
	return 1;
    }
}
##################################################################
sub equiv_tags {
    croak "not implemented\n";
}
sub equiv_words {
    croak "not implemented\n";
}
##################################################################
# height/depth functions
##################################################################
sub depth_from {
    # return depth from given target. returns undef if $target is not
    # the ancestor of $self

    my __PACKAGE__ $self   = shift;
    my __PACKAGE__ $target = shift;

    if ($self == $target) {
	return 0;
    }
    elsif ($self->is_root()) {
	carp "depth_from argument not an ancestor of instance";
	# we could check this explicitly, but users may already know
	# this isn't going to happen, so let's not waste cycles
	return (); # not defined
    }
    else {
	return $self->parent->depth_from($target) + 1;
    }
}
##################################################################
sub depth {

    # returns how many steps from self up to root

    my __PACKAGE__ $self = shift;

    # implemented using more general function -- but it does require
    # two traversals of the tree... other implementations may be easier
    return $self->depth_from( $self->root() );

# if benchmarking turns up a problem here, use one of these below
# instead (probably the second, since it involves the fewest stack ops
# and so is probably the fastest).

# simple recursive implementation

##      if ( $self->is_root() ) {
##  	return 0;
##      }
##      else {
##  	return $self->parent->depth() + 1;
##      }

# non-recursive implementation
##      my $d = 0;
##      my __PACKAGE__ $p = $self->parent;
##      until ( $p->is_root() ) {
##  	$h++;
##  	$p = $p->parent;
##      }
##      return $d;

}
##################################################################
sub height {
    # returns longest distance from self down to any leaf

    # could be re-implemented with get_all_terminals, path_up_to and
    # array lengths, but that seems unnecessary
    my __PACKAGE__ $self = shift;

    if ($self->is_terminal()) {
	return 0;
    }
    else {
	my ($max) = 0;

	# choose the largest height among the children, return that
	# (+1)
	foreach my __PACKAGE__ $d (@{ $self->children() }) {
	    my $this_height = $d->height();
	    if ($max < $this_height) {
		$max = $this_height;
	    }
	}
	return $max + 1;
    }
}
##################################################################
sub get_index {
    my __PACKAGE__ $self = shift;
    my __PACKAGE__ $daughter = shift;

    if ($self->is_terminal) {
	carp "get_index called on terminal node, can't get_index";
	return;
    }

    if (not $self == $daughter->parent ) {
	carp "argument not daughter of instance, can't get index";
	return ;
    }

    for ( 0 .. $#{$self->children} ) {
	if ( $self->children($_) == $daughter ) {
	    return $_;
	}
    }

    carp "malformed tree:",
      " daughter identifies instance as parent, but parent does ",
	"not claim daughter";
    return ;
}
##################################################################
# node retrieval functions
##################################################################
sub path_up_to {
    my __PACKAGE__ $self = shift;
    my __PACKAGE__ $terminus = shift;

    # could be done non-recursively, but this is grammatical structure
    # -- very small heights.  Besides, recursivity is cooler, and
    # easier to think about

    if ($self == $terminus) {
	return ($self);
    }
    elsif ( $self->is_root() ) {
	carp "terminus argument not an ancestor of instance!";
	return ;
    }
    else {
	my @path = $self->parent->path_up_to( $terminus );
	if (not @path) {
	    return; # not found
	}
	else {
	    return ( $self, @path );
	}
    }
}
##################################################################
sub root {
    # returns the root of a given node
    my __PACKAGE__ $self = shift;
    if ($self->is_root()) {
	return $self;
    }
    else {
	return $self->parent->root();
    }
}
##################################################################
# Return a list of ancestors of a node matching a criteria given in a
# function parameter.
#    my $path = <<EOTREE;
#    (NP
#     (NP
#      (VP
#       (N dog))))
#    EOTREE
#
#    my $node = Lingua::Treebank::TB3Const->new->from_penn_string($text);
#    my @terms = $node->get_all_terminals();
#    my $node = shift @terms;
#    my @ancestors = $node->select_ancestors(sub{$_[0]->tag() eq "NP"});
sub select_ancestors {
    my __PACKAGE__ $self = shift;
    my $criteria = shift;

    my @ancestors = ();

    $self = $self->parent();
  PARENT:
    while (defined $self) {
	push @ancestors, $self if (&$criteria($self));
	$self = $self->parent();
    }

    return @ancestors;
}
##################################################################
# Return a list of children of a node matching a criteria given in a
# function parameter.  The children are searched breadth-first.
sub select_children {
    my __PACKAGE__ $self = shift;
    my $criteria = shift;

    my @children = ();
    my @stack = ($self);
  CHILD:
    while (1) {
	my $node = pop @stack;
	last CHILD if (not $node);

	push @children, $node if (&$criteria($node));
	push @stack, @{$node->children()};
    }

    return @children;
}
##################################################################
sub get_all_terminals {
    # returns all leaves in a left-right traversal

    my __PACKAGE__ $self = shift;

    my @terminals;

    if ( $self->is_terminal() ) {
	@terminals = ( $self ); # parens force list return
    }
    else {
	foreach my __PACKAGE__ $d ( @{$self->children} ) {
	    push @terminals, $d->get_all_terminals;
	}
    }
    return @terminals;
}
##################################################################
sub next_sib {
    my __PACKAGE__ $self = shift;

    return if $self->is_root; # no sib, return undef

    my __PACKAGE__ $parent = $self->parent;

    my $index = $parent->get_index($self);

    if ($index == $#{$parent->children}) {
	# this is the rightmost of the group of siblings
	return; # no right sib
    }
    return $parent->children($index + 1);
}
##################################################################
sub prev_sib {
    my __PACKAGE__ $self = shift;

    return if $self->is_root; # no sib, return undef

    my __PACKAGE__ $parent = $self->parent;

    my $index = $parent->get_index($self);

    if ($index == 0) {
	# this is the leftmost of the group of siblings
	return; # no left sib
    }
    return $parent->children($index - 1);
}
##################################################################
sub right_leaf {
    my __PACKAGE__ $self = shift;
    # returns rightmost leaf of current node

    if ($self->is_terminal) {
	return $self;
    }
    else {
	my __PACKAGE__ $right_daughter = $self->children(-1);
	return $right_daughter->right_leaf();
    }
}
##################################################################
sub left_leaf {
    my __PACKAGE__ $self = shift;
    # returns leftmost leaf of current node

    if ($self->is_terminal) {
	return $self;
    }
    else {
	my __PACKAGE__ $left_daughter = $self->children(0);
	return $left_daughter->left_leaf();
    }
}
##################################################################
sub prev_leaf {
    # return the next leaf to the left (back in time), not dominated
    # by the current node

    # should behave correctly even when called on a non-terminal --
    # returns the first leaf to the left not-dominated by the current
    my __PACKAGE__ $self = shift;

    my __PACKAGE__ $left_sib = $self->prev_sib;

    if (defined $left_sib) {
	return $left_sib->right_leaf();
    }
    else {
	# no immediate left sib, go up the tree

	if ( $self->is_root() ) {
	    return; # no previous leaves
	}
	else {
	    return $self->parent->prev_leaf();
	}
    }
}
##################################################################
sub next_leaf {
    # return the next leaf to the right (forward in time)

    # should behave correctly even when called on a non-terminal --
    # returns the first leaf to the right not-dominated by the current
    my __PACKAGE__ $self = shift;

    my __PACKAGE__ $right_sib = $self->next_sib;

    if (defined $right_sib) {
	return $right_sib->left_leaf();
    }
    else {
	# no immediate right sib, go up the tree

	if ( $self->is_root() ) {
	    return; # no previous leaves
	}
	else {
	    return $self->parent->next_leaf();
	}
    }
}
##################################################################
# boolean requests (one additional argument)
##################################################################
sub is_descendant_of {
    my __PACKAGE__ $self = shift;
    my __PACKAGE__ $grandma = shift;

    if ($self == $grandma) {
	return 1; # yes, you are your own descendant. :p
    }
    if ($self->is_root) {
	return 0; # root is descendant of nobody, grandma or otherwise
    }
    else {
	return $self->parent->is_descendant_of($grandma);
    }
}
##################################################################
sub is_ancestor_of {
    my __PACKAGE__ $self = shift;
    my __PACKAGE__ $candidate = shift;
    return $candidate->is_descendant_of($self);
}
##################################################################
# Are the two nodes siblings?
#
#  my $sibling = <<EOTREE;
#  (S
#   (NP
#    (D the)
#    (N boy))
#   (VP
#    ran))
#  EOTREE
#
#  my $node = Lingua::Treebank::TB3Const->new()->from_penn_string($sibling);
#  my @child = @{$node->children()};
#  my $np = $child[0];
#  my $vp = $child[1];
#  print "This is true." if ($np->is_sibling($vp));
sub is_sibling {
    my __PACKAGE__ $self = shift;
    my __PACKAGE__ $other = shift;

    return 0 if ($self->is_root() or $other->is_root());

    my __PACKAGE__ $parent = $self->find_common_ancestor($other);
    return 0 if (not defined $parent);

    return ($parent == $self->parent() and $parent == $other->parent());
}
##################################################################
# I/O methods (to/from text)
##################################################################
sub as_penn_text {
    my __PACKAGE__ $self = shift;
    my $step = shift;
    my $indentChar = shift;
    my $child_prolog = shift;
    my $child_epilog = shift;
    my $am_head = shift;

    # set defaults (in case called without full specification)
    $step = 0 if not defined $step;
    $indentChar = $INDENT_CHAR if not defined $indentChar;
    $child_prolog = $CHILD_PROLOG if not defined $child_prolog;
    $child_epilog = $CHILD_EPILOG if not defined $child_epilog;

    # begin composition of text
    my $label = $self->tag();
    if (defined $am_head) {
      if ($am_head) {
	$label = '*'.$label.'*';
      }
    }
    # don't touch if $am_head undef

    if (defined $self->annot()) {
	$label .= '-' . $self->annot();
    }

    my $text = '(' . $label . ' ';

    if ($self->is_terminal) {
	$text .= $self->word();
    }
    else {
	# non-terminal
      my $head = $self->headchild();
      
      foreach my  __PACKAGE__ $d ( @{$self->children} ) {
	$text .= $child_prolog;
	$text .= ($indentChar x ($step + 1));
	my $child_is_head;
	if (defined $head) {
	  $child_is_head = ($head == $d ? 1 : 0);
	}
	$text .= $d->as_penn_text($step + 1, $indentChar, $child_prolog, $child_epilog, $child_is_head);
	$text .= $child_epilog;
      }
    }

    $text .= ')';

    return $text;
}
##################################################################
sub from_cnf_string {
    my __PACKAGE__ $self = shift;
    my $class = ref $self;
    local $_ = shift;

    # Strip leading and trailing whitespace.
    s/^\s+//;
    s/\s+$//;
    # Remove outermost parenthesis pair.
    if (s/^ \( \s* (.*) \s* \) $/$1/x) {
	# This is a non-terminal node.
	# Extract the non-terminal tag.
	s/^(\S+)\s*//;
	my $tag = $1;
	$self->tag($tag);
	# Enumerate all the children of this node.
	while (length $_) {
	    my $childtext;
	    if ( /^\(/ ) {
		# The child is a non-terminal node.
 		$childtext = $class->find_brackets($_);
		substr ($_, 0, length $childtext) = '';
		# BUGBUG check for errors here?
	    }
	    else {
		# The child is a terminal node.
		s/^(\S+)\s*// or carp "couldn't find text in $_\n";
		$childtext = $1;
	    }
	    # Create a child node structure.
	    my __PACKAGE__ $child = $class->new();
	    $child->from_cnf_string($childtext);
	    $self->append($child);
	    # Skip whitespace delimiting children.
	    s/^\s+//;
	}
    }
    elsif (/^([^_]+)_(\S+)$/) {
	# This is a terminal node.
	my ($word, $tag) = ($1, $2);
	$self->word($word);
	$self->tag($tag);
    }
    else {
	croak "can't parse '$_'";
    }
    return $self;
}
##################################################################
sub from_penn_string {
    my __PACKAGE__ $self = shift;
    my $class = ref $self;
    my $text = shift;
    # pass it a complete constituent in text form.

    # records the tag plus a list of its subconstituents. If
    # subconstituents themselves have structure, then they will be
    # arrayrefs

    # JGK: why @tags? can't remember...
#      my (@tags) = shift;


    # strip off front and back parens and whitespace
    $text =~ s/^ \s* \( \s* //x;
    $text =~ s/ \s* \) \s* $//x;

    # handle perverse cases where the brackets are the text, like
    # (NP (-LRB- () (NNP Joe) (-RRB- )))
    $text =~ s/\(-LRB- \(\)/__LPRN__/g;
    $text =~ s/\(-RRB- \)\)/__RPRN__/g;

    # tag is everything up to the first whitespace or
    # parenthesis. Children are everything else.
    my ($tag, $childrentext) =
      ($text =~ /^ ([^\s\(]*)  \s* (.*) $/sx);

    if (not defined $tag or not defined $childrentext) {
	croak "couldn't find a constituent in '$text'";
	return; # undef
    }

    if ($tag =~ m/ ^ ( [^-]+? ) ([-=]) ( .* ) $/x ) {
	my $short_tag = $1;
	if ($2 ne '-') {
	    warn "found '$2' (should be '-') separating annotation ".
	      "in tag $tag\n" if $VERBOSE;
	}
	$self->annot( $3 );
	$self->tag( $short_tag );
    }
    else {
	$self->tag($tag);
    }
    while (length $childrentext) {
	# handle perverse cases where the brackets are the text, like
	# (NP (-LRB- () (NNP Joe) (-RRB- )))
	if ($childrentext =~ s/^\s*__LPRN__\s*//) {
	    my __PACKAGE__ $child = $class->new();
	    $child->tag('-LRB-');
	    $child->word('(');
	    $self->append($child);
	    next;
	}
	elsif ($childrentext =~ s/^\s*__RPRN__\s*//) {
	    my __PACKAGE__ $child = $class->new();
	    $child->tag('-RRB-');
	    $child->word(')');
	    $self->append($child);
	    next;
	}

	my $childtext = $class->find_brackets($childrentext);
	if (defined $childtext) {
	    # child is itself a constituent
	    my __PACKAGE__ $child = $class->new();
	    $child->from_penn_string($childtext);

	    $self->append($child);

#  	    $child->parent($self);
#  	    push @{$self->children}, $child;

	    # chop out the childrentext
	    substr ($childrentext, 0, length $childtext) = "";
	    $childrentext =~ s/^\s+//;

	    warn "trouble -- child constituent found " .
	      "in token that already had word\n"
		if defined $self->word;
	}
	else {
	    if ($childrentext =~ tr {()} {()} ) {
		carp "found a parenthesis in word '$childrentext'; ",
		  " this suggests that the data had unbalanced parens";
	    }

 	    # this is a word; we're done
	    $self->word($childrentext);

	    # eliminate text so that we can exit the while loop
	    $childrentext = '';

	    warn "trouble --  word found in token that "
	      . "already had child constituents\n"
		if @{$self->children};
	}
    }

    return $self;
}
my $bracket_error;
sub find_brackets {
    my $class = shift;
    my $text = shift;
    my $count_l = 1;

    my $posn = -1;

    my $nextL = index $text, '(', $posn+1;
    my $nextR = index $text, ')', $posn+1;

    croak ("I found a right bracket before a left-bracket. ",
	   "Brackets mis-nested. Are you using .psd files instead of .mrg?")
      if $nextR < $nextL;

    return if ($nextL==-1 and $nextR==-1);

    $posn=$nextL;

    if ($posn == -1) {
	# undefined
	return;
    }

    while ($count_l > 0) {
	$nextL=index $text, '(', $posn+1;
	$nextR=index $text, ')', $posn+1;
	if ($nextR == -1) {
	    croak "missing close parens in $text";
	}
	if ($nextL == -1 or $nextR < $nextL) {
	    $count_l--;
	    $posn=$nextR;
	}
	else { # ($nextL < $nextR)
	    $count_l++;
	    $posn = $nextL;
	}
    }
    return substr $text, 0, $posn+1;
}
##################################################################
# Tree modification methods
##################################################################
sub flatten {
    # pull up all terminals to be children of the instance here,
    # regardless of how deep they are

    # see POD below for better details

    my __PACKAGE__ $self = shift;

    if ($self->is_terminal) {
	carp "flatten called on terminal node";
	return;
    }

    foreach my __PACKAGE__ $daughter (@{$self->children}) {

	next if $daughter->is_terminal; # this child's done

	# pull up all descendants of non-terminal daughter to depend
	# directly on the daughter
	$daughter->flatten();

	# now reparent all the grandchildren to self, by retracting
	# the daughter
	$self->retract($daughter);
    }

    return $self;

    # could probably be reimplemented by "get_all_terminals" and
    # judicious use of insert, but this recursive strategy is more
    # elegant and takes advantage of brains of retract() method
}
##################################################################
sub retract {
    # pulls in and removes one layer of non-terminal nodes, attaching
    # their children directly to the current node, retaining what
    # surface order they originally had.

    # see POD for more details

    my __PACKAGE__ $self = shift;
    my __PACKAGE__ $daughter = shift;

    if ( $daughter->parent() != $self ) {
	carp "argument daughter does not claim instance as mother,",
	  " can't retract!";
	return;
    }

    if ( $daughter->is_terminal() ) {
	carp "daughter is a terminal node, can't retract!";
	return;
    }

    $self->replace( $daughter, @{$daughter->children} );

    return $self;

}
##################################################################
sub replace {
    # replace target arg with replacement list
    my __PACKAGE__ $self         = shift;
    my __PACKAGE__ $target       = shift;
    my @replacements = @_;

    carp "argument not a child of instance, can't replace!"
      unless ($target->parent == $self);

    my $index = $self->get_index($target);

    $self->detach_at($index);

    $self->insert_at($index, @replacements);
}
##################################################################
sub wither {
    my __PACKAGE__ $self = shift;
    return if $self->is_root();

    my __PACKAGE__ $parent =  $self->parent();

    my $num_sibs = $parent->num_children();

    $parent->detach($self);
    if ($num_sibs == 1) {
	# unary parent, wither it too
	$parent->wither();
    }
}
##################################################################
sub detach {
    # removes an entire subtree.
    my __PACKAGE__ $self = shift;
    my __PACKAGE__ $daughter = shift;

    # actually do the detachment
    my $index = $self->get_index($daughter);

    $self->detach_at($index);

}
##################################################################
sub detach_at {
    # remove one daughter node at index
    my __PACKAGE__ $self = shift;
    my $index = shift;

    if (not defined $index) {
	croak "no index provided to detach_at method";
    }

    my __PACKAGE__ $d = $self->children($index);

    if (not defined $d) {
	carp "no daughter at index $index";
	return;
    }

    # remove links
    $d->clear_parent();

    if (defined $self->headchild() and $self->headchild() == $d) {
	$self->clear_headchild();
    }

    splice @{$self->children}, $index, 1, (); # replace with empty list
}
##################################################################
sub prepend {
    my __PACKAGE__ $self = shift;
    my @daughters = @_;
    $self->insert_at(0, @daughters);
}
##################################################################
sub append {
    my __PACKAGE__ $self = shift;
    my @daughters = @_;
    $self->insert_at(scalar @{$self->children}, @daughters);
}
##################################################################
sub insert_before {
    my __PACKAGE__ $self = shift;

    my $parent = $self->parent();
    my $position = $parent->get_index($self);

    my @sibs = @_;
    $parent->insert_at($position, @sibs);

    return $self;
}
##################################################################
sub insert_after {
    my __PACKAGE__ $self = shift;

    my $parent = $self->parent();
    my $position = $parent->get_index($self);

    my @sibs = @_;
    $parent->insert_at($position + 1, @sibs);

    return $self;
}
##################################################################
sub insert_at {
    my __PACKAGE__ $self     = shift;
    my $position = shift;
    my @daughters = @_;

    foreach my __PACKAGE__ $d (@daughters) {
	$d->parent($self);
    }

    splice @{$self->children}, $position, 0, @daughters;
    return $self;
}
##################################################################
# FEATURES OF THE CURRENT NODE
##################################################################
sub is_root {
    my __PACKAGE__ $self = shift;
    return ( not defined $self->[PARENT] );
}
##################################################################
# Is this an empty root node?
#
#    my $text = <<EOTREE;
#    (
#      (INTJ
#          (UH Okay)
#          (. .)
#          (-DFL- E_S)))
#    EOTREE
#
#    my $node = Lingua::Treebank::TB3Const->new->from_penn_string($text)
#    print "This is true." if ($node->is_empty_root());
#
sub is_empty_root {
    my __PACKAGE__ $self = shift;

    return ($self->is_root() and
	    not $self->tag() and
	    scalar(@{$self->children()}) == 1 )
}
#################################################################
sub is_terminal {
    my __PACKAGE__ $self = shift;
    if (defined $self->[WORD]) {
	if ( @{$self->children()} ) {
	    carp "how did I get children AND a word?";
	}
	return 1;
    }
    else {
	if ( not @{ $self->children() } ) {
	    croak "how did I get neither a word NOR children?";
	    return 1; # might as well terminate
	}
	return 0;
    }
}
##################################################################
sub children {
    my $self = shift;
    if (@_ > 2) {
	croak "children() called with >2 args";
    }
    if (@_ == 2) {
	# e.g. $d->children(1, $foo_child);
	croak "wrong package type: ", ref($_[1]),
	  " .  Expecting ", __PACKAGE__
	    unless UNIVERSAL::isa($_[1], __PACKAGE__);

	return $self->[ CHILDREN ][ $_[0] ] = $_[1];

    }
    if (@_ == 1) {
	if (ref $_[0] eq 'ARRAY') {
	    # reset entire array,
	    # e.g. $d->children([ $foo, $bar ])
	    foreach (@{$_[1]}) {
		if (not UNIVERSAL::isa($_, __PACKAGE__)) {
		    croak "ref ", ref $_, " in arrayref not a ",
		      __PACKAGE__;
		}
	    }
	    $self->[ CHILDREN ] = $_[1];
	}
	else {
	    # getting single element
	    # e.g. $d->children(2);
	    return $self->[ CHILDREN ][ $_[0] ];
	}
    }
    # else no args
    return $self->[ CHILDREN ];
}
##################################################################
sub num_children {
    my $self = shift;
    return scalar @{$self->[ CHILDREN ]};
}
##################################################################
# Functions for headed trees
##################################################################
sub capitalize_headed {
  my __PACKAGE__ $self = shift;
  if ($self->is_terminal) {
    return;
  }
  my $head = $self->headchild();
  for my $kid (@{$self->children}) {
    if ($kid == $head) {
      $kid->tag(uc $kid->tag());
    }
    else {
      $kid->tag(lc $kid->tag());
    }
    $kid->capitalize_headed();
  }
}

sub maximal_projection {
  # given a node (usually a leaf!) climb the tree until I'm not the
  # headword any more
  my __PACKAGE__ $self = shift;
  my $maximal = $self;

 CLIMB:
  while (1) {
    my $parent = $maximal->parent();
    if (not defined $parent or $parent->headterminal() != $self) {
      last CLIMB;  # done! $maximal is it
    }
    $maximal = $parent;
  }
  return $maximal;
}
##################################################################
sub clear_headchild {
    my __PACKAGE__ $self = shift;
    $self->[HEADCHILD] = undef;
}
##################################################################
sub headterminal {
    my __PACKAGE__ $self = shift;
    if ($self->is_terminal()) {
	return $self;
    }
    my $headchild = $self->headchild();

    return undef if not defined $headchild;

    return $headchild->headterminal();
}
##################################################################
sub headchild {
    my __PACKAGE__ $self = shift;
    if (@_) {
	# setting
	if (@_ > 1) {
	    croak "->headchild() called with >1 argument";
	}
	my $val = $_[0];
	croak "->headchild() argument wrong class"
	  if ( not UNIVERSAL::isa($val, __PACKAGE__) );

	if (not grep { $val == $_ } @{$self->[ CHILDREN ]}) {
	    croak "->headchild() setting used value that wasn't ",
	      "one of its kids";
	}
	$self->[HEADCHILD] = $val;
    }
    else {
	# getting
	return $self->[HEADCHILD];
    }
}
##################################################################
sub parent {
    my __PACKAGE__ $self = shift;
    if (@_) {
	# setting
	if (@_ > 1) {
	    croak "parent called with >1 argument";
	}
	my $val = $_[0];
	croak "parent argument wrong class"
	  if ( not UNIVERSAL::isa($val, __PACKAGE__) );
	$self->[PARENT] = $val;
    }
    else {
	# getting
	return $self->[PARENT];
    }
}
##################################################################
sub clear_parent {
    my $self = shift;
    $self->[PARENT] = undef;
}
##################################################################
sub tag {
    my __PACKAGE__ $self = shift;
    if (@_) {
	# setting
	if (@_ > 1) {
	    croak "tag() called with >1 argument";
	}
	carp "tag() passed a reference!" if ref($_[0]);
	$self->[TAG] = $_[0];
    }
    else {
	# getting
	return $self->[TAG];
    }
}
##################################################################
sub annot {
    my __PACKAGE__ $self = shift;
    if (@_) {
	# setting
	if (@_ > 1) {
	    croak "annot() called with >1 argument";
	}
	carp "annot() passed a reference!" if ref($_[0]);
	$self->[ANNOT] = $_[0];
    }
    else {
	# getting
	return $self->[ANNOT];
    }
}
##################################################################
sub word {
    my __PACKAGE__ $self = shift;
    if (@_) {
	# setting
	if (@_ > 1) {
	    croak "word() called with >1 argument";
	}

	if (@{$self->[CHILDREN]}) {
	    croak "can't assign a word when children exist, failing!";
	    return;
	}

	carp "word() passed a reference!" if ref($_[0]);
	$self->[WORD] = $_[0];
    }
    else {
	# getting
	return $self->[WORD];
    }
}
##################################################################
sub text {
    my __PACKAGE__ $self = shift;
    return join(" ", 
		map {$_->word()} 
		grep {$_->tag ne '-NONE-'}
		$self->get_all_terminals());
}
##################################################################
sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless [], $class;
    $self->[CHILDREN] = [];
    $self->[NUM] = $class->_next_numid();
    foreach (keys %args) {
	if ($self->can($_)) {
	    $self->$_($args{$_});
	}
	else {
	    carp "unknown argument $_";
	}
    }
    return $self;
}
##################################################################

1;

__END__

=head1 NAME

Lingua::Treebank::Const - Object modeling constituent from a treebank

=head1 SYNOPSIS

  use Lingua::Treebank::Const;

  my $text = <<EOTREE
  (S
    (NP-SBJ (DT this) )
    (VP (VBZ is)
      (NP-PRD (NNP Lisa) ))
    (. .) )
  TREE

  my $utt = Lingua::Treebank::Const->new->from_penn_string($text)

  print $utt->as_penn_text(), "\n";;

Results:

  (S
      (NP-SBJ
          (DT this))
      (VP
          (VBZ is)
          (NP-PRD
              (NNP Lisa) ))
      (. .))

This is configurable (TO DO: document how so).


=head1 ABSTRACT

  module defines methods for accessing syntactic constituents; it
  identifies its parents and its children, and can write itself out in
  a variety of formats (currently Penn treebank style).

=head1 DESCRIPTION

Module for describing simple constituents of the Penn
Treebank. Recursive behaviors are implied.

Note assumption that terminal nodes (those with defined C<word>
values) will not have C<children>, and vice versa. This assumption is
currently unchecked by the code.

For a number of these methods, the jargonish notion of I<domination>
plays a large role, so for those who might not know:

a node C<A> I<dominates> another node C<B> if C<B> is a descendant of
C<A>.

=head1 Class methods

=over

=item new

Constructs a new (uninitialized) token.  If starting from text, can be
used together with the C<from_penn_string> initialization method, as
below:

  my $text = <<EOTREE
  (S
    (NP-SBJ (DT this) )
    (VP (VBZ is)
      (NP-PRD (NNP Lisa) ))
    (. .) )
  TREE

  my $utt = Lingua::Treebank::Const->new->from_penn_string($text)

Otherwise, resulting new unit will have no values (C<parent>,
C<children>, C<tag> or C<word> set by default.

=back

=head1 Instance methods

=head2 creation methods

These methods help to populate the fields of these objects from
external data.

=over

=item from_penn_string

given a string of the Penn format, e.g.,

  (S
    (NP-SBJ (DT this) )
    (VP (VBZ is)
      (NP-PRD (NNP Lisa) ))
    (. .) )

populates the current node with C<tag> C<S> and the C<children> field
with new objects (C<tag> C<NP>, C<tag> C<VP>, and C<tag> C<.>). This
method recurses on C<new> and C<from_penn_string> to do its job.

=back

=head2 simple attributes

=over

=item tag

Records the tag of this constituent (0-domination).  (This is the part
of the constituent-label before the hyphen -- after the hyphen is the
C<annot>, not the C<tag>).

TO DO: example here.

=item annot

Returns whatever comes after the hyphen in the constituent label.

=item word

If this constituent is terminal, then C<word> should contain the
lexical item that is represented.

=item text

A string containing the word values of the terminal nodes donminated
by this constituent.  For example, calling text on a node created from
the Penn text given in the description of the new function returns the
string "this is lisa .".

=item parent

Returns the parent of the current node.

=item children

Returns a reference to an array of C<Lingua::Treebank::Const> objects
that are the children of the current node.

Currently does not check whether C<word> is populated.

=back

=head2 methods about parentage

These methods ask questions about the dominating ancestors and direct
children of the current node. Think of them as navigating up-and-down
the tree.

=over

=item is_terminal

No arguments

Returns whether self is a leaf.  Does not check whether C<children>
are populated; if automatically generated from the C<from_penn_string>
method then this will always be correct.

=item is_root

No arguments. Boolean. Returns whether the instance is a root node
(has no parents).

=item root

No arguments.

Returns the root node for the instance in question (might be itself)

=item path_up_to

Takes an ancestor node as argument.

Returns a list of all the nodes (distal first) between the instance
and the root.

Returns I<undefined> and C<carp>s when the given node is not an
ancestor of the instance.

=item is_descendant_of

Takes presumed ancestor as argument.

Returns whether the ancestor is indeed an ancestor of the current
instance.

=item is_ancestor_of

Takes presumed descendant as argument.

Returns whether current instance is an ancestor of the presumed
descendant.

=item is_sibling

Takes presumed sibling as argument.

Returns whether current instance shares an immediate parent with the
presumed sibling.

=item height

No arguments.

Returns the I<farthest> distance from the current node to a terminal
node.

=item depth

No arguments.

Returns the distance from the instance to the root.

=item depth_from

what's the distance from the current node up to the node given as
argument? (return I<undefined> if the node given is not the ancestor
of the instance node)

=back

=head2 methods about siblings

These methods ask questions about siblings, and left-right movement in
the tree. Think of them as moving left-and-right around in the tree.

=over

=item get_index

One argument (daughter).

Returns the index of the daughter in the instance's C<children>
list. Zero-based, of course.

=item prev_sib

=item next_sib

No arguments. Returns next (or previous) sibling at the same level
(dependent on the same parent), or the empty list if no such leaf
exists.

=item prev_leaf

=item next_leaf

No arguments. Returns the leaf just before (or after) any of the
leaves of this node, or the empty list if no such leaf exists.

=item left_leaf

=item right_leaf

No arguments. Returns leftmost (rightmost) leaf dominated by the
instance.

=item get_all_terminals

No arguments.  Returns left-to-right list of all terminal nodes at or
below the current node.

=item find_common_ancestor

One argument: a presumed cousin.

returns the lowest ancestor the instance and the cousin share (or
undefined if they do not share an ancestor)

=item select_ancestors

=item select_children

Both these methods take a subroutine as an argument and return those
[child/ancestor] nodes that return true when the sub is called with
the node as an argument.

The expectation is that the sub will not modify the node.

=back

=head2 methods about structural comparison

These methods are ways of exposing and comparing regions of local
structure.

=over

=item equiv_to

Tests whether the argument has the same structure (and words) as the
instance. These need not be the same object, just the same tags and
words in the same structure.

=item equiv_tags

=item equiv_words

Handy -- and unimplemented -- shorthands for checking certain kinds of
matching structure.

=back

=head2 methods about tree structure modification

=over

=item detach

Argument is I<DAUGHTER> node.

Removes the I<DAUGHTER> from the C<children> list of the current
instance. I<DAUGHTER> node will still be a valid node, but it will no
longer have a C<parent>; it will be a C<root>.

Note that C<detach> may leave a degenerate tree: it may have no
terminal node (one with words) at the end of a branch. To avoid this,
use C<wither> instead.

=item wither

No arguments.

Detaches self from parent. self will become an independent root.  If
the parent has no other children, will recursively call
C<parent->wither>, making a possibly zero-length list of degenerate roots
above it until an ancestor has a different child than the one in this
line of descent.

         A                   A
        / \    	     C   B   |
       B   X   	    / \      X
      /     \   => D   E     |
     C       Y 	             Y
    / \
   D   E
           Before    After

        calling C->wither()


=item prepend

=item append

Arguments are a I<LIST> of new daughters to be inserted at the
beginning/end of the C<children> list.

=item replace

Arguments are (I<DAUGHTER>, I<LIST>).  Replaces I<DAUGHTER> with the
elements of I<LIST> in the C<children> of the current instance.

I<DAUGHTER> is now its own C<root>; see C<detach>.

=item flatten

pull up all terminals to be children of the instance, regardless of
how deep they are. Re-attach them to the current node, preserving leaf
order.

  A->flatten()

       /        /
      A   ==>  A__
     / \      /|\ \
    X   B    C F D G
   /|\   \
  C F D   E
           \
            G

=item retract

pulls in and removes one non-terminal node (I<which> node is specified
by argument), attaching its children directly to the current node,
retaining what surface order the children originally had, e.g.:

   A->retract(X)

       /        /
      A   ==>  A
     / \      /|\
    X   B    C D B
   / \   \    / \ \
  C   D   E  F   G E
     / \
    F   G

=item detach_at

Argument is I<INDEX>.  Removes the daughter at I<INDEX>.  Will C<carp>
if there is no daughter at I<INDEX>.

The daughter at I<INDEX> remains well-formed, though if you do not
maintain your own pointer to it, it will probably be collected by
the garbage collector.

=item insert_at

Arguments are I<INDEX>, I<LIST> of daughters.  I<LIST> daughters will
be inserted beginning at position I<INDEX> of the current instances
C<children>.

=back

=head2 utility methods

These methods are methods that may (or not) be useful in programming
with these objects.  These methods are used internally, but are
exposed for the programmer who might need them.

C<stringify> overloading is certainly helpful in debugging, since the perl
debugger representation of these objects is complicated by their
up-reference to parents.

=over

=item as_penn_text

Returns a text string representing this constituent.

B<To do: document additional parameters to this, and the possible
effects of changing them>

=over

=item C<$Lingua::Treebank::Const::CHILD_PROLOG>

=item C<$Lingua::Treebank::Const::INDENT_CHAR>

=item C<$Lingua::Treebank::Const::CHILD_EPILOG>


=back

=item stringify

This is the method called by default when the object handle is used in
a string (see C<perldoc overload>).

Depending on the value of C<$Lingua::Treebank::Const::STRINGIFY> (see
below), the string representation of the object varies. The default
behavior is C<as_penn_text>, above.

Note that like any object-ref, copying its stringification does NOT
work to retain all its behaviors. Nor does an identical string
representation necessarily mean the two objects are the I<same>
object; merely, that they have the same structure. (see C<equiv_to>).

=item numerify

This is the mthod called by default when the object handle is used in
a numeric context (usually C<==> or C<!=>).

Returns an integer representing the unique object. Identity on this
method I<does> indicate identity of the objects.

Rarely used in client code. The numeric inequality operators are
unlikely to have any useful meaning on these objects, though they
should behave consistently (you should get consistent answers given
any two objects, regardless of methods called on those objects).

=back

=head2 power user methods

=over

=item walk ( &action, &stop_crit, $state, $bf_traversal )

An instance method. C<&action> argument is required, others are optional.

Calls C<&action> (a subroutine ref) as a method on node and its
children, recursively, passing the node under consideration and the
C<$state> value (if provided).

If C<&stop_crit> is defined, calls it on each node; when C<&stop_crit>
returns true, children of that node are not pursued.

For both C<action> and C<stop_crit> commands, if a string is passed,
it will be called if a method by that name can be found in the object.

C<$state> is passed into each of the child method calls.  This is
convenient for things like pushing interesting elements onto a list,
or updating a counter. It must be a scalar, but can be a reference.

Passing a true value as C<$bf_traversal> tells C<walk()> to explore
the tree breadth-first rather than depth-first.  passing a false (but
defined) value forces depth-first.  Undefined values default to the
value of C<$Lingua::Treebank::Const::BF_TRAVERSAL>, which is C<undef>
(false) -- and thus depth-first by default.


  # find out how many children each NP has, but don't count anything
  # inside an EDITED node
  my $action = sub {
      my ($self, $state) = @_;
      return unless $self->tag() eq 'NP';

      # just print it
      print scalar @{$self->children}, "\n";

      # or store it in the state variable
      push @{$state}, scalar @{$self->children()};
    };

  my $stop_crit = sub {$_[0]->tag() eq 'EDITED'};

  $tree->walk( $action, $stop_crit, \@counts );

  use List::Util 'sum';
  print "there were ", sum (@counts),
        " total children of NP nodes\n";

=back

=head1 Class variables

=over

=item $Lingua::Treebank::Const::BF_TRAVERSAL

Defaults to undefined. If true, changes the default behavior of the
walk() method to be breadth-first rather than depth-first.

=item $Lingua::Treebank::STRINGIFY

Changes the default stringification of the objects. Can be set to any
of the following three values:

=over

=item as_penn_text

default value.

e.g.

  (S
    (NP
      (NNP Joe)
    )
    (VP
      (VB likes)
      (NP
        (NNP Bach)
      )
    )
    (. .)
  )

=item words

e.g.

  Joe likes Bach .

=item preterm_tags

e.g.,

  NNP VB NNP .

=back

=back

=head1 To Do

check that destroy doesn't leak (undo parent links?)

dump as latex tree

read in other treebank formats (latex trees?)

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.22 with options

  -CAX
	Lingua::Treebank::Const

=item 0.02

=over

=item Improved comparison code by caching numerify results.

Should give minor speed improvements for data that works with the same
tree over more than one operation. Little if any degradation (tiny
increase in size) for those who only use each tree once.

=item Improved documentation.

Now lists all instance methods.  Instance method documentation also
organized better -- now falls into categories.

=back

=item 0.03

=over

=item new interface variable

added $VERBOSE variable for suppressing non-fatal errors.

=item improved parsing

now copes with examples like (e.g.):

  ((FRAG (FOO bar))

critically, earlier versions failed when the tag was empty and not
followed by whitespace

=back

=item 0.08

=item added new methods

=over

=item select_ancestors

=item select_children

=item is_empty_root

=item walk

=back

=item new interface variable

added $BF_TRAVERSAL for changing walk() method defaults

=item 0.09

=over

=item added new methods

TODO: document these, add test cases, update version number 

=over

=item edges

now with new ignore feature!

=item shared_edges

=item list_constituents

=back

=back

=item 0.16

Version number jump to keep up with Lingua::Treebank

=back


=head1 SEE ALSO

Documentation for Penn treebank L<http://www.cis.upenn.edu/~treebank/>.

=head1 AUTHOR

Jeremy Gillmor Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jeremy Gillmor Kahn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
