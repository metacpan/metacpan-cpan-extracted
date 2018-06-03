package FLAT::DFA;

use strict;
use warnings;
use parent qw(FLAT::NFA);
use Storable qw(dclone);
use FLAT::DFA::Minimal;
use Carp;

sub set_starting {
    my $self = shift;
    $self->SUPER::set_starting(@_);

    my $num = () = $self->get_starting;
    confess "DFA must have exactly one starting state"
        if $num != 1;
}

sub complement {
    my $self = $_[0]->clone;

    for my $s ($self->get_states) {
        $self->is_accepting($s)
            ? $self->unset_accepting($s)
            : $self->set_accepting($s);
    }

    return $self;
}

sub _TUPLE_ID {join "\0", @_}

sub _uniq {
    my %seen;
    grep {!$seen{$_}++} @_;
}

## this method still needs more work..
sub intersect {
    my @dfas = map {$_->as_dfa} @_;

    my $return = FLAT::DFA->new;
    my %newstates;
    my @alpha = _uniq(map {$_->alphabet} @dfas);

    $_->_extend_alphabet(@alpha) for @dfas;

    my @start = map {$_->get_starting} @dfas;
    my $start = $newstates{_TUPLE_ID(@start)} = $return->add_states(1);
    $return->set_starting($start);
    $return->set_accepting($start)
        if !grep {!$dfas[$_]->is_accepting($start[$_])} 0 .. $#dfas;

    my @queue = (\@start);
    while (@queue) {
        my @tuple = @{shift @queue};

        for my $char (@alpha) {
            my @next = map {$dfas[$_]->successors($tuple[$_], $char)} 0 .. $#dfas;

            #warn "[@tuple] --> [@next] via $char\n";

            if (not exists $newstates{_TUPLE_ID(@next)}) {
                my $s = $newstates{_TUPLE_ID(@next)} = $return->add_states(1);
                $return->set_accepting($s)
                    if !grep {!$dfas[$_]->is_accepting($next[$_])} 0 .. $#dfas;
                push @queue, \@next;
            }

            $return->add_transition($newstates{_TUPLE_ID(@tuple)}, $newstates{_TUPLE_ID(@next)}, $char);
        }
    }

    return $return;
}

# this is meant to enforce 1 starting state for a DFA, but it is getting us into trouble
# when a DFA object calls unset_starting
sub unset_starting {
    my $self = shift;
    $self->SUPER::unset_starting(@_);
    my $num = () = $self->unset_starting;
    croak "DFA must have exactly one starting state"
        if $num != 1;
}

#### transformations

sub trim_sinks {
    my $self   = shift;
    my $result = $self->clone();
    foreach my $state ($self->array_complement([$self->get_states()], [$self->get_accepting()])) {
        my @ret = $self->successors($state, [$self->alphabet]);
        if (@ret) {
            if ($ret[0] == $state) {
                $result->delete_states($state) if ($result->is_state($state));
            }
        }
    }
    return $result;
}

# classical DFA minimization using equivalence classes
sub as_min_dfa {
    my $self     = shift()->clone;
    my $N        = $self->num_states;
    my @alphabet = $self->alphabet;
    my ($start)  = $self->get_starting;
    my %final    = map {$_ => 1} $self->get_accepting;
    my @equiv    = map [(0) x ($_ + 1), (1) x ($N - $_ - 1)], 0 .. $N - 1;
    while (1) {
        my $changed = 0;
        for my $s1 (0 .. $N - 1) {
            for my $s2 (grep {$equiv[$s1][$_]} 0 .. $N - 1) {
                if (1 == grep defined, @final{$s1, $s2}) {
                    $changed = 1;
                    $equiv[$s1][$s2] = 0;
                    next;
                }
                for my $char (@alphabet) {
                    my @t = sort {$a <=> $b} $self->successors([$s1, $s2], $char);
                    next if @t == 1;

                    if (not $equiv[$t[0]][$t[1]]) {
                        $changed = 1;
                        $equiv[$s1][$s2] = 0;
                    }
                }
            }
        }
        last if !$changed;
    }
    my $result = FLAT::DFA::Minimal->new;
    my %newstate;
    my @classes;
    for my $s (0 .. $N - 1) {
        next if exists $newstate{$s};

        my @c = ($s, grep {$equiv[$s][$_]} 0 .. $N - 1);
        push @classes, \@c;

        @newstate{@c} = ($result->add_states(1)) x @c;
    }
    for my $c (@classes) {
        my $s = $c->[0];
        for my $char (@alphabet) {
            my ($next) = $self->successors($s, $char);
            $result->add_transition($newstate{$s}, $newstate{$next}, $char);
        }
    }
    $result->set_starting($newstate{$start});
    $result->set_accepting($newstate{$_}) for $self->get_accepting;
    $result->set_equivalence_classes(\@classes);
    return $result;
}

# the validity of a given string <-- executes symbols over DFA
# if there is not transition for given state and symbol, it fails immediately
# if the current state we're in is not final when symbols are exhausted, then it fails

sub is_valid_string {
    my $self   = shift;
    my $string = shift;
    chomp $string;
    my $OK = undef;
    my @stack = split('', $string);
    # this is confusing all funcs return arrays
    my @current = $self->get_starting();
    my $current = pop @current;
    foreach (@stack) {
        my @next = $self->successors($current, $_);
        if (!@next) {
            return $OK;    #<--returns undef bc no transition found
        }
        $current = $next[0];
    }
    $OK++ if ($self->is_accepting($current));
    return $OK;
}

# Need to implement! http://www.ianab.com/hyper/
# DFA hyper-minimization using equivalence classes
sub as_hyper_min_dfa {
    my $self = shift()->clone;
}

# DFT stuff in preparation for DFA pump stuff;
sub as_node_list {
    my $self = shift;
    my %node = ();
    for my $s1 ($self->get_states) {
        $node{$s1} = {};    # initialize
        for my $s2 ($self->get_states) {
            my $t = $self->get_transition($s1, $s2);
            if (defined $t) {
                # array of symbols that $s1 will go to $s2 on...
                push(@{$node{$s1}{$s2}}, split(',', $t->as_string));
            }
        }
    }
    return %node;
}

sub as_acyclic_strings {
    my $self        = shift;
    my %dflabel     = ();                      # lookup table for dflable
    my %backtracked = ();                      # lookup table for backtracked edges
    my $lastDFLabel = 0;
    my @string      = ();
    my %nodes       = $self->as_node_list();
    # output format is the actual PRE followed by all found strings
    $self->acyclic($self->get_starting(), \%dflabel, $lastDFLabel, \%nodes, \@string);
}

sub acyclic {
    my $self        = shift;
    my $startNode   = shift;
    my $dflabel_ref = shift;
    my $lastDFLabel = shift;
    my $nodes       = shift;
    my $string      = shift;
    # tree edge detection
    if (!exists($dflabel_ref->{$startNode})) {
        $dflabel_ref->{$startNode} = ++$lastDFLabel;    # the order inwhich this link was explored
        foreach my $adjacent (keys(%{$nodes->{$startNode}})) {
            if (!exists($dflabel_ref->{$adjacent})) {    # initial tree edge
                foreach my $symbol (@{$nodes->{$startNode}{$adjacent}}) {
                    push(@{$string}, $symbol);
                    $self->acyclic($adjacent, \%{$dflabel_ref}, $lastDFLabel, \%{$nodes}, \@{$string});
                    if ($self->array_is_subset([$adjacent], [$self->get_accepting()])) {    #< proof of concept
                        printf("%s\n", join('', @{$string}));
                    }
                    pop(@{$string});
                }
            }
        }
    }
    # remove startNode entry to facilitate acyclic path determination
    delete($dflabel_ref->{$startNode});
    #$lastDFLabel--;
    return;
}

sub as_dft_strings {
    my $self  = shift;
    my $depth = 1;
    $depth = shift if (1 < $_[0]);
    my %dflabel = ();                      # scoped lookup table for dflable
    my %nodes   = $self->as_node_list();
    foreach (keys(%nodes)) {
        $dflabel{$_} = [];                 # initialize container (array) for multiple dflables for each node
    }
    my $lastDFLabel = 0;
    my @string      = ();
    $self->dft($self->get_starting(), [$self->get_accepting()], \%dflabel, $lastDFLabel, \%nodes, \@string, $depth);
}

sub dft {
    my $self        = shift;
    my $startNode   = shift;
    my $goals_ref   = shift;
    my $dflabel_ref = shift;
    my $lastDFLabel = shift;
    my $nodes       = shift;
    my $string      = shift;
    my $DEPTH       = shift;
    # add start node to path
    my $c1 = @{$dflabel_ref->{$startNode}};    # get number of elements
    if ($DEPTH >= $c1) {
        push(@{$dflabel_ref->{$startNode}}, ++$lastDFLabel);
        foreach my $adjacent (keys(%{$nodes->{$startNode}})) {
            my $c2 = @{$dflabel_ref->{$adjacent}};
            if ($DEPTH > $c2) {                # "initial" tree edge
                foreach my $symbol (@{$nodes->{$startNode}{$adjacent}}) {
                    push(@{$string}, $symbol);
                    $self->dft($adjacent, [@{$goals_ref}], $dflabel_ref, $lastDFLabel, $nodes, [@{$string}], $DEPTH);
                    # assumes some base path found
                    if ($self->array_is_subset([$adjacent], [@{$goals_ref}])) {
                        printf("%s\n", join('', @{$string}));
                    }
                    pop(@{$string});
                }
            }
        }    # remove startNode entry to facilitate acyclic path determination
        pop(@{$dflabel_ref->{$startNode}});
        $lastDFLabel--;
    }
}

#
# String gen using iterators (still experimental)
#

sub get_acyclic_sub {
    my $self = shift;
    my ($start, $nodelist_ref, $dflabel_ref, $string_ref, $accepting_ref, $lastDFLabel) = @_;
    my @ret = ();
    foreach my $adjacent (keys(%{$nodelist_ref->{$start}})) {
        $lastDFLabel++;
        if (!exists($dflabel_ref->{$adjacent})) {
            $dflabel_ref->{$adjacent} = $lastDFLabel;
            foreach my $symbol (@{$nodelist_ref->{$start}{$adjacent}}) {
                push(@{$string_ref}, $symbol);
                my $string_clone  = dclone($string_ref);
                my $dflabel_clone = dclone($dflabel_ref);
                push(
                    @ret,
                    sub {
                        return $self->get_acyclic_sub($adjacent, $nodelist_ref, $dflabel_clone, $string_clone, $accepting_ref, $lastDFLabel);
                    }
                );
                pop @{$string_ref};
            }
        }

    }
    # returns a complex data structure in the form of a hash reference
    return {
        substack    => [@ret],
        lastDFLabel => $lastDFLabel,
        string      => ($self->array_is_subset([$start], $accepting_ref) ? join('', @{$string_ref}) : undef)
    };
}

sub init_acyclic_iterator {
    my $self        = shift;
    my %dflabel     = ();
    my @string      = ();
    my $lastDFLabel = 0;
    my %nodelist    = $self->as_node_list();
    my @accepting   = $self->get_accepting();
    # initialize
    my @substack = ();
    my $r = $self->get_acyclic_sub($self->get_starting(), \%nodelist, \%dflabel, \@string, \@accepting, $lastDFLabel);
    push(@substack, @{$r->{substack}});
    return sub {
        while (1) {
            if (!@substack) {
                return undef;
            }
            my $s = pop @substack;
            my $r = $s->();
            push(@substack, @{$r->{substack}});
            if ($r->{string}) {
                return $r->{string};
            }
        }
        }
}

sub new_acyclic_string_generator {
    my $self = shift;
    my $iterator = $self->init_acyclic_iterator();
    return $iterator;
}

sub get_deepdft_sub {
    my $self = shift;
    my ($start, $nodelist_ref, $dflabel_ref, $string_ref, $accepting_ref, $lastDFLabel, $max) = @_;
    my @ret = ();
    my $c1  = (ref $dflabel_ref eq 'HASH') ? @{$dflabel_ref->{$start}} : 0;
    if ($max and $c1 < $max) {
        push(@{$dflabel_ref->{$start}}, ++$lastDFLabel);
        foreach my $adjacent (keys(%{$nodelist_ref->{$start}})) {
            my $c2 = @{$dflabel_ref->{$adjacent}};
            if ($c2 < $max) {
                foreach my $symbol (@{$nodelist_ref->{$start}{$adjacent}}) {
                    push(@{$string_ref}, $symbol);
                    my $string_clone  = dclone($string_ref);
                    my $dflabel_clone = dclone($dflabel_ref);
                    push(
                        @ret,
                        sub {
                            return $self->get_deepdft_sub($adjacent, $nodelist_ref, $dflabel_clone, $string_clone, $accepting_ref,
                                $lastDFLabel, $max);
                        }
                    );
                    pop @{$string_ref};
                }
            }
        }
    }
    return {
        substack    => [@ret],
        lastDFLabel => $lastDFLabel,
        string      => ($self->array_is_subset([$start], $accepting_ref) ? join('', @{$string_ref}) : undef)
    };
}

sub init_deepdft_iterator {
    my $self        = shift;
    my $MAXLEVEL    = shift;
    my %dflabel     = ();
    my @string      = ();
    my $lastDFLabel = 0;
    my %nodelist    = $self->as_node_list();
    foreach my $node (keys(%nodelist)) {
        $dflabel{$node} = [];    # initializes anonymous arrays for all nodes
    }
    my @accepting = $self->get_accepting();
    # initialize
    my @substack = ();
    my $r = $self->get_deepdft_sub($self->get_starting(), \%nodelist, \%dflabel, \@string, \@accepting, $lastDFLabel, $MAXLEVEL);
    push(@substack, @{$r->{substack}});
    return sub {
        while (1) {
            if (!@substack) {
                return undef;
            }
            my $s = pop @substack;
            my $r = $s->();
            push(@substack, @{$r->{substack}});
            if ($r->{string}) {
                return $r->{string};
            }
        }
        }
}

sub new_deepdft_string_generator {
    my $self = shift;
    my $MAXLEVEL = (@_ ? shift : 1);
    return $self->init_deepdft_iterator($MAXLEVEL);
}

1;

__END__

=head1 NAME

FLAT::DFA - Deterministic finite automata

=head1 SYNOPSIS

A FLAT::DFA object is a finite automata whose transitions are labeled
with single characters. Furthermore, each state has exactly one outgoing
transition for each available label/character. 

=head1 USAGE

In addition to implementing the interface specified in L<FLAT> and L<FLAT::NFA>, 
FLAT::DFA objects provide the following DFA-specific methods:

=over

=item $dfa-E<gt>unset_starting

Because a DFA, by definition, must have only ONE starting state, this allows one to unset
the current start state so that a new one may be set.

=item $dfa-E<gt>trim_sinks

This method returns a FLAT::DFA (though in theory an NFA) that is lacking a transition for 
all symbols from all states.  This method eliminates all transitions from all states that lead
to a sink state; it also eliminates the sink state.

This has no affect on testing if a string is valid using C<FLAT::DFA::is_valid_string>, 
discussed below.

=item $dfa-E<gt>as_min_dfa

This method minimizes the number of states and transitions in the given DFA. The modifies
the current/calling DFA object.

=item $dfa-E<gt>is_valid_string($string)

This method tests if the given string is accepted by the DFA.

=back

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and 
Brett Estrade E<lt>estradb at gmail dot comE<gt>.

The initial version (FLAT::Legacy) by Brett Estrade was work towards an 
MS thesis at the University of Southern Mississippi.

Please visit the Wiki at http://www.0x743.com/flat

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
