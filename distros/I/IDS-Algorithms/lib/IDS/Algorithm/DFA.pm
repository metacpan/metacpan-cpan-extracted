=head1 DFA

=head2 Introduction

A DFA is a collection of L<IDS::Algorithm::DFAState>s.    A DFA consists of the following:

=over

=item states

A reference to a list of states.  Functions that return information about
this variable: print, printvcg.  Functions that indirectly return
information about this variable: test_instance, stats, verify.
Functions that manipulate this variable: load, add_transition,
collapse_states.

=item tokens

A reference to a hash.  The index of the hash is the token, the value is
the state that that token will cause a transition into.

Functions that manipulate this variable: rebuild_tokens, add_transition.
Used by: verify, test_instance.

=item verbose

The verbosity level; the higher the value, the more messages are
produced.

TODO: define the verbosity levels.

=item start

A reference to the start state.

=item accept

A reference to the accept state.

=back

states[0] is the start state.
states[1] is the accept state.
However, relying on this is a bad idea; use the references to these
states.

=head2 Methods

=cut

package IDS::Algorithm::DFA;
use base qw(IDS::Algorithm);

use strict;
use warnings;
use IO::Handle;
use IDS::Algorithm::DFAState;
use Carp qw(cluck carp confess);

$IDS::Algorithm::DFA::VERSION = "3.1";

=over

=item new()

=item new(filehandle)

Create a new DFA with two states, the start and accept states.  If the
filehandle is supplied, load the DFA (in the format used by print()).

=back

=cut

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = {
	states => [], # a set of states
	tokens => {}, # token to a list of states that the token will
		      # cause a transition into
		      ### need to see if the list is ever larger than 1
    };
    bless($self, $class);
    $self->default_parameters;
    my $source = $self->handle_parameters(@_);
    $self->load($source) if defined($source);

    $self->{"states"}[0] = IDS::Algorithm::DFAState->new($self->{"params"}{"verbose"}); # Start state
    $self->{"start"} = $self->{"states"}[0];
    $self->{"states"}[1] = IDS::Algorithm::DFAState->new($self->{"params"}{"verbose"}); # Accept state
    $self->{"accept"} = $self->{"states"}[1];
    ${$self->{"tokens"}}{'(ACCEPT)'} = $self->{"accept"};

    return $self;
}

=over

=item load(filehandle)

Load a DFA from a file; this is the inverse of "print", and the format
we expect is that used in $self->print.

=back

=cut

sub load {
    my $self = shift;
    my $fname = shift;
    defined($fname) && $fname or
        $fname = ${$self->{"params"}}{"state_file"};
    defined($fname) && $fname or
	confess *load{PACKAGE} .  "::load missing filename";
    my ($cnt, $from, $to, $token, $l, $fh);
    my $verbose = ${$self->{"params"}}{"verbose"};

    $fh = new IO::File "<$fname" or
        confess *load{PACKAGE} . "::load Unable to open $fname for reading: $!";
    
    $l = 0;
    while (<$fh>) {
	chomp;
	$l++;
        ($from, $to, $cnt) = /^State (\d+) To (\d+) count (\d+) Token:$/;
	defined($from) or confess *load{PACKAGE} . "::load missing 'from' on line $l";
	defined($to) or confess *load{PACKAGE} . "::load missing 'to' on line $l";
	defined($cnt) or confess *load{PACKAGE} . "::load missing 'cnt' on line $l";
	$token = <$fh>;
	defined($token) or confess *load{PACKAGE} . "::load missing 'token' on line $l";
	$token =~ s/^    //;
	chomp $token;
	defined($self->{"states"}[$from]) or
	    $self->{"states"}[$from] = IDS::Algorithm::DFAState->new($verbose);
	defined($self->{"states"}[$to]) or
	    $self->{"states"}[$to] = IDS::Algorithm::DFAState->new($verbose);
	$self->{"states"}[$from]->add_outbound($token, $self->{"states"}[$to]);
	$self->{"states"}[$to]->add_inbound($self->{"states"}[$from], $token);
	$self->{"states"}[$from]->set_count($token, $cnt);
	${$self->{"tokens"}}{$token} = $self->{"states"}[$to];
    }
    $self->verify if $verbose; # paranoia
}

=over

=item stats()

Return general statistics about the DFA.

=back

=cut

sub stats {
    my $self = shift;
    my ($t, $v);

    my $states = $#{$self->{"states"}} + 1;
    my $tokens = scalar keys %{$self->{"tokens"}};

    my $edges = 0;
    for my $s (@{$self->{"states"}}) {
        $edges += scalar $s->out_tokens();
    }

    return  "$states " . $self->plural("state", $states) .
            " $tokens " . $self->plural("token", $tokens) .
            " $edges " . $self->plural("edge", $edges);
}

=over

=item prune(threshold)
=item prune(node_threshold, edge_threshold)

Delete nodes and edges used fewer than threshold times.  If only one
threshold is provided, it is used for both.

=back

=cut

sub prune {
    my $self = shift;
    my $node_thresh = shift;
    defined($node_thresh) or
        confess *prune{PACKAGE} . "::prune missing 'threshold'";
    my $edge_thresh = shift;
    defined($edge_thresh) or $edge_thresh = $node_thresh; # default
    my ($state, $deleted, $d, $verbose, $i);
    
    $verbose = ${$self->{"params"}}{"verbose"};

    ### node and edge pruning should be able to be combined into one
    ### loop.  They are separate to make consistency checking easier
    ### (for tracking down bugs in the pruning process).

    print STDERR "About to prune\n" if $verbose;
    ### TEST: is this clobbering the node map later?
    #$deleted = $self->node_prune($node_thresh);
    #print STDERR "node pruning deleted $deleted.\n" if $verbose;
    $self->verify || warn "Verify failed ($deleted)\n"; ### will not want this in production; too slow

    $d = $self->edge_prune($edge_thresh);
    $deleted += $d;
    print STDERR "edge pruning deleted $d.\n" if $verbose;
    $self->verify || warn "Verify failed ($deleted)\n"; ### will not want this in production; too slow

### TEST: is this clobbering the node map later?
#    while (($d = $self->deadend_prune) > 0) {
#        $deleted += $d;
#	print STDERR "deadend pruning deleted $d.\n" if $verbose;
#    }
#    $self->verify || warn "Verify failed ($deleted)\n"; ### will not want this in production; too slow

    print STDERR $self->stats, "\n" if $verbose;
    #$self->rebuild_tokens if $deleted;
    #print STDERR "About to start final consistency check.\n" if $verbose;
    #$self->verify || warn "Final verify failed ($deleted)\n"; ### will not want this in production; too slow

    return $deleted;
}

sub deadend_prune {
    my $self = shift;
    my ($state, $deleted, %seen, @tovisit, $s, $d);

    # find the reachable nodes.
    %seen = (); $seen{$self->{"start"}} = 1;
    @tovisit = $self->{"start"}->out_states;
    while ($#tovisit >= 0) {
	$s = pop @tovisit;
	$seen{$s} = 1;
	for $d ($s->out_states) {
	    $seen{$d} or push @tovisit, $d;
	}
    }

    # Drop all states that became unreachable.  
    $deleted = 0;
    for (my $i=0; $i <= $#{$self->{"states"}}; $i++) {
	my $state = ${$self->{"states"}}[$i];

	# never prune the start and accept states
	next if $state eq $self->{"start"}  || $state eq $self->{"accept"};

	# below gets dead ends; should we keep them?
	#if ($state->out_links == 0 || $state->in_links == 0) {

	# This gets rid of completely unreachable states.
        unless (exists($seen{$state})) {
	    $state->drop_all_edges;
	    splice @{$self->{"states"}}, $i, 1;
	    $deleted++;
	}
    }
    return $deleted;
}

sub edge_prune {
    my $self = shift;
    my $edge_thresh = shift;
    defined($edge_thresh) or
        confess *edge_prune{PACKAGE} . "::edge_prune missing 'threshold'";
    my ($state, $verbose);

    $verbose = ${$self->{"params"}}{"verbose"};

    for $state (@{$self->{"states"}}) {
	# never prune the start and accept states
	next if $state eq $self->{"start"}  || $state eq $self->{"accept"};

	my $dropped = $state->drop_edges($edge_thresh);
	print STDERR "Dropped $dropped edges from state $state\n"
	    if $verbose;
    }
    return $self->delete_empty;
}

sub node_prune {
    my $self = shift;
    my $node_thresh = shift;
    defined($node_thresh) or
        confess *node_prune{PACKAGE} . "::node_prune missing 'threshold'";
    my ($state, $deleted, $verbose);

    $verbose = ${$self->{"params"}}{"verbose"};
    $deleted = 0;
    for $state (@{$self->{"states"}}) {
	# never prune the start and accept states
	next if $state eq $self->{"start"}  || $state eq $self->{"accept"};

	if ($state->visits < $node_thresh) {
	    print STDERR "Dropping $state; visits ", $state->visits, 
	                 " thresh $node_thresh\n" if $verbose;
	    #$state->print if $verbose;
	    #$state->browse("About to drop");
	    $state->drop_all_edges;
	    $deleted++;
	}
    }
    $deleted += $self->delete_empty;

    return $deleted;
}

# delete all of the empty states.
sub delete_empty {
    my $self = shift;
    my ($i, $state, $deleted);

    $deleted = 0;
    for ($i=0; $i <= $#{$self->{"states"}}; $i++) {
	$state = ${$self->{"states"}}[$i];
	if ($state->out_links == 0 && $state->in_links == 0) {
	    splice @{$self->{"states"}}, $i, 1;
	    $deleted++;
	    $i--; # to account for the deleted entry.
	}
    }
    return $deleted;
}

=over

=item rebuild_tokens()

We deleted one or more states.  Rebuild our list of what tokens go
where.

=back

=cut 

### This whole function is a kludge; find a way of keeping things
### straight.
sub rebuild_tokens {
    my $self = shift;
    my ($k, $v, $t, $state);
    
    %{$self->{"tokens"}} = ();
    # rebuild the list of tokens
    for $state (@{$self->{"states"}}) {
        for $t ($state->in_tokens()) {
	    defined($t) or confess "t state undefined\n";
	    if (exists(${$self->{"tokens"}}{$t})) {
	        my $clobbered = ${$self->{"tokens"}}{$t};
	        carp "clobbering an existing token ($clobbered) with $t";
	    }
	    ${$self->{"tokens"}}{$t} = $state;
	}
    }
}

=over

=item reset_counters()

Reset all of the counters associated with node and edge use.

=back

=cut

sub reset_counters {
    my $self = shift;

    for my $state (@{$self->{"states"}}) {
	$state->reset_counters;
    }
}

=over

=item add(token_listref)

The collection of tokens (in the list referenced by token_listref)
is a complete example of a list that should be accepted by the DFA.  

WE add the transition from the last token to the '(ACCEPT)' state.

=back

=head3 How learning occurs:

=begin latex

The learning algorithm is based on one by Burge \cite{Burge2003DFA}.
We chose this algorithm because it is straightforward to implement,
and it works well in our situation.  The learning algorithm proceeds
as follows:
\begin{enumerate}
\item A parser breaks a HTTP request into a list of tokens; the
last token is the ``ACCEPT'' token.
\item The current state ($C$) is set to the ``START'' state.
\item For each token $T_i$ in the list of tokens, do
\begin{enumerate}
\item If a transition using $T_i$ exists from $C$ to some other state
$D$, set $C$ to $D$.
\item If no such transition exists, look for a node ($D$) which has
been the destination for the same token, but from some other node.
If $D$ exists, (it will be unique), add a transition from $C$ to $D$.
Set $C$ to $D$.  A picture of this step is in
Figure~\ref{add_transition}.
\item If no node $D$ exists, create a new node ($E$) and create a
transition from $C$ to $E$.  Set $C$ to $E$.  A picture of this step is
in Figure~\ref{add_node}.
\end{enumerate}
\end{enumerate}

\begin{figure*}
\input{DFA-learning-a.tex}
\caption{As the learner is traversing the DFA, it sometimes must add a
transition or new node.  In (a), the current state is $C$ and the
next token ($T_i$) is the same token that caused the transition from $B$
to $D$.  The learner will change the DFA to that in (b) by adding add
the
transition from $C$ to $D$.}
\label{add_transition}
\end{figure*}
\begin{figure*}
\input{DFA-learning-b.tex}
\caption{As the learner is traversing the DFA, it sometimes must add a
transition or new node.  In (a), the current state is $C$ and no
existing transition for the token $T_i$ exists.  Therefore, the
learner will change the DFA to that in (b) by adding both the node $E$
and the transition from $C$ to $E$.}
\label{add_node}
\end{figure*}

=end latex

=cut

sub add {
    my $self = shift;
    my $data = shift or 
        confess *add{PACKAGE} . "::add missing data to add";
    my ($current_state, $t);
    my $verbose = ${$self->{"params"}}{"verbose"};

    $current_state = $self->{"start"};
    print "Start $current_state\n" if $verbose;
    $current_state->visited;
    foreach $t (@{$data}) {
	defined($t) or cluck("undefined token in add.  List: '" .
	                     join("' '", @{$data}) . "'");
	print "Adding a transition from $current_state for $t\n" if $verbose;
	$current_state = $self->add_transition($current_state, $t);
	$current_state->visited;
	print "    New state $current_state\n" if $verbose;
    }
    print "Adding a transition from $current_state for (ACCEPT)\n" if $verbose;
    $current_state = $self->add_transition($current_state, "(ACCEPT)");
}

=over

=item add_transition(from, token)

Add a transition from one state to another when the specified token is
received.  It is not an error to try to add an existing transition.
In that event, this function quietly returns.  If no such transition
exists, we look for a transition on the token; if so, we add an edge to
the destination node for the existing edge.  Finally, if there is no
other choice, we create a new state and add the edge.

=back

=cut

sub add_transition {
    my $self = shift;
    my $from = shift;
    defined($from) or
        confess *add_transition{PACKAGE} . "::add_transition missing 'from'";
    $from->isa("IDS::Algorithm::DFAState") or
        confess *add_transition{PACKAGE} . "::add_transition 'from' is wrong type";
    my $token = shift; # the token causing the transition
    defined($token) or
        confess *add_transition{PACKAGE} . "::add_transition missing 'token'";
    my $verbose = ${$self->{"params"}}{"verbose"};
    my ($next, $end, $s, $next_state, $n);

    # special handling for accept state
    ### Commented out because if everything is properly set up (in new())
    ### this part should not be necessary.
#    if ($token eq "(ACCEPT)") {
#        $end = $self->{"accept"};
#	defined($end) or
#	    confess *add_transition{PACKAGE} . "::add_transition missing accept state in DFA";
#	$next = $from->next($token);
#	return if defined($next) && $end eq $next;
#	$from->add_outbound($token, $end);
#	return $end;
#    }

    # First, see if a transition on this token already exists;  if so,
    # we will assume (valid?) that it is what we want.
    $next = $from->next($token);
    print "    existing transition $next\n" if defined($next) && $verbose;
    if (defined($next)) {
	$from->followed($token);
	return $next;
    }

    print "    No existing transition\n" if $verbose;
    # OK, we know the transition does not exist.  Does a *single* 
    # state exist that this token has caused a transition to in
    # the past?  If so, we assume (valid?) that we want to follow it.
    # In this DFA, a token can cause only one transition.
    if (exists ${$self->{"tokens"}}{$token}) {
	$s = ${$self->{"tokens"}}{$token};
	$from->add_outbound($token, $s);
	$from->followed($token);
	print "    going to existing state $s\n" if $verbose;
        return $s;
    }

    print "    No existing state\n" if $verbose;
    # We have run out of re-use options.  Create a new state and
    # set up the transition into it.
    $next_state = IDS::Algorithm::DFAState->new($verbose);
    $from->add_outbound($token, $next_state);
    $from->followed($token);
    # done in add_outbound: $next_state->add_inbound($from, $token);
    ${$self->{"tokens"}}{$token} = $next_state;
    push @{$self->{"states"}}, $next_state;
    $n = $#{$self->{"states"}};
    print "    State $n $next_state\n" if $verbose;
    return $next_state;
}

sub save {
    my $self = shift;
    my $dest = shift;
    my $destfh;

    if (defined($dest) && ! $dest->isa("IO::Handle")) {
        $destfh = IO::File->new("> $dest");
	defined($destfh) or confess "Cannot open $dest: $!";
    } else {
        $destfh = $dest;
    }

    return $self->print($destfh);
}

=over

=item print

=item print(filehandle)

Print in a form both usable by humans as well as for reading back in
with the load subroutine.  If the filehandle is specified, print there;
otherwise, print to STDOUT.

=back

=cut

sub print {
    my $self = shift;
    my $fh = $self->get_fh(shift);
    my ($i, $s, $node_map);

    print $#{$self->{"states"}} + 1, " nodes\n";

    $i = 0;
    for $s (@{$self->{"states"}}) {
	$node_map->{$s} = $i++;
    }

    for $s (@{$self->{"states"}}) {
        $s->print_edges($node_map, $fh);
    }
}

=over

=item printvcg

=item printvcg(filehandle)

Print in a form usable by VCG for printing the DFA.

If the filehandle is specified, print there; otherwise, print to STDOUT.

=back

=cut

sub printvcg {
    my $self = shift;
    my $fh = $self->get_fh(shift);
    my ($i, $node_map, $s);

    print $fh "graph: { layoutalgorithm: minbackward\n" . 
              "         manhattan_edges: yes\n" .
              "         splines: yes\n" .
              "         display_edge_labels: yes\n" .
              "         port_sharing: no\n" .
              '         title: "HTTP DFA"' . "\n\n";

    # The nodes
    $i = 0;
    for $s (@{$self->{"states"}}) {
        $s->print_vcg_node($i, $fh);
	$node_map->{$s} = $i;
	$i++;
    }
    print $fh "\n";

    # The transitions
    # This loop cannot be combined with the one above because nodes have
    # to be defined for vcg before they are referenced.
    for $s (@{$self->{"states"}}) {
        $s->print_vcg_edges($node_map, $fh);
    }
    print $fh "}\n";
}

=over

=item clean(type)

Clean the DFA.

Clean by collapsing states.  We will do this until we get no changes in
the size of the DFA.  This cleaning is appropriate for any time.

If type eq "test", we collapse, then prune.  Pruning only makes sense 
if training has already occurred and we are testing.

If type eq "train" or is undefined, we only collapse states.

=back

=cut

sub clean {
    my $self = shift;
    my $type = shift;

    # Collapse
    my $i = 0;
    while ($self->collapse_states()) { $i++ };

    if (defined($type) && $type eq "test" &&
        ${$self->{"params"}}{"prune_threshold"} > 0) {
            $self->prune(${$self->{"params"}}{"prune_threshold"});
    }
}

=over

=item generalize()

Generalization is simply cleaning as if we were training.  This function
exists to fit the IDS::Test framework.

=back

=cut

sub generalize {
    my $self = shift;

    $self->clean(undef);
}

=over

=item collapse_states()

Look for identical transitions and collapse them into one state.

TODO: More description here

=back

=cut

sub collapse_states {
    my $self = shift;
    my $start = $#{$self->{"states"}}; # for stats on how many we collapsed
    my $verbose = ${$self->{"params"}}{"verbose"};

    # loop through nodes, looking for duplicates.  n^2 algorithm, sigh
    ### change to alg where sort by source and dest nodes before
    ### comparing; then O(n log n)
    for (my $i=0; $i<$#{$self->{"states"}}; $i++) {
        for (my $j=$i+1; $j<=$#{$self->{"states"}}; $j++) {
	    my ($si, $sj); # prettier code
	    $si = ${$self->{"states"}}[$i];
	    $sj = ${$self->{"states"}}[$j];
	    my $nstates = $#{$self->{"states"}};

	    ### Kludge; should not need this, but something is apparently creating undefined entries in states
	    unless (defined($sj)) {
		cluck "sj undefined: i $i j $j nstates $nstates";
		#warn "Starting verify pass with verbose on\n";
		#${$self->{"params"}}{"verbose"} = 1;
		#$self->verify;
		#warn "verify pass done\n";

		splice(@{$self->{"states"}}, $j, 1);
		last if $j > $#{$self->{"states"}};
		$sj = ${$self->{"states"}}[$j];
	    }
	    confess "si or sj undefined. nstates $nstates i $i j $j si '$si' sj '$sj'\n" unless defined($si) && defined($sj);

	    if ($si->compare($sj) == 0) {
		print STDERR "States $i ($si) and $j ($sj) are the same.\n"
		    if $verbose > 0;
		# Change the state that a token causes a change into for
		# the about-to-be-deleted state.  A lot happens in these
		# next three lines.
		for my $token ($sj->in_tokens()) {
		    ${$self->{"tokens"}}{$token} = $si;
		}
		# the rest of the deletion is straightforward
		$si->absorb($sj);
		splice(@{$self->{"states"}}, $j, 1);
		# readjust $j to account for the deletion
		$j--;
	    }
	}
    }
    my $end = $#{$self->{"states"}};
    return $start - $end;
}

=over

=item test(tokensref)

Test a list of tokens against the DFA by attempting to traverse the DFA
from the start to the (single) accept node.  If no transition exists
for a token, this event is counted.  The verifier then attempts to
resynchronize by looking at the next token in the stream.  If the
edge corresponding to this token exists in the DFA, then the verifier
will traverse this edge (even though it was not in a state with this
outbound edge).  If no such edge exists, another miss has occurred,
and the verifier tries again with the next token.  The similarity
value returned is:

=begin latex
\[
\frac{\mbox{\rm \# of tokens where a transition is taken}}{\mbox{\rm \#
of tokens in the HTTP request}}
\in [0,1]
\]

=end latex

Note: WE put in the '(ACCEPT)' token at the end of the list we are
passed.

Q: do we want to update the counters only if the test indicates
normality?  If so, it looks like we're commiting to two runs, one to
determine normality and the second to update the counters.  For now,
we will update on the fly, but will hold this idea in reserve.

=back

=cut

sub test {
    my $self = shift;
    my $tokensref = shift or # list of tokens making up the data to test
        confess *test_instance{PACKAGE} . "::test_instance missing tokenref";

    my ($t, $misfires, $ntokens);
    my $verbose = ${$self->{"params"}}{"verbose"};

    my $current_state = $self->{"start"};
    defined($current_state) or 
        confess *test{PACKAGE} . "::test missing start state in DFA";

    $misfires = 0;
    foreach $t (@{$tokensref}, "(ACCEPT)") { # note included eof token
	if (defined($current_state)) {
	    $current_state->visited;
	    my $next = $current_state->next($t);
	    print STDERR "Looking for a transition for token '$t'\n"
	        if $verbose;
	    if (defined($next)) {
	        # if a transition exists, take it
		print STDERR "    Found existing state transition\n"
		    if $verbose;
		$current_state->followed($t);
		$current_state = $next;
	    } else {
	        # the transition does not exist; misfire + try to resync
		print STDERR "    Misfire\n" if $verbose;
		$misfires++;
		$current_state = defined(${$self->{"tokens"}}{$t})
		    ? ${$self->{"tokens"}}{$t}
		    : undef;
		print STDERR "Resync failed on token '$t'\n"
		    if !defined($current_state) && $verbose;
	    }
	} else { # we got lost earlier and are trying to resync
	    $misfires++;
	    $current_state = defined(${$self->{"tokens"}}{$t})
		? ${$self->{"tokens"}}{$t}
		: undef;
	    print STDERR "able to resync\n"
	        if $verbose && defined($current_state);
	}
    }

    # see if we are in the accept state.  If not, then count a misfire
    if (defined($current_state)) {
	unless ($self->{"accept"} eq $current_state) {
	    print STDERR "Misfire due to not ending in accept state\n" if $verbose;
	    $misfires++;
	}
    } else {
	print STDERR "Misfire due to undefined current state\n" if $verbose;
        $misfires++;
    }

    $ntokens = $#{$tokensref} + 2; # 2 because of indexing starting at
    				   # 0 and because of the end-of-input token
    print STDERR "misfires $misfires ntokens $ntokens\n" if $verbose;
    my $ret = 1 - ($misfires / $ntokens);
    return $ret > 0 ? $ret : 0; # return value cannot be less than 0,
				# but our calculation can be slightly
				# negative in some really bad cases.
}

=over

=item verbose(level)

Set the verbosity level.  Higher values imply more output.  Values over
2 are unlikely to be useful.

=back

=cut

sub verbose {
    my $self = shift;
    my $old = ${$self->{"params"}}{"verbose"};
    my $new = shift;
    ${$self->{"params"}}{"verbose"} = $new if defined($new);

    return $old;
}

=over

=item verify

Verify the consistency of the DFA; this function exists to aid in
debugging, when it may be that a bug is causing it to be corrupted.
Consider this a ``fsck'' for a DFA.

=back

=cut

sub verify {
    my $self = shift;
    my $OK = 1; # assume we are OK till proven otherwise
    my $warn = 0; # no warnings yet
    my ($i, $s, $t, $d, %seen, @tovisit, $missing);
    my $verbose = ${$self->{"params"}}{"verbose"};

    my $start = time if $verbose;
    print STDERR "Verifying; start at $start\n" if $verbose;

    # look for (and remove?) undefined states
    for ($i=0; $i < $#{$self->{"states"}}; $i++) {
        next if defined(${$self->{"states"}}[$i]);
	warn "State $i undefined.  Removing.\n";
	#splice @{$self->{"states"}}, $i, 1;
    }

    # verify that every node (except START) claims to have inbound links
    for $s (@{$self->{"states"}}) {
        next if $s eq $self->{"start"};
	if ($s->in_links == 0) {
	    warn "$s has no inbound states\n";
	    $warn = 1;
	}
    }
    print STDERR "Verify: inbound link check done; OK $OK; " . (time - $start) . "sec\n" if $verbose;

    # verify that every node (except ACCEPT) has outbound links
    for $s (@{$self->{"states"}}) {
        next if $s eq $self->{"accept"};
	if ($s->out_links == 0) {
	    warn "$s has no outbound states\n";
#	    $s->browse("dead-end; " . scalar($s));
	    $warn = 1;
	}
    }
    print STDERR "Verify: outbound link check done; OK $OK; " . (time - $start) . "sec\n" if $verbose;

    # verify that every transition is listed in the inbound list of the
    #    destination.
    for $s (@{$self->{"states"}}) {
        for $t ($s->out_tokens) {
	    $d = $s->next($t);
	    unless ($d->exists_inbound_from($s)) {
		warn "$d has no inbound from $s (on $t)\n";
		$s->browse("mixed-up; " . scalar($s));
		$OK = 0;
	    }
	}
    }
    print STDERR "Verify: out-in check done; OK $OK; " . (time - $start) . "sec\n" if $verbose;

    # verify that every node is reachable from the start node.
    %seen = (); $seen{$self->{"start"}} = 1;
    @tovisit = $self->{"start"}->out_states;
    while ($#tovisit >= 0) {
	$s = pop @tovisit;
	$seen{$s} = 1;
	for $d ($s->out_states) {
	    $seen{$d} or push @tovisit, $d;
	}
    }
    $missing = scalar(@{$self->{"states"}}) - scalar(keys %seen);
    if ($missing) {
	warn "Missing access to $missing states\n";
	$OK = 0;
    }
    print STDERR "Verify: reachability check done; warn $warn; OK $OK; " . (time - $start) . "sec\n" if $verbose;
    print STDERR "Verify: OK $OK total time: ", (time - $start), "sec\n" if $verbose;

    return $OK;
}

sub plural {
    my $self = shift;
    my $word = shift or confess *plural{PACKAGE} . "::plural Missing 'word'";
    my $num = shift or confess *plural{PACKAGE} . "::plural Missing 'num'";

    return $num > 1 ? ($word . "s") : $word;
}

sub get_fh {
    my $self = shift;
    my $fh = shift;
    my $dest_fh = shift; # not required; default is STDOUT
    defined($dest_fh) or $dest_fh = fileno(STDOUT);

    unless (defined($fh)) {
        $fh = new IO::Handle;
        $fh->fdopen($dest_fh,"w") or
	    confess "Unable to fdopen STDOUT: $!\n";
    }
    return $fh;
}

=head2 Functions required by IDS::Algorithm

=over

=item default_parameters()

Sets all of the default values for the parameters.  Normally called by
new() or one of its descendents.

=back

=cut

sub default_parameters {
    my $self = shift;

    %{$self->{"params"}} = (
        "verbose"         => 0,
	"state_file"      => 0,
	"prune_threshold" => 0,
	"auto_generalization_threshold" => 10,
    );
}

=over

=item param_options()

Command-line option specifiers for our parameters for GetOpt::Long.

=back

=cut

sub param_options {
    my $self = shift;

    return (
	"dfa_verbose=i"     => \$self->{"verbose"},
	"ids_state=s"       => \${$self->{"params"}}{"state_file"},
	"prune_threshold=i" => \${$self->{"params"}}{"prune_threshold"},
	"auto_generalization_threshold=i" => \${$self->{"params"}}{"auto_generalization_threshold"},
    );
}

=head2 Functions for the auto id of where generalization is necessary.

=over

=item generalization_needed

Looks through the DFA for high out-degrees with a low usage count.  The high out
degree says that we found a high variability here.  The low usage count says
that rarely were tokens duplicated.

This is not a DFA walk, but a scan through the nodes.

=back

=cut

sub generalization_needed {
    my $self = shift;
    my ($state, $max, $min, $nvref, $tnv, %in_tokens, $summary, $outdegree, $score);
    my ($sortfunc);
    my $verbose = ${$self->{"params"}}{"verbose"};

    # parameters, still under investigation as to what is important and why
    $verbose = 1;

#    $sortfunc = sub { ($b->autogen_nums)[0] <=> ($a->autogen_nums)[0] };
#    $sortfunc = sub { ($b->autogen_nums)[1] <=> ($a->autogen_nums)[1] };
#    $sortfunc = sub { ($b->autogen_nums)[2] <=> ($a->autogen_nums)[2] };
    $sortfunc = sub { ($b->autogen_nums)[3] <=> ($a->autogen_nums)[3] };
#    $sortfunc = sub { ($b->autogen_nums)[4] <=> ($a->autogen_nums)[4] };
    for $state (sort $sortfunc @{$self->{"states"}}) {
	($min, $max, $outdegree, $score, $nvref) = $state->autogen_nums;
	%in_tokens = ();
	map {$in_tokens{$_}++} $state->in_tokens;
        $summary = "";
	map {$summary .= "(" . ${$nvref}{$_} . ") " . $_ . "; " } keys %{$nvref};
	print join("; ", keys %in_tokens), "; out degree $outdegree; ",
	      "min $min max $max; score: $score; ",
	      "Token type(s): $summary\n" if $verbose;
    }
}

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the reponse depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Test>, L<IDS::DataSource>, L<IDS::Algorithm>

=cut

1;
