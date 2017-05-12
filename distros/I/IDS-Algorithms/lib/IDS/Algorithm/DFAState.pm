package IDS::DFAState;
$IDS::DFAState::VERSION = "1.1";

=head1 NAME

IDS::DFAState - A state in a Deterministic Finite Automata (L<DFA>)
or a Hidden Markov Model (L<HMM>).

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

=head1 DESCRIPTION

=head2 Introduction

This class is for people writing various forms of finite
automata.  It is unlikely to be useful to others.

Note that a state is rarely accessed other than through a reference.
A token is always a simple string.

A state consists of the following:

=over

=item inbound

A hash with key of a reference to a state and a value of a reference to
a hash indexed by tokens that that that cause a transition to us (the
value of this hash is just "1"; we use a hash because it is a set and
not a list).  If the hash is empty, we will be pruned shortly.  

Class methods that provide information relating to this variable:

=over

=item L</in_links>

How many states have transitions to us

=item L</in_states>

What states have transitions to us

=item L</in_tokens>

what are the tokens causing an inbound transition

=item L</exists_inbound_from>

If a state is in the list

=back

Functions that change this variable:

=over

=item L</add_inbound>

Add an inbound state

=item L</absorb>

=item L</dropped_edge>

=back

=item outbound

A hash, indexed by tokens causing the transition, of references
to states that we can transition to.  We can have only one outbound
transition per token, so this is a DFA and not a NFA state.
Functions that provide information relating to this
variable:

=over

=item L</out_links>

How many outbound links do we have

=item L</out_states>

States we can reach

=item L</out_tokens>

Tokens causing transitions

=item L</token_to>

What token causes a transition to a specified state

=item L</next>

What state we transition to for a given token.

=back

Functions that change this variable:

=over

=item L</add_outbound>

=item L</absorb>

=item L</move>

=item L</drop_edge>

=item L</drop_link_to>

=back

=item out_count

Out_count keeps track of every time an edge is traversed.  When used in
a DFA, the counts may be used to know which edges are not used, and thus
are candidates for pruning.  When used in a HMM, out_count keeps track
of every time an edge is traversed for computing probabilities later.
This variable is a hash, indexed by the token causing the transition,
with the value being the count.

Functions that provide information relating to this variable:

=over

=item L</out_count>

the count for a given token

=back

Functions that change this variable:

=over

=item L</followed>

=item L</reset_counters>

=back

As well as all of the functions that manipulate the variable outbound.

=item visits

When the DFA is being used, visits keep track of the number of times
this node has been visited.  It is used in pruning to delete un-used
nodes.  Functions that provide information relating to this variable:

=over

=item L</visits>

=back

Functions that change this variable:

=over

=item L</visited>

=item L</reset_counters>

=back

Sanity says that the sum of the out counts should equal this count.

=item verbose

As the state does operations, it will print messages that might be
helpful for debugging.  These are controlled by the verbosity level.
The higher the value, the more verbose.  Values beyond 2 are unlikely to
be useful.

=back


=head2 Methods

The only callers of these methods should be methods in L<DFA>, L<HMM>,
or related classes.

=cut

use strict;
use warnings;
use IO::Handle;
use Carp qw(cluck carp confess);
use Tie::RefHash;
use IDS::Utils qw(fh_or_stdout);
use Tk;

=head2 Methods related to construction

Construction involves not just attaching one state to another, but also
the merging of states.

=over

=item new()

=item new(verbosity)

Creates a new IDS::DFAState.  The verbosity level defaults to 0 if it is not
supplied.

=item add_outbound(token, to)

During construction, add an outbound transition for the specified
token to the specified state.

=item add_inbound(inref, intoken)

Private method.  Add a reference to a state that transitions to us.

=item absorb(otherstate)

Absorb the transitions from another (similar) state.  Any tokens that
our state does not have are added.  The resulting counter is the sum of
the current and other states.

All tokens in common must go to the same place or an error results.

=item move(from, to)

Move outbound transitions from the "from" state to the "to" state.
This function will be called during a state merge, to reset the
transitions to the new state.

The counter is not changed since all that occurs is a move; the count
can still be considered valid.

=back

=cut

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = {
	"outbound"    => {}, # transition table keyed by token; this
	                     # implies that we have a DFA and not a NFA
			     # since we can only have one outbound link
			     # per token.
	"out_count"   => {}, # counters for the times the edge has been used
	"inbound"     => {}, # what states have transitions into this one?
	"visits"      => 0,  # counter for uses of this node
	"verbose"     => shift || 0,
    };
    tie %{$self->{"inbound"}}, 'Tie::RefHash';
    bless($self, $class); # consecrate
    return $self;
}

sub add_outbound {
    my $self = shift;
    my $token = shift;
    defined($token) or
        confess *add_outbound{PACKAGE} . "::add_outbound Missing token";
    my $to = shift;
    defined($to) or 
        confess *add_outbound{PACKAGE} . "::add_outbound Missing to";
    $to->isa("IDS::DFAState") or
        confess *add_outbound{PACKAGE} . "::add_outbound 'to' is wrong type";

    # sanity check that we are not moving an existing transition
    confess "Moving an existing transition from  $self to $to on $token"
        if exists(${$self->{"outbound"}}{$token}) and 
	   ${$self->{"outbound"}}{$token} ne $to;

    # See if the transition already exists; if so, we are done.
    return if exists(${$self->{"outbound"}}{$token}) &&
              ${$self->{"outbound"}}{$token} eq $to;
 
    ${$self->{"outbound"}}{$token} = $to;
    ${$self->{"out_count"}}{$token} = 1;
    $to->add_inbound($self, $token);
}

sub add_inbound {
    my $self = shift;
    my $inref = shift;
    my $intoken = shift;
    defined($inref) or confess "Missing inref in call to add_inbound";
    $inref->isa("IDS::DFAState") or
        confess *add_inbound{PACKAGE} . "::add_inbound 'inref' is wrong type";
    defined($intoken) or confess "Missing intoken in call to add_inbound";

    ${${$self->{"inbound"}}{$inref}}{$intoken} = 1;
}

sub absorb {
    my $self = shift;
    my $other = shift or
        confess *absorb{PACKAGE} . "::absorb Missing 'other'";
    $other->isa("IDS::DFAState") or
        confess *absorb{PACKAGE} . "::absorb 'other' is wrong type";
    
    $self eq $other and 
        confess *absorb{PACKAGE} . "::absorb Trying to absorb myself!";

    # take over the outbound transitions
    for my $token ($other->out_tokens()) {
	my $next = $other->next($token);

	# First, a sanity check to make sure we can stay a DFA
	exists(${$self->{"outbound"}}{$token}) and
	    ${$self->{"outbound"}}{$token} ne $next and
	    confess *absorb{PACKAGE} . "::absorb link clash for $token!";

	# Do we already have this transition, or do we need to add it?
	if (exists(${$self->{"outbound"}}{$token}) &&
	            ${$self->{"outbound"}}{$token} eq $next) {
	    # only need to add counter
	    ${$self->{"out_count"}}{$token} += $other->out_count($token);
	} else {
	    # otherwise, need to add everything
	    ${$self->{"outbound"}}{$token} = $next;
	    exists(${$self->{"out_count"}}{$token}) or
		${$self->{"out_count"}}{$token} = 0;
	    ${$self->{"out_count"}}{$token} += $other->out_count($token);
	    # update list of inbound states in the destination state
	    $next->replace_inbound($other, $self);
	    print STDERR "Absorbing from $other transition for '$token' to $next\n"
		if $self->{"verbose"} > 0;
	}
    }

    # adjust the inbound transitions to point to us
    my @inbound = $other->in_states();
    for my $s (@inbound) {
        $s->move($other, $self);
	print STDERR "moving $s from $other to $self\n"
	    if $self->{"verbose"} > 0;
    }
}

# update the inbound state hash to reflect a change in an inbound
# link
sub replace_inbound {
    my $self = shift;
    my $from = shift or
        confess *move{PACKAGE} . "::move Missing 'from'";
    $from->isa("IDS::DFAState") or
        confess *move{PACKAGE} . "::move 'from' is wrong type";
    my $to = shift or 
        confess *move{PACKAGE} . "::move Missing 'to'";
    $to->isa("IDS::DFAState") or
        confess *move{PACKAGE} . "::move 'to' is wrong type";

    map {${${$self->{"inbound"}}{$to}}{$_} = 1} keys %{${$self->{"inbound"}}{$from}};
    delete(${$self->{"inbound"}}{$from});
}

sub move {
    my $self = shift;
    my $from = shift or
        confess *move{PACKAGE} . "::move Missing 'from'";
    $from->isa("IDS::DFAState") or
        confess *move{PACKAGE} . "::move 'from' is wrong type";
    my $to = shift or 
        confess *move{PACKAGE} . "::move Missing 'to'";
    $to->isa("IDS::DFAState") or
        confess *move{PACKAGE} . "::move 'to' is wrong type";

    for my $t (keys %{$self->{"outbound"}}) {
	if (${$self->{"outbound"}}{$t} eq $from) {
	    ${$self->{"outbound"}}{$t} = $to;
	    ### Update inbound link in destination
	    # ${$self->{"out_count"}}{$t} is not changed since all we are
	    # doing is a move; the count can still be considered valid.
	    print STDERR "Moved from $from to $to for token $t\n"
	        if $self->{"verbose"};
	}
    }
}

=head2 I/O methods

=over

=item print_edges(node_map, filehandle)

=item print_edges(node_map)

Print the edges associated with this state.  If a filehandle is supplied,
print there, STDOUT otherwise.

The node_map is a mapping from node (IDS::DFAState) reference to the node
number assigned to a node by the L<DFA> or L<HMM>.

=item print_vcg_edges(node_map)

Print the outbound transitions in VCG format.  See L<SEE ALSO> for a
reference for the VCG format.

The node_map is a mapping from a node (IDS::DFAState) reference to the node
number assigned to a node by the L<DFA> or L<HMM>.

=item print_vcg_node(node_number)

Print information about this node (state) in VCG format.  The
node_number is our node number.

=back

=cut

sub print_edges {
    my $self = shift;
    my $node_map = shift or 
        confess *print_edges{PACKAGE} . "::print_edges no node_map";
    my $fh = fh_or_stdout(shift);
    my ($src, $dst, $cnt, $label);

    unless (defined($node_map->{$self})) {
	carp "$self (src) has no node map entry!";
	next EDGE;
    }
    EDGE: for my $token (keys %{$self->{"outbound"}}) {
	unless (defined($node_map->{${$self->{"outbound"}}{$token}})) {
	    carp ${$self->{"outbound"}}{$token} . " (dst) ($token) has no node map!";
	    next EDGE;
	}
	$src = $node_map->{$self};
	$dst = $node_map->{${$self->{"outbound"}}{$token}};
	$cnt = ${$self->{"out_count"}}{$token};
	print $fh "State $src To $dst count $cnt Token:\n    $token\n";
    }
}

sub print_vcg_edges {
    my $self = shift;
    my $node_map = shift or 
        confess *print_vcg_edges{PACKAGE} . "::print_vcg_edges no node_map";
    my $fh = fh_or_stdout(shift);
    my ($src, $dst, $label);

    unless (defined($node_map->{$self})) {
	carp "$self (src; vcg) has no node map entry!";
	next EDGE;
    }
    EDGE: for my $token (keys %{$self->{"outbound"}}) {
	unless (defined($node_map->{${$self->{"outbound"}}{$token}})) {
	    carp ${$self->{"outbound"}}{$token} . " (dst; vcg) ($token) has no node map!";
	    next EDGE;
	}
	$src = $node_map->{$self};
	$dst = $node_map->{${$self->{"outbound"}}{$token}};
	$label = $token;
	$label =~ s/"/'/g; # so we can use " in the edge descr
	print $fh 'edge: { sourcename: "' . $src . '" ' .
			  'label: "' . $label . '" ' . 
			  'targetname: "' . $dst .  '" }' .
		  "\n";
    }
}

sub print_vcg_node {
    my $self = shift;
    my $n = shift;
    defined($n) or 
        confess *print_vcg_node{PACKAGE} . "::print_vcg_node no node number";
    my $fh = fh_or_stdout(shift);
    my ($level, $label, $title);

    $level = "";
    if ($n == 0) {
        $level = "level: 1";
	$label = 'label: "(START)"';
    } else {
        $label = 'label: "' . $n . " " . $self . '"'; # debugging
        #$label = 'label: "' . $n . '"'; # normal use
    }
    $title = 'title: "' . $n . '"';

    print $fh "node: { $title $label $level }\n";
}

# for debugging purposes
sub print {
    my $self = shift;
    my $fh = fh_or_stdout(shift, fileno(STDERR));

    print $fh "self $self visits ", $self->{"visits"}, "\n";
    print $fh "    Inbound ", $self->in_links, "\n";
    map { print $fh "        $_\n" } $self->in_tokens;

    print $fh "    Outbound\n";
    for my $token (keys %{$self->{"outbound"}}) {
        print $fh "        $token -> ", ${$self->{"outbound"}}{$token}, "\n";
    }
}

=head2 Methods related to adapting the FA, counters and their maintenance

L<DFA> adaptive learning (from the point of view of a IDS::DFAState) is keeping
track of nodes and edges as they are used, and then dropping the edges
which are not used enough to warrant keeping them.

The counters are also used by a L<HMM> for calculating probabilities.

=over

=item visited()

Increment the visited counter for the node.

=item visits()

Return the value of the visited counter.

=item followed(token)

Increment the counter for an edge associated with a token.  Note that
the edge must exist.

=item out_count(token)

Return the counter associated with the transition for the specified
token.

=item set_count(token, value)

Set the counter associated with the transition for the specified
token to the given value.

=item reset_counters()

Reset the node and edge counters to 0.

=item probability(token)

Return the probability of taking the edge assocaited with the specified
token.  The probability is calculated as
out_count(token) / sum of out_count(all tokens)

=item drop_edges(threshold)

Drop all edges with a use count below the threshold.

=item drop_edge(token)

Internal use only.  Drop the edge associated with the specified token.

=item dropped_edge(fromref)

Internal use only.  An edge to us from the state referenced by fromref
was dropped.  Update the inbound array to remove the given node that used
to come to us.

=item drop_all_edges()

This node is about to be dropped; drop all of our edges.  This function
does not work if loops exist in the automaton.  A solution is to let the
edges drop off from non-use and then use a function that has yet to be
written to drop nodes with no in or out edges.

=item drop_link_to(state)

The state is about to be dropped.  Remove all links to it.

=back

Note that the dropping of an edge will not cause a node to be deleted.
Only the pruning will so that.  This means that we will keep dead-end
and unreachable nodes until the pruning drops them from lack of use.
The various drop functions should only ensure the consistency of both
sides of the link they are operating on.

=cut

sub visited {
    my $self = shift;
    $self->{"visits"}++;
}

sub visits {
    my $self = shift;
    return $self->{"visits"};
}

sub followed {
    my $self = shift;
    my $t = shift;
    defined($t) or 
        confess *followed{PACKAGE} . "::followed Missing token";

    if (exists(${$self->{"outbound"}}{$t})) {
	${$self->{"out_count"}}{$t}++;
    } else {
        carp "Trying to update a counter for the nonexistent token '$t'\n";
    }
}

# This is a test func, and has no bearing on reality
sub autogen_nums {
    my $self = shift;

    my ($min, $max, $outdegree, $count, %counts, $t, $tnv, %novalues);

    $outdegree = scalar(keys %{$self->{"outbound"}});
    $min = $outdegree;
    $max = 0;
    %novalues = ();
    for $t (keys %{$self->{"outbound"}}) {
	$count = $self->out_count($t);
	$min = $count if $count < $min;
	$max = $count if $count > $max;
	$counts{$t} = $count;
	$tnv = $t;
	$tnv =~ s/:.*//;
	$novalues{$tnv}++;
    }
    return ($min, $max, $outdegree, $max != 0 ? $outdegree / $max : undef, \%novalues);
}

sub set_count {
    my $self = shift;
    my $t = shift;
    defined($t) or 
        confess *out_count{PACKAGE} . "::out_count Missing token";
    my $v = shift;
    defined($t) or 
        confess *out_count{PACKAGE} . "::out_count Missing count value";

    ${$self->{"out_count"}}{$t} = $v;
}

sub out_count {
    my $self = shift;
    my $t = shift;
    defined($t) or 
        confess *out_count{PACKAGE} . "::out_count Missing token";

    return ${$self->{"out_count"}}{$t};
}

sub reset_counters {
    my $self = shift;

    $self->{"visits"} = 0;
    map {${$self->{"out_count"}}{$_} = 0} keys %{$self->{"out_count"}};
}

sub probability {
    my $self = shift;
    my $token = shift;

    my ($sum);

    exists(${$self->{"out_count"}}{$token}) or return undef;

    $sum = 0;
    map { $sum += ${$self->{"out_count"}}{$_}; } keys %{$self->{"out_count"}};

    return ${$self->{"out_count"}}{$token} / $sum;
}

sub drop_edges {
    my $self = shift;
    my $thresh = shift;
    defined($thresh) or 
        confess *drop_edges{PACKAGE} . "::drop_edges Missing threshold";
    my ($t, $v, $n);
    
    # each can handle deletions of the element with key $t as it iterates
    $n = 0;
    while (($t, $v) = each(%{$self->{"out_count"}})) {
        if ($v < $thresh) {
	    $self->drop_edge($t) if $v < $thresh;
	    $n++;
	}
    }
    return $n;
}

sub drop_edge {
    my $self = shift;
    my $token = shift;
    defined($token) or 
        confess *drop_edge{PACKAGE} . "::drop_edge Missing token";

    exists(${$self->{"outbound"}}{$token}) or
        confess *drop_edge{PACKAGE} . "::drop_edge no outbound edge for $token";

    my $other = ${$self->{"outbound"}}{$token};
    $other->dropped_edge($self, $token);
    delete ${$self->{"outbound"}}{$token};
    delete ${$self->{"out_count"}}{$token};
}

sub dropped_edge {
    my $self = shift;
    my $from = shift;
    defined($from) or 
        confess *dropped_edge{PACKAGE} . "::dropped_edge Missing 'from'";
    $from->isa("IDS::DFAState") or
        confess *dropped_edge{PACKAGE} . "::dropped_edge 'from' is wrong type";
    my $token = shift;
    defined($token) or 
        confess *dropped_edge{PACKAGE} . "::dropped_edge Missing 'token'";

    my $inbound = $self->{"inbound"};
    unless (exists(${$inbound}{$from})) {
	cluck *dropped_edge{PACKAGE} . "::dropped_edge no inbound transition from $from to $self";
	$from->browse("from: $from");
	$self->browse("to: $self");
	exit(1);
    }
    my $intokens = ${$inbound}{$from};
    unless (exists(${$intokens}{$token})) {
	cluck *dropped_edge{PACKAGE} . "::dropped_edge no inbound transition from $from to $self on $token!";
	$from->browse("from: $from");
	$self->browse("to: $self");
	exit(1);
    }

    # delete the entry in the list of tokens
    delete(${$intokens}{$token});

    # if there are no tokens left coming from this state, delete the
    # entry for this state
    if (scalar(keys(%{$intokens})) == 0) {
       delete(${$inbound}{$from});
    }
}

sub drop_all_edges {
    my $self = shift;
    my ($t, $v, $s);

    while (($t, $v) = each(%{$self->{"outbound"}})) {
        $self->drop_edge($t);
    }
    
    for $s (keys %{$self->{"inbound"}}) {
	for $t (keys %{${$self->{"inbound"}}{$s}}) {
	    $s->drop_link_to($self, $t);
	}
	delete(${$self->{"inbound"}}{$s});
    }
}

sub drop_link_to {
    my $self = shift;
    my $to = shift;
    defined($to) or
        confess *drop_link_to{PACKAGE} . "::drop_link_to Missing 'to'";
    $to->isa("IDS::DFAState") or
        confess *drop_link_to{PACKAGE} . "::drop_link_to 'to' is wrong type";
    my $token = shift;
    defined($token) or
        confess *drop_link_to{PACKAGE} . "::drop_link_to Missing 'token'";

    confess "No link from $self on token $token\n"
        unless exists(${$self->{"outbound"}}{$token});
    confess "No link from $self to $to on token $token\n"
        unless ${$self->{"outbound"}}{$token} eq $to;

    delete ${$self->{"outbound"}}{$token};
    delete ${$self->{"out_count"}}{$token};
}

=head2 Methods for information about this state

=over

=item in_states()

Return a list or reference to an array (depending on if we are called
in scalar or list context) which is a list of inbound states.

=item in_links()

Return the number of inbound links we have.

=item out_tokens()

Return a list of tokens that cause a transition out of this state.

=item out_states()

Return a list of states to which this state has transitions.

=item out_links()

Return the number of outbound edges.

=back

=cut

sub in_states {
    my $self = shift;
    my @states = ();

    if (wantarray) {
	return keys %{$self->{"inbound"}};
    } else {
	@states = keys %{$self->{"inbound"}};
	return \@states;
    }
}

sub in_links {
    my $self = shift;
    return scalar(keys %{$self->{"inbound"}});
}

sub out_tokens {
    my $self = shift;
    return keys %{$self->{"outbound"}};
}

sub out_states {
    my $self = shift;
    return values %{$self->{"outbound"}};
}

sub out_links {
    my $self = shift;

    return scalar(keys %{$self->{"outbound"}});
}

=over

=item in_tokens()

Return a list of tokens that cause a transition into this state.

=back

=cut

sub in_tokens {
    my $self = shift;

    # tokens for a given state $s are
    # keys(%{${$self->{"inbound"}}{$s}})
#    return $self->uniq(map {keys(%{${$self->{"inbound"}}{$_}})} keys(%{$self->{"inbound"}}));
    my @instates = keys(%{$self->{"inbound"}});
    my @intokens = map {$_->token_to($self)} @instates;
    return @intokens;
}

=over

=item token_to(state)

Return the token that causes a transition to the specified state.

=item token_from(state)

Return the token that causes a transition from the specified state, or
undef if the state claims to have no transition to us.

=back

=cut

sub token_to {
    my $self = shift;
    my $state = shift;
    defined($state) or
        confess *token_to{PACKAGE} . "::token_to Missing 'state'";
    $state->isa("IDS::DFAState") or
        confess *token_to{PACKAGE} . "::token_to 'state' is wrong type";

    for my $token (keys %{$self->{"outbound"}}) {
        return $token if ${$self->{"outbound"}}{$token} eq $state;
    }
    cluck "IDS::DFAState::token_to returning undef for $state!";
    return undef;
}

sub tokens_from {
    my $self = shift;
    my $state = shift;
    defined($state) or
        confess *token_to{PACKAGE} . "::token_to Missing 'state'";
    $state->isa("IDS::DFAState") or
        confess *token_to{PACKAGE} . "::token_to 'state' is wrong type";

    return keys(%{${$self->{"inbound"}}{$state}});
}

=over

=item next(token)

Given a token, return the next state.  

=back

=cut

sub next {
    my $self = shift;
    my $token = shift;
    defined($token) or 
        confess *next{PACKAGE} . "::next called without a token";

    cluck "IDS::DFAState::next returning undef for '$token'" unless
	(exists(${$self->{"outbound"}}{$token}) &&
	 defined(${$self->{"outbound"}}{$token})) ||
	$self->{"verbose"} < 3;
    return ${$self->{"outbound"}}{$token};
}

=over

=item exists_inbound_from(from)

Verify that ``from'' is in the list of inbound states.

=back

=cut

sub exists_inbound_from {
    my $self = shift;
    my $from = shift or
        confess *exists_inbound_from{PACKAGE} . "::exists_inbound_from Missing 'from'";
    $from->isa("IDS::DFAState") or
        confess *exists_inbound_from{PACKAGE} . "::exists_inbound_from 'from' is wrong type";

    return exists(${$self->{"inbound"}}{$from});
}

=over

=item compare(otherstate)

Compare the current state with another state.  The return value is 0 if
they are identical, 1 otherwise.  This return value may seem odd, but it
was inspired by the perl cmp and <=> operators.  However, the concept of
greater than and less than is not well defined.  

Two states are considered identical iff:

=over

=item *
They have the same number of outbound states.

=item *
Every token for one state has a transition in the other state with the
same destination.

=back

=back

Note that the inbound states may be different for the compared states
and they will still test as identical.  This is on purpose to allow the
merging to occur.

=cut

sub compare {
    my $self = shift;
    my $other = shift or
        confess *compare{PACKAGE} . "::compare Missing 'other'";
    $other->isa("IDS::DFAState") or
        confess *compare{PACKAGE} . "::compare 'other' is wrong type";

    if ($self eq $other) {
	carp "IDS::DFAState: comparison with self";
	return 0;
    }

    my $n = keys %{$self->{"outbound"}};
    if (keys(%{$other->{"outbound"}}) != $n) {
	return 1;
    }

    # At this point, we know that the number of keys is the same.
    # Therefore, we just check to see if they are all go to the same
    # place.  We do this by counting the number that do not match, in a
    # backwards sort of way.
    map { exists(${$other->{"outbound"}}{$_}) and
          ${$other->{"outbound"}}{$_} eq ${$self->{"outbound"}}{$_} and
	  $n--; 
	} keys %{$self->{"outbound"}};

    return $n;
}


# Tk methods for browsing; only the top-level call is public

sub browse {
    my $self = shift;
    my $label = shift || "(START)";

    my $main = MainWindow->new;

    $self->tk_children($main, $self, $label);
    MainLoop;
}

sub tk_children {
    my $self = shift;
    my $window = shift;
    defined($window) or
        confess *tk_children{PACKAGE} . "::tk_children window undefined.";
    my $state = shift;
    defined($state) or
        confess *tk_children{PACKAGE} . "::tk_children state undefined";
    my $label = shift;
    defined($label) or
        confess *tk_children{PACKAGE} . "::tk_children label undefined";

    my ($nodeinfo, $tocanvas, $fromcanvas);

    # remove all items currently in the window; we want a clean window
    map { $_->destroy } $window->children;

    $fromcanvas = $self->tk_fromlist($window, $state);
    $fromcanvas->grid(-column => 0, -row => 0);

    $nodeinfo  = $state->in_links . " inbound states\n";
    $nodeinfo .= "$label\n(" . scalar($state) . "); node count " .
                 $state->visits . "\n";
    $nodeinfo .= $state->out_links . " outbound states";
    $window->Label(-text => $nodeinfo)->grid(-column => 0, -row => 1);

    $tocanvas = $self->tk_tolist($window, $state);
    $tocanvas->grid(-column => 0, -row => 2);

    $window->Button(
                  -text => "Done.",
		  -command => sub {$window->destroy}
		   )->grid(-column => 0, -row => 3);
}

sub tk_fromlist {
    my $self = shift;
    my $window = shift;
    defined($window) or
        confess *tk_children{PACKAGE} . "::tk_children window undefined.";
    my $state = shift;
    defined($state) or
        confess *tk_children{PACKAGE} . "::tk_children state undefined";

    my ($x, $y, $token, $button, $s, $canvas, $n, $coderef);

    $canvas = $self->tk_setup_bcanvas($window);

    $y = 0.1 * $canvas->reqheight;
    $x = 0.1 * $canvas->reqwidth;
    $n = 1;
    for $s ($state->in_states) {
	$token = $s->token_to($state) || "UNDEF!";
	$coderef = sub { $self->tk_children($window, $s, $token) };
	$y = $self->tk_addbutton($canvas, $n++ . ". $s $token", $coderef,
	                         $x, $y);
    }
    $canvas->configure(-scrollregion => ['0c', '-10p', '0c', ($n * 19) . "p"]);

    return $canvas;
}

sub tk_tolist {
    my $self = shift;
    my $window = shift;
    defined($window) or
        confess *tk_children{PACKAGE} . "::tk_children window undefined.";
    my $state = shift;
    defined($state) or
        confess *tk_children{PACKAGE} . "::tk_children state undefined";

    my ($canvas, $token, $button, $s, $x, $y, $next, $n, $label, $coderef);

    $canvas = $self->tk_setup_bcanvas($window);

    $y = 0.1 * $canvas->reqheight;
    $x = 0.1 * $canvas->reqwidth;

    $n = 1;
    for $token ($state->out_tokens) {
	$next = $state->next($token);
	$label = $n++ . ". $next; $token; " . $state->out_count($token);
	$coderef = sub { $self->tk_children($window, $next, $token) };
	$y = $self->tk_addbutton($canvas, $label, $coderef, $x, $y);
    }
    $canvas->configure(-scrollregion => ['0c', '-10p', '0c', ($n * 19) . "p"]);
    return $canvas;
}

sub tk_setup_bcanvas {
    my $self = shift;
    my $window = shift;
    defined($window) or
        confess *tk_children{PACKAGE} . "::tk_children window undefined.";

    my $canvas;

    $canvas = $window->Scrolled("Canvas",
				     -scrollbars => "osow",
                                     -width => 600,
				     -height => 300,
#                                     -scrollregion => ['0c', '-10p', '0c', '1000p']
				    );
    $canvas->CanvasBind('<2>' => [ scanMark => Ev('x'), Ev('y') ]);
    $canvas->CanvasBind('<B2-Motion>' => [ scanDragto => Ev('x'), Ev('y') ]);

    return $canvas;
}

sub tk_addbutton {
    my $self = shift;
    my $window = shift;
    defined($window) or
        confess *tk_children{PACKAGE} . "::tk_children window undefined.";
    my $buttontext = shift;
    defined($buttontext) or
        confess *tk_children{PACKAGE} . "::tk_children buttontext undefined.";
    my $coderef = shift;
    defined($coderef) or
        confess *tk_children{PACKAGE} . "::tk_children coderef undefined.";
    my $x = shift;
    defined($x) or
        confess *tk_children{PACKAGE} . "::tk_children x undefined.";
    my $y = shift;
    defined($y) or
        confess *tk_children{PACKAGE} . "::tk_children y undefined.";

    my ($button);

    $button = $window->Button(
			      -text => $buttontext,
			      -command => $coderef,
			     );
    $window->createWindow($x, $y,
			  -width=>$button->reqwidth,
			  -anchor => "nw",
			  -window => $button
			 );
    return $y + $button->reqheight;
}

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the response depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Algorithm>, L<DFA>, L<HMM>

VCG - Visualization of Compiler Graphs, Design Report and User
Documentation,  Ref. Compare, USAAR-1049-visual, January 1994, updated
January 1995

=cut


1;
