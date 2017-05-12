package IDS::Algorithm::MM;
use base qw(IDS::Algorithm);
$IDS::Algorithm::MM::VERSION = "1.0";

=head1 NAME

IDS::Algorithm::MM - Learn or test using a first-order Markov Model
(MM).

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

In section 4.2 in Kruegel and Vigna's paper, they ignored the
probability information that the MM provided, and produced a binary
result.  In effect, they were using the constructed MM as a {N,D}FA.

=head1 DESCRIPTION

Someday more will be here.

Ideally, we would be using the algorithm from stolcke94bestfirst.
Constructing a DFA rather than a NFA in effect has performed most of the
state merging that stolcke93hidden do.

Consider also a java or C/C++ implementaion:
http://www.ghmm.org/
http://www.run.montefiore.ulg.ac.be/~francois/software/jahmm/

Useful information:
http://www.cs.brown.edu/research/ai/dynamics/tutorial/Documents/HiddenMarkovModels.html
http://www.comp.leeds.ac.uk/roger/HiddenMarkovModels/html_dev/main.html
L R Rabiner and B H Juang, `An introduction to HMMs', IEEE ASSP
Magazine, 3, 4-16.

=cut

use strict;
use warnings;
use Carp qw(cluck carp confess);
use IDS::DFAState;
use IDS::Utils qw(to_fh);

sub default_parameters {
    my $self = shift;

    %{$self->{"params"}} = (
        "verbose"    => 0,
        "state_file" => 0,
    );
}

sub param_options {
    my $self = shift;

    return (
	    "markov_verbose=i" => \${$self->{"params"}}{"verbose"},
	    "ids_state=s"   => \${$self->{"params"}}{"state_file"},
    );
}

sub initialize {
    my $self = shift;

    $self->{"states"} = []; # a set of states
    $self->{"tokens"} = {}; # token to a list of states that the token will
		            # cause a transition into

    # set up start and accept states
    $self->{"states"}[0] = new IDS::DFAState($self->{"params"}{"verbose"}); # Start state
    $self->{"start"} = $self->{"states"}[0];
    $self->{"states"}[1] = new IDS::DFAState($self->{"params"}{"verbose"}); # Accept state
    $self->{"accept"} = $self->{"states"}[1];
    ${$self->{"tokens"}}{'(ACCEPT)'} = $self->{"accept"};

    # whether the MM has been reduced (generalized) via state merging
    $self->{"reduced"} = 0;
}

sub save {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    defined($fname) && $fname or
	confess *save{PACKAGE} .  "::save missing filename";
    my $fh = to_fh($fname, ">");

    my ($i, $s, $node_map);
    my $verbose = ${$self->{"params"}}{"verbose"};

    # generalization is not required, but controlled by IDS::Test
    # $self->{"reduced"} or $self->generalize;

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

This code was stolen from DFA, and does not know about the
probabilities.

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

=item load(filehandle)

Load a MM from a file; this is the inverse of "print", and the format
we expect is that used in $self->print.

=back

=cut

sub load {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    $fname or
	confess *load{PACKAGE} . "::load missing filename";
    my $fh = to_fh($fname, "<");

    my ($cnt, $from, $to, $token, $l);
    my $verbose = ${$self->{"params"}}{"verbose"};

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
	    $self->{"states"}[$from] = new IDS::DFAState($verbose);
	defined($self->{"states"}[$to]) or
	    $self->{"states"}[$to] = new IDS::DFAState($verbose);
	$self->{"states"}[$from]->add_outbound($token, $self->{"states"}[$to]);
	$self->{"states"}[$to]->add_inbound($self->{"states"}[$from], $token);
	### set count for the node from $cnt
	${$self->{"tokens"}}{$token} = $self->{"states"}[$to];
    }
    $self->verify if $verbose; # paranoia
}

=over

=item test(tokensref, string, instance)

Test the string of tokens and calculate the probability of the string
being seen.  At each stage, we get a p in [0,1].  The result is the
product of these probabilities.

Note that if a transition cannot be made, we return a 0 probability.

=back

=cut

sub test {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *test{PACKAGE} . "::test";
    my $string = shift; # not used
    my $instance = shift or
        confess "bug: missing instance to ", *test{PACKAGE} . "::test";

    my ($result, $t, $current_state, $next, $prob);

    $current_state = $self->{"start"};
    defined($current_state) or
	confess *test{PACKAGE} . "::test missing start state in MM";

    $result = 1.0;
    foreach $t (@{$tokensref}, "(ACCEPT)") { # note included eof token
	$next = $current_state->next($t);
	defined($next) or return 0;
	$prob = $current_state->probability($t);
	$result *= $prob;
	$current_state = $next;
    }
    return $result;
}

=over

=item add(tokensref, string, instance)

The collection of tokens (in the list referenced by tokensref)
is a complete example of a list that should be accepted by the DFA.  

string and instance are IDS::Test framework arguments that we ignore
because we do not need them.

WE add the transition from the last token to the '(ACCEPT)' state.

=back

=cut

sub add {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *add{PACKAGE} . "::add";
    my $string = shift; # not used
    my $instance = shift or
        confess "bug: missing instance to ", *add{PACKAGE} . "::add";
    my ($current_state, $t);
    my $verbose = ${$self->{"params"}}{"verbose"};

    $current_state = $self->{"start"};
    print "Start $current_state\n" if $verbose;
    foreach $t (@{$tokensref}) {
	defined($t) or cluck("undefined token in add.  List: '" .
	                     join("' '", @{$tokensref}) . "'");
	print "Adding a transition from $current_state for $t\n" if $verbose;
	### MM: Need to increment the counter for the transition usage
	$current_state = $self->add_transition($current_state, $t);
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
    $from->isa("IDS::DFAState") or
        confess *add_transition{PACKAGE} . "::add_transition 'from' is wrong type";
    my $token = shift; # the token causing the transition
    defined($token) or
        confess *add_transition{PACKAGE} . "::add_transition missing 'token'";
    my $verbose = ${$self->{"params"}}{"verbose"};
    my ($next, $end, $s, $next_state, $n);

    # First, see if a transition on this token already exists;  if so,
    # we will assume (valid?) that it is what we want.
    $next = $from->next($token);
    print "    existing transition $next\n" if defined($next) && $verbose;
    defined($next) and return $next;

    print "    No existing transition\n" if $verbose;
    # OK, we know the transition does not exist.  Does a *single* 
    # state exist that this token has caused a transition to in
    # the past?  If so, we assume (valid?) that we want to follow it.
    # In this DFA, a token can cause only one transition.
    if (exists ${$self->{"tokens"}}{$token}) {
	$s = ${$self->{"tokens"}}{$token};
	$from->add_outbound($token, $s);
	print "    going to existing state $s\n" if $verbose;
        return $s;
    }

    print "    No existing state\n" if $verbose;
    # We have run out of re-use options.  Create a new state and
    # set up the transition into it.
    $next_state = new IDS::DFAState($verbose);
    $from->add_outbound($token, $next_state);
    # done in add_outbound: $next_state->add_inbound($from, $token);
    ${$self->{"tokens"}}{$token} = $next_state;
    push @{$self->{"states"}}, $next_state;
    $n = $#{$self->{"states"}};
    print "    State $n $next_state\n" if $verbose;
    return $next_state;
}

=over

=item generalize()

Reduce the number of states in the model.

Our building a DFA rather than a NFA has in effect performed most of the
state merging that would have occurred.

XXX We should still be doing some checks for additional merge possibilities.

XXX A proof that the DFA is effectively the NFA with merged states would
be useful.

=back

=cut

sub generalize {
    my $self = shift;

    $self->{"reduced"} = 1;
}

# model prior, section 3.3 from stolcke93hidden
sub prior {
    my $self = shift;
    my ($m_s);

    # e^-sizeof(M)
    $m_s = exp(- scalar(@{$self->{"states"}}));
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

L<IDS::Test>, L<IDS::DataSource>, L<IDS::Algorithm>

Best-first Model Merging for Hidden Markov Model Induction by A. Stolcke
and S. M. Omohundro, Technical Report TR-94-003, 1994.
http://citeseer.ist.psu.edu/stolcke94bestfirst.html

Anomaly detection of web-based attacks by Christopher Kruegel and
Giovanni Vigna in Proceedings of the 10th ACM conference on Computer and
Communications Security, 2003, pages 251--261, ISBN 1-58113-738-9.
http://doi.acm.org/10.1145/948109.948144

=cut

1;
