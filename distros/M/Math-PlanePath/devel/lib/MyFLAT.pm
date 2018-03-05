# Copyright 2016, 2017, 2018 Kevin Ryde
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.


# Some miscellaneous functions related FLAT.pm automatons.

package MyFLAT;
use 5.010;
use strict;
use warnings;
use Carp 'croak';
use List::Util 'max','sum';

# uncomment this to run the ### lines
# use Smart::Comments;

use base 'Exporter';
our @EXPORT_OK
  = (
     # generic, methods
     # 'get_non_accepting','num_accepting','num_non_accepting',
     # 'eventually_accepting', 'get_eventually_accepting',
     # 'get_eventually_accepting_info',
     # 'prefix',
     # 'prefix_accepting','get_prefix_accepting','get_prefix_accepting_info',
     # 'separate_sinks','add_sink',
     # 'rename_accepting_last',
     # 'is_accepting_sink',

     # generic functions
     'fraction_digits',

     # fairly specific
     'zero_digits_flat','one_bits_flat',
     'bits_N_even_flat','bits_N_odd_flat','bits_of_length_flat',
     'aref_to_FLAT_DFA',

     # temporary
     # 'as_nfa','concat','minimize','reverse,  # methods

     # misc
     'FLAT_count_contains',
     'FLAT_rename',
     'FLAT_to_perl_re',

     # personal preferences
     'view',
     'FLAT_check_is_equal','FLAT_check_is_subset',
     'FLAT_show_breadth',
     'FLAT_print_perl_table',
     'FLAT_print_perl_accepting',
     'FLAT_print_gp_inline_table',
     'FLAT_print_gp_inline_accepting',
     'FLAT_print_tikz',
    );
our %EXPORT_TAGS = (all => \@EXPORT_OK);


#------------------------------------------------------------------------------

=pod

=over

=item C<@states = $fa-E<gt>MyFLAT::get_non_accepting>

Return a list of all the non-accepting states in C<$fa>.

=back

=cut

sub get_non_accepting {
  my ($fa) = @_;
  return grep {! $fa->is_accepting($_)} $fa->get_states;
}

#------------------------------------------------------------------------------

=pod

=over

=item C<$count = num_accepting($fa)>

=item C<$count = num_non_accepting($fa)>

Return the number of accepting or non-accepting states in C<$fa>.

=back

=cut

sub num_accepting {
  my ($fa) = @_;
  my @states = $fa->get_accepting;
  return scalar(@states);
}
sub num_non_accepting {
  my ($fa) = @_;
  my @states = $fa->MyFLAT::get_non_accepting;
  return scalar(@states);
}

sub num_symbols {
  my ($fa) = @_;
  my @alphabet = $fa->alphabet;
  return scalar(@alphabet);
}

#------------------------------------------------------------------------------
# Prefixes

=pod

=over

=item C<$new_lang = $lang-E<gt>prefix>

=item C<$new_lang = $lang-E<gt>prefix ($proper)>

Return a new regular language object for prefixes of C<$lang>.  This means
all strings S for which there exists some T where S.T is in C<$lang>.  For
example if "abc" is in C<$lang> then C<$new_lang> has all prefixes "", "a",
"ab", "abc".

The default is to allow T empty, so all strings of C<$lang> are included in
C<$new_lang>.  Optional parameter C<$proper> true means T must be non-empty
so only proper prefixes S are accepted.

In both cases prefix S can be the empty string, if suitable T exists.  For
C<$proper> false this means if C<$lang> accepts anything at all (C<!
$lang-E<gt>is_empty>).  For C<$proper> true it means if C<$lang> accepts
some non-empty string.

=back

=cut

sub prefix {
  my ($self, $proper) = @_;
  $self = $self->clone;
  my @ancestors = $self->MyFLAT::ancestors([$self->get_accepting]);
  if ($proper) {
    $self->unset_accepting($self->get_accepting);
  }
  $self->set_accepting(@ancestors);
  return $self;
}

sub ancestors {
  my ($self, $state, $symb) = @_;
  my %targets;
  @targets{ref $state eq 'ARRAY' ? @$state : $state} = ();  # hash slice
  my %try;
  @try{$self->get_states} = (); # hash slice
  my %ret;
  my $more;
  do {
    $more = 0;
    foreach my $from (keys %try) {
      foreach my $to ($self->successors($from,$symb)) {
        if (exists $targets{$to}) {
          delete $try{$from};
          $ret{$from} = 1;
          $targets{$from} = 1;
          $more = 1;
        }
      }
    }
  } while ($more);
  return keys %ret;
}

sub predecessors {
  my ($self, $state, $symb) = @_;
  my %targets;
  @targets{ref $state eq 'ARRAY' ? @$state : $state} = ();  # hash slice
  my @ret;
  foreach my $from ($self->get_states) {
    foreach my $to ($self->successors($from,$symb)) {
      if (exists $targets{$to}) {
        push @ret, $state;
      }
    }
  }
  return @ret;
}

=pod

=over

=item C<@states = $fa-E<gt>get_prefix_states ()>

=item C<@states = $fa-E<gt>get_prefix_states ($proper)>

Return a list of those states which C<prefix()> would make accepting (and
all other states non-accepting).

This is all ancestor states of the accepting states in C<$fa>, so the
predecessors of accepting, the predecessors of them, etc.  The default
C<$proper> false includes the original accepting states (so all original
strings of C<$fa>).  For C<$proper> the original accepting states are not
included, unless they occur as ancestors.  (If they do, and are reachable
from starting states, then it means there are already some prefixes accepted
by C<$fa>.)

No attention is paid to start states and what might be reached from them.
This allows prefixing to be found or manipulated before setting starts.

C<$fa> can be modified to accept also its prefixes like a non-copying form
of C<$fa-E<gt>prefix()> by

    $fa->set_accepting($fa->get_prefix_states);



=item C<@states = get_prefix_accepting($fa)>

=item C<$fa = prefix_accepting($fa)>

C<get_prefix_accepting> returns states which are not accepting but which by
some sequence of symbols are able to reach accepting.

Some states of C<$fa> may be non-accepting, but able to reach an accepting
state by some sequence of symbols.  C<get_prefix_accepting()> returns a list
of those states.

C<prefix_accepting()> returns a new FLAT which has these "prefix accepting"
states set as accepting.  The effect is to accept all strings C<$fa> does,
and in addition accept all prefixes of strings accepted by C<$fa>, including
the empty string.

Prefix accepting states are the predecessors of accepting states, and
predecessors of those prefix states, etc.  This usually extends back to
starting states, and includes those states.  But no attention is paid to
starting-ness, the process just continues back by predecessors, irrespective
of what might be actually reachable from a starting state.

=back

=cut

# Return depth=>$depth,states=>$aref.
sub get_prefix_accepting_info {
  my ($fa) = @_;
  my $alphabet_aref = [ $fa->alphabet ];
  my %non_accepting;
  @non_accepting{$fa->MyFLAT::get_non_accepting} = ();  # hash slice
  my $depth = -1;
  my %prefixes;
  my $more;
  do {
    $depth++;
  STATE: while (my ($state) = each %non_accepting) {
      # if any successor is an accepting or accepting prefix then this state
      # is an accepting prefix too
      if (grep
          {$prefixes{$_} || $fa->is_accepting($_)}
          $fa->successors([$fa->epsilon_closure($state)], $alphabet_aref)) {
        $prefixes{$state} = 1;
        delete $non_accepting{$state};
        $more = 1;
      }
    }
  } while ($more--);
  return (depth => $depth, states => [ keys %prefixes ]);
}

sub get_prefix_accepting {
  my ($fa) = @_;
  my %info = get_prefix_accepting_info($fa);
  return @{$info{'states'}};
}

# Return a new FLAT (a clone) which accepts any initial prefix of the
# strings accepted by $fa.
# Each state is set to accepting if it has any accepting successor (some
# symbol leads to accepting), and repeating until no more such can be found.
#
sub prefix_accepting {
  my ($fa, %options) = @_;
  my %info = get_prefix_accepting_info($fa);
  my $states = $info{'states'};
  my $depth  = $info{'depth'};
  if ($options{'verbose'}) {
    print $fa->{name}//'',
      " accepting prefixes, count ",scalar(@$states)," more, depth=$depth\n";
  }

  $fa = $fa->clone;
  $fa->set_accepting(@$states);
  if (defined (my $name = $fa->{'name'})) {
    if ($depth) { $name .= ' prefixes'; }
    $fa->{'name'} = $name;
  }
  return $fa;
}

{
  package FLAT::Regex;
  sub MyFLAT_prefix {
    my $self = shift;
    $self->_from_op($self->op->MyFLAT_prefix(@_));
  }
  sub MyFLAT_suffix {
    my $self = shift;
    $self->_from_op($self->op->MyFLAT_suffix(@_));
  }
}
{
  package FLAT::Regex::Op::atomic;
  sub MyFLAT_prefix {
    my ($self, $proper) = @_;
    my $member = $self->members;
    return (! defined $member
            ? $self   # null regex, unchanged

            : $proper
            # symbol becomes empty string, # empty string becomes null regexp
            ? (ref $self)->new(length($member) ? '' : undef)

            : length($member)
            # symbol, accept it and also empty string
            ? FLAT::Regex::Op::alt->new((ref $self)->new(''), $self)

            # empty string, unchanged
            : $self);
  }
  *MyFLAT_suffix = \&MyFLAT_prefix;
}
{
  package FLAT::Regex::Op::star;
  sub MyFLAT_prefix {
    my ($self, $proper) = @_;
    my $member = $self->members;

    # M* -> M* properprefix(M)
    # Can be proper prefix always since a itself covered by M*.
    # But must check M has a non-empty string before doing that.
    # Otherwise get (M* #) which doesn't match anything at all, but for
    # $proper==0 want to match the empty string (unless M is_empty).

    return ($member->has_nonempty_string
            ? FLAT::Regex::Op::concat->new($self, $member->MyFLAT_prefix(1))

            : $proper ? FLAT::Regex::Op::atomic->new(undef)
            :           $member);  # empty string or null regex remains so
  }
  sub MyFLAT_suffix {
    my ($self, $proper) = @_;
    my $member = $self->members;

    # like prefix but reverse

    return ($member->has_nonempty_string
            ? FLAT::Regex::Op::concat->new($member->MyFLAT_suffix(1), $self)

            : $proper ? FLAT::Regex::Op::atomic->new(undef)
            :           $member);  # empty string or null regex remains so
  }
}
{
  package FLAT::Regex::Op::concat;
  sub MyFLAT_prefix {
    my ($self,$proper) = @_;

    # B C -> properprefix(B) | B prefix(C)
    #
    # If prefix(C) is not null then it includes the empty string and can go
    # to properprefix(B) since whole B is covered by (B []).
    #
    # If C is the empty string and $proper==1 then prefix(C) is null so get
    # (B #) which matches nothing and thus doesn't give whole C.  This is as
    # desired, since it is not a proper prefix in that case.
    #
    # For 3 or more concat members, nest like
    # A B C -> properprefix(A) | A ( properprefix(B) | B prefix(C) )
    #
    # properprefix() is allowed for the earlier parts once a non-null prefix
    # is seen.
    #
    # An empty $member means the whole concat matches nothing.  Watch for
    # that explicitly since B=# would give prefix(A) | (A #) which would
    # wrongly accept prefix(A).

    my $ret;
    foreach my $member (CORE::reverse $self->members) {
      if ($member->is_empty) { return $member; }
      my $prefix = $member->MyFLAT_prefix($proper);
      $ret = (defined $ret
              ? FLAT::Regex::Op::alt->new ($prefix,
                                           __PACKAGE__->new($member, $ret))
              : $prefix);
      $proper ||= ! $prefix->is_empty;
    }
    return $ret;
  }
  sub MyFLAT_suffix {
    my ($self,$proper) = @_;

    # similar to prefix, working forwards through members for the nesting
    # A B   ->   suffix(A) B | propersuffix(B)
    # A B C -> ( suffix(A) B | propersuffix(B)) C ) | propersuffix(C)

    my $ret;
    foreach my $member ($self->members) {
      if ($member->is_empty) { return $member; }
      my $suffix = $member->MyFLAT_suffix($proper);
      $ret = (defined $ret
              ? FLAT::Regex::Op::alt->new (__PACKAGE__->new($ret, $member),
                                           $suffix)
              : $suffix);
      $proper ||= ! $suffix->is_empty;
    }
    return $ret;
  }
}
{
  package FLAT::Regex::Op;
  # return new op of $self members transformed by $member->$method on each
  sub MyFLAT__map_method {
    my $self = shift;
    my $method = shift;
    return (ref $self)->new(map {$_->$method(@_)} $self->members);
  }
}
{
  package FLAT::Regex::Op::alt;
  # prefix(X|Y) = prefix(X) | prefix(Y)
  # suffix(X|Y) = suffix(X) | suffix(Y)
  sub MyFLAT_prefix {
    my $self = shift;
    return $self->MyFLAT__map_method('MyFLAT_prefix',@_);
  }
  sub MyFLAT_suffix {
    my $self = shift;
    return $self->MyFLAT__map_method('MyFLAT_suffix',@_);
  }
}
{
  package FLAT::Regex::Op::shuffle;
  *MyFLAT_prefix = \&FLAT::Regex::Op::alt::MyFLAT_prefix;
  *MyFLAT_suffix = \&FLAT::Regex::Op::alt::MyFLAT_suffix;
}



#------------------------------------------------------------------------------
# Eventually Accepting

=pod

=over

=item C<@states = get_eventually_accepting($fa)>

=item C<$fa = eventually_accepting($fa)>

Some states of C<$fa> may be "eventually accepting" in the sense that after
more symbols they are certain to reach accepting, for all possible further
symbol values.

For example suppose alphabet a,b,c.  If bba, bbb and bbc are all accepted by
C<$fa> then string "bb" is reckoned as eventually accepted since one further
symbol, any of a,b,c, goes to accepting.

C<get_eventually_accepting()> returns a list of states which are eventually
accepting.  C<eventually_accepting()> returns a clone of C<$fa> which has
those states set as accepting.

Eventually accepting states are found first as any state with all symbols
going to accepting, then any state with all symbols going to either
accepting or eventually accepting, and so on until no more such further
states.

In an NFA any epsilon transitions are crossed in the usual way, but there
should be just one starting state (or just one which ever leads to
accepting).  If multiple starting states then the simple rule used will
sometimes fail to find all eventually accepting states and hence strings.
C<as_dfa> will collapse multiple starts.

=back

=cut

# Return depth=>$depth,states=>$aref.
sub get_eventually_accepting_info {
  my ($fa) = @_;
  my $alphabet_aref = [ $fa->alphabet ];
  my %non_accepting;
  @non_accepting{$fa->MyFLAT::get_non_accepting} = ();  # hash slice
  my %eventually;
  my $depth = -1;
  my $more;
  do {
    $depth++;
    my @new_eventually;
  STATE: while (my ($state) = each %non_accepting) {
      ### $state
      foreach my $to_state ($fa->successors([$fa->epsilon_closure($state)],
                                            $alphabet_aref)) {
        ### $to_state
        unless ($eventually{$to_state} || $fa->is_accepting($to_state)) {
          next STATE;
        }
      }
      push @new_eventually, $state;
    }
    foreach my $state (@new_eventually) {
      $eventually{$state} = 1;
      delete $non_accepting{$state};
      $more = 1;
    }
  } while ($more--);
  return (depth => $depth, states => [ keys %eventually ]);
}

sub get_eventually_accepting {
  my ($fa) = @_;
  my %info = get_eventually_accepting_info($fa);
  return @{$info{'states'}};
}

# Return a new FLAT (a clone) which accepts strings eventually accepted by $fa.
sub eventually_accepting {
  my ($fa, %options) = @_;
  my %info = get_eventually_accepting_info($fa);
  my $states = $info{'states'};
  my $depth  = $info{'depth'};
  if ($options{'verbose'}) {
    print $fa->{name}//'',
      " eventually accepting, count ",scalar(@$states)," more, depth=$depth\n";
  }

  $fa = $fa->clone;
  $fa->set_accepting(@$states);
  if (defined (my $name = $fa->{'name'})) {
    if ($depth) { $name .= ' eventually'; }
    $fa->{'name'} = $name;
  }
  return $fa;
}


#------------------------------------------------------------------------------

=pod

=over

=item C<$fa = fraction_digits($num,$den, %options)>

Return a C<FLAT::DFA> which matches digits of fraction C<$num/$den>.
The DFA remains accepting as long as it is given successive digits of the
fraction, and goes non-accepting (and remains so) on a wrong digit.

The default is decimal digits, or optional key/value

    radix  => integer>=2

If C<$num/$den> is an exact fraction in C<$radix>, meaning C<$num/$den ==
n/$radix**k> for some integer n,k, then it has two different
representations.  Firstly terminating digits followed by trailing 0s,
secondly C<$n-1> followed by trailing C<$radix-1> digits.

For example 42/100 is 420000... and 419999...  Both digit sequences converge
to 42/100.  For fractions not an exact power of C<$radix> there is just one
digit sequence which converges to C<$num/$den>.

C<$num == 0> gives a DFA matching 000..., or C<$num==$den> for fraction
C<$num/$den == 1> gives a DFA matching 9999... (or whatever C<$radix-1>).

In all cases the C<$fa-E<gt>alphabet> is all the digits 0 to C<$radix-1>.
Those which are "wrong" digits at a given point go to a non-accepting sink
state.  This is designed so that C<$fa-E<gt>complement> gives all digit
strings except fraction C<$num/$den>.

MAYBE: Option to omit wrong digits in an NFA, so transitions only for the
accepted digits.

MAYBE: Currently the symbols for digits in a radix 11 or higher are decimal
strings, but that might change.  Could have an option for hex or a table or
func.  Decimal strings are easy to work with their values in Perl if a
further func might act on the resulting FLAT.  C<FLAT_rename> can always
change for final result if desired.

=back

=cut

sub fraction_digits {
  my ($num, $den, %options) = @_;
  ### fraction_digits(): "$num / $den"

  require FLAT::DFA;
  my $f = FLAT::DFA->new;

  my $radix = $options{'radix'} || 10;
  ### $radix

  my $not_accept = $f->add_states(1);
  $f->add_transition ($not_accept,$not_accept, 0..$radix-1);

  unless ($num >=0 && $num <= $den) {
    croak "fraction_digits() must have 0<=num<=den";
  }
  unless ($radix >= 2) {
    croak "fraction_digits() must have radix>=2";
  }

  my %num_to_state;
  my $prev_state = $f->add_states(1);
  $f->set_starting ($prev_state);
  $f->set_accepting ($prev_state);
  $num_to_state{$num} = $prev_state;
  my $prev_digit;
  my $prev_prev_state;

  if ($num == $den) {
    # 1/1 match .9999...
    $f->add_transition ($prev_state,$prev_state,      $radix-1);
    $f->add_transition ($prev_state,$not_accept, 0..$radix-2);
    return $f;
  }

  for (;;) {
    ### $num

    $num *= $radix;
    my $digit = int($num / $den);
    $num %= $den;
    if ($digit >= 10) { $digit = chr(ord('A')+$digit-10); }
    ### $digit

    my $cycle_state = $num_to_state{$num};
    my $state = $cycle_state // $f->add_states(1);
    $f->set_accepting ($state);
    $f->add_transition ($prev_state,$state, $digit);
    $f->add_transition ($prev_state,$not_accept,
                        grep {$_!=$digit} 0..$radix-1);

    if (defined $cycle_state) {
      if ($num == 0 && $prev_digit) {
        $state = $f->add_states(1);
        $f->set_accepting ($state);
        $f->set_transition ($prev_prev_state, $not_accept,
                            grep {$_!=$prev_digit-1 && $_!=$prev_digit}
                            0..$radix-1);
        $f->add_transition ($prev_prev_state,$state, $prev_digit-1);
        $f->add_transition ($state,$state,      $radix-1);
        $f->add_transition ($state,$not_accept, 0..$radix-2);
      }
      return $f;
    }

    $num_to_state{$num} = $state;
    $prev_digit = $digit;
    $prev_prev_state = $prev_state;
    $prev_state = $state;
  }
}

  # $radix ||= 10;
  # unless ($num >=0 && $num < $den) {
  #   croak "fraction_digits() must have 0<=num<den";
  # }
  # my @digits;  # the successive digits of $num/$den
  # my %seen;    # $digit=>$index of digits in @digits
  # my $pos = 0;
  # for (;;) {
  #   if (defined(my $rpos = $seen{$num})) {
  #     # this numerator is a repeat of what was at $rpos, so cycle back to there
  #     require FLAT::DFA;
  #     my $f = FLAT::DFA->new;
  #     my @states = $f->add_states($pos+1);
  #     $f->set_starting($states[0]);
  #     $f->set_accepting(@states[0..$pos-1]);
  #     foreach my $i (0 .. $pos) {
  #       foreach my $d (0 .. $radix-1) {
  #         my $to = ($i==$pos || $d != $digits[$i] ? $pos   # not accept
  #                   : $i == $pos-1 ? $rpos                 # cycle back
  #                   : $i+1);                               # next
  #         $f->add_transition ($states[$i],$states[$to]);
  #       }
  #     }
  #     $f->{'name'} = "$num/$den radix $radix";
  #     return $f;
  #   }
  # 
  #   ### $num
  #   ### assert: $num >= 0
  #   ### assert: $num < $den
  #   $seen{$num} = $pos++;
  #   $num *= $radix;
  #   my $digit = int($num / $den);
  #   $num %= $den;
  #   if ($digit >= 10) { $digit = chr(ord('A')+$digit-10); }
  #   push @digits, $digit;
  # }

#
# my $str;
#   $str .= $digit;
# my $re = substr($str,0,$rpos) . "(".substr($str,$rpos) . ")*";
# ### $str
# ### $rpos
# ### $re
# my $f = FLAT::Regex->new($re)->as_dfa;
# $f->{'name'} = "$num/$den radix $radix";
# $f = prefix($f);
# return $f;


# $fa is a FLAT::DFA which matches fractions represented as strings of digits.
# Return a new FLAT::DFA which matches any terminating fraction like 10111
# also as its non-terminating equivalent 101101111...
# FIXME: currently only works for binary, and only when terminating
# fractions end with a 1, not with low 0s.
sub fraction_also_nines {
  my ($fa, %options) = @_;

  # FLAT::Regex->new ('(0|1)* 1 0*')->as_nfa;

  my $binary_odd_flat = FLAT::Regex->new ('(0|1)* 1')->as_dfa;
  return $fa->as_dfa
    ->intersect($binary_odd_flat)
    ->MyFLAT::skip_final
    ->MyFLAT::concat(FLAT::Regex->new ('01*')->as_dfa)
    ->union($fa)
    ->MyFLAT::set_name($fa->{'name'});
}

# $fa is a FLAT::NFA or FLAT::DFA accepting strings of digits.
# Those strings are interpreted as fractional numbers .ddddd...
# Return a new FLAT (same DFA or NFA) which accepts these same strings and
# also representations ending 999...
# For example if 321 is accepted then 3209999... is also accepted.
#
# The radix is taken from $fa->alphabet, or option radix=>$r can be given if
# $fa might not have all digits appearing.
#
# The digit strings read high to low by default.  Option
# direction=>"lowtohigh" can interpret them low to high instead.  Low to
# high will be more efficient since manipulations are at the low end
# (propagate a carry up through low "9"s), but both work.
#
# sub fraction_nines {
#   my ($fa, %options) = @_;
#   ### digits_increment() ...
# 
#   # starting state is flip
#   # in flip 0-bit successor as a 1-bit, and thereafter unchanged
#   #         1-bit successor as a 0-bit, continue flip
# 
#   my $direction = $options{'direction'} || 'hightolow';
#   my $radix     = $options{'radix'} || max($fa->alphabet)+1;
#   my $nine      = $radix-1;
# 
#   my $is_dfa = $fa->isa('FLAT::DFA');
#   $fa = $fa->clone->MyFLAT::as_nfa;
#   if ($direction eq 'hightolow') { $fa = $fa->reverse; }
# 
#   my %flipped_states;
#   {
#     # states reachable by runs of 9s from starting states
#     my @pending = $fa->get_starting;
#     while (defined (my $state = shift @pending)) {
#       unless (exists $flipped_states{$state}) {
#         my ($new_state) = $fa->add_states(1);
#         ### add: "state=$state new=$new_state"
#         $flipped_states{$state} = $new_state;
# 
#         if ($fa->is_starting($state)) {
#           $fa->set_starting($new_state);
#           $fa->unset_starting($state);
#         }
#         push @pending, $fa->successors($state, $nine);
#       }
#     }
#   }
# 
#   while (my ($state, $flipped_state) = each %flipped_states) {
#     ### setup: "$state nines becomes $flipped_state"
# 
#     foreach my $digit (0 .. $nine-1) {
#       foreach my $successor ($fa->successors($state, $digit)) {
#         ### digit: "digit=$digit  $flipped_state -> $successor on 1"
#         $fa->add_transition($flipped_state, $successor, $digit+1);
#       }
#     }
#     if ($fa->is_accepting($state)) {
#       # 99...99 accepting becomes 00..00 1 accepting, with a new state for
#       # the additional 1-bit to go to
#       my ($new_state) = $fa->add_states(1);
#       $fa->set_accepting($new_state);
#       $fa->add_transition($flipped_state, $new_state, 1);
#       ### carry above accepting: $new_state
#     }
# 
#     foreach my $successor ($fa->successors($state, $nine)) {
#       ### nine: "$flipped_state -> $flipped_states{$successor} on 0"
#       $fa->add_transition($flipped_state, $flipped_states{$successor}, 0);
#     }
#   }
# 
#   if (defined $fa->{'name'}) {
#     $fa->{'name'} =~ s{\+(\d+)$}{'+'.($1+1)}e
#       or $fa->{'name'} .= '+1';
#   }
# 
#   if ($direction eq 'hightolow') { $fa = $fa->reverse; }
#   if ($is_dfa) { $fa = $fa->as_dfa; }
#   return $fa;
# }


#------------------------------------------------------------------------------

=pod

=over

=item C<$new_fa = $fa-E<gt>MyFLAT::separate_sinks>

Return a copy of C<$fa> which has separate sink states.

A sink state is where all out transitions loop back to itself.  If two or
more states go to the same sink then the return has new states so that each
goes to its own such sink.  The new sinks are the same accepting or not as
each original sink.

This does not change the strings accepted, but can help viewing a big
diagram where many long range transitions go to a single accepting and/or
non-accepting sink.

Only single sink states are sought.  Multiple states cycling among
themselves all the same accepting or non-accepting are sinks, but they can
be merged by an C<as_min_dfa>.

=item C<$bool = $fa-E<gt>MyFLAT::is_sink($state)>

Return true if C<$state> has all transitions go to itself.

=back

=cut

sub separate_sinks {
  my ($fa) = @_;
  $fa = $fa->clone;
  my %sink_used;
  my @alphabet = $fa->alphabet;
  foreach my $from_state ($fa->get_states) {
    foreach my $to_state ($fa->successors($from_state)) {
      next unless $fa->MyFLAT::is_sink($to_state);
      next if $from_state==$to_state;
      next unless $sink_used{$to_state}++;

      my $new_state = $fa->MyFLAT::copy_state($to_state);
      my @labels = FLAT_get_transition_labels($fa,$from_state,$to_state);

      ### common sink: "$from_state to $to_state, new $new_state, labels ".join(' ',@labels)

      # when $fa is an NFA and add_transition() accumulates, so for it must
      # remove old transitions
      $fa->remove_transition($from_state,$to_state);

      $fa->add_transition($from_state,$new_state,@labels);
    }
  }
  return $fa;
}

# $fa is a FLAT::FA.
# FIXME: what about cycles of mutual transitions among accepting states?
sub is_sink {
  my ($fa, $state) = @_;
  my @next = $fa->successors($state);
  return @next==1 && $next[0]==$state;
}

sub is_accepting_sink {
  my ($fa, $state) = @_;
  $fa->MyFLAT::is_sink($state) && $fa->is_accepting($state);
}
sub get_accepting_sinks {
  my ($fa) = @_;
  return grep {$fa->MyFLAT::is_accepting_sink($_)} $fa->get_states;
}
sub num_accepting_sinks {
  my ($fa) = @_;
  # this depends on use of grep in get_accepting_sinks()
  return scalar($fa->MyFLAT::get_accepting_sinks);
}

=pod

=over

=item C<$new_state = $fa-E<gt>MyFLAT::copy_state ($state)>

Add a state to C<$fa> which is a copy of C<$state>.  Transitions out and
accepting-ness of C<$new_state> and the same as C<$state>.  Return the new
state number.

=back

=cut

sub copy_state {
  my ($fa, $state) = @_;
  ### copy_state(): $state

  my ($new_state) = $fa->add_states(1);
  if ($fa->is_accepting ($state)) {
    $fa->set_accepting($new_state);
  }
  # ENHANCE-ME: transition can be copied more efficiently?
  foreach my $symbol ($fa->alphabet) {
    foreach my $next ($fa->successors($state, $symbol)) {
      my $new_next = ($next == $state ? $new_state : $next);
      $fa->add_transition($new_state,$new_next, $symbol);
    }
  }
  return $new_state;
}

#------------------------------------------------------------------------------

# $fa is a FLAT::FA.
# Return a new FLAT with some of its states or symbols renamed.
#
#     symbols_func => $coderef called $new_symbol = $coderef->($old_symbol)
#     symbols_map  => $hashref of $old_symbol => $new_symbol
#     states_map   => $hashref of $old_state  => $new_state
#     states_list  => arrayref of existing states in order for the new
#
# Any states or symbols in $fa unmentioned in these mappings are unchanged,
# so some can be changed and the rest left alone.
#
# Symbols can be swapped or cycled by for example {'A'=>'B', 'B'=>'A'}.
# States similarly.
#
sub FLAT_rename {
  my ($fa, %options) = @_;
  my @alphabet = $fa->alphabet;

  my $symbols_func = $options{'symbols_func'}
    // do {
      my $symbols_map  = $options{'symbols_map'} // {};
      sub {
        my ($symbol) = @_;
        return $symbols_map->{$symbol};
      }
    };

  my $states_map  = $options{'states_map'}  // {};
  if (defined(my $states_list = $options{'states_list'})) {
    $states_map = { map {$_ => $states_list->[$_]} 0 .. $#$states_list };
  }

  my $new = (ref $fa)->new;
  $new->add_states($fa->num_states);

  foreach my $old_state ($fa->get_states) {
    my $new_state = $states_map->{$old_state} // $old_state;
    if ($fa->is_accepting($old_state)) { $new->set_accepting($new_state); }
    if ($fa->is_starting ($old_state)) { $new->set_starting ($new_state); }

    foreach my $symbol (@alphabet) {
      my $new_symbol = $symbols_func->($symbol) // $symbol;
      foreach my $old_next ($fa->successors($old_state, $symbol)) {
        my $new_next = $states_map->{$old_next} // $old_next;
        $new->add_transition($new_state, $new_next, $new_symbol);
      }
    }
  }
  $new->{'name'} = $fa->{'name'};
  return $new;
}

# Return a new FLAT::FA of the same type as $fa but where any accepting
# states are numbered last.
sub rename_accepting_last {
  my ($fa, %options) = @_;
  return FLAT_rename($fa, states_list =>
                     [ $fa->MyFLAT::get_non_accepting, $fa->get_accepting ]);
}

#------------------------------------------------------------------------------

# zero_digits_flat() returns a FLAT::DFA matching a run of 0 digits,
# possibly an empty run.  This is regex "0*", but with alphabet 0 .. $radix-1.
sub zero_digits_flat {
  my ($radix) = @_;
  my $f = FLAT::DFA->new;
  $f->add_states(2);
  $f->set_starting(0);
  $f->set_accepting(0);
  $f->add_transition(0,0, 0);                # state 0 accept 0s
  $f->add_transition(0,1, 1 .. $radix-1);
  $f->add_transition(1,1, 0 .. $radix-1);    # state 1 non-accepting sink
  return $f;
}

# one_bits_flat() returns a FLAT::DFA matching a run of 1 bits, possibly an
# empty run.  This is regex "1*", but with alphabet 0,1.
use constant::defer one_bits_flat => sub {
  require FLAT::DFA;
  my $f = FLAT::DFA->new;
  $f->add_states(2);
  $f->set_starting(0);
  $f->set_accepting(0);
  $f->add_transition(0,0, 1);
  $f->add_transition(0,1, 0);
  $f->add_transition(1,1, 1);
  $f->add_transition(1,1, 0);
  return $f;
};

# Return a FLAT::DFA which matches bit strings which are an even number N.
# An empty string "" is reckoned as 0 and so is matched.
use constant::defer bits_N_even_flat => sub {
  require FLAT::Regex;
  my $f = FLAT::Regex->new('(0|1)* 0 | []')->as_dfa;
  $f->{'name'} = 'even N';
  return $f;
};
# Return a FLAT::DFA which matches bit strings which are an odd number N.
use constant::defer bits_N_odd_flat => sub {
  require FLAT::Regex;
  my $f = FLAT::Regex->new('(0|1)* 1')->as_dfa;
  $f->{'name'} = 'odd N';
  return $f;
};

# Return a FLAT::DFA which matches exactly $len many bits 0,1.
sub bits_of_length_flat {
  my ($len) = @_;
  require FLAT::Regex;
  return FLAT::Regex->new('(0|1)' x $len)
    ->as_dfa
    ->MyFLAT::set_name("$len bits");
}

#------------------------------------------------------------------------------

# Return all the labels which transition $from_state to $to_state.
sub FLAT_get_transition_labels {
  my ($fa, $from_state, $to_state) = @_;
  ### FLAT_get_transition_labels(): "$from_state to $to_state"
  my @ret;
  foreach my $symbol ($fa->alphabet) {
    ### $symbol
    my $next;
    if ((($next) = $fa->successors($from_state, $symbol))
        && $next==$to_state) {
      push @ret, $symbol;
    }
    ### $next
  }
  ### @ret
  return @ret;
}

#------------------------------------------------------------------------------
# printouts

sub FLAT_varname {
  my ($fa) = @_;
  my $name = $fa->{'name'};
  if (defined $name) {
    $name =~ tr/a-zA-Z0-9_/_/c;
  }
  return $name;
}

sub FLAT_print_perl_table {
  my ($fa, $name) = @_;
  $name //= FLAT_varname($fa);
  my @alphabet = sort {$a<=>$b} $fa->alphabet;
  print "# alphabet ",join(',',@alphabet),"\n";
  require MyPrintwrap;
  print "\@$name = (\n";
  MyPrintwrap::printwrap_indent("  ");
  my @states = $fa->get_states;
  foreach my $state (@states) {
    my @row = map { my $symbol = $_;
                    my @next = $fa->successors($state,$symbol);
                    if (@next != 1) {
                      croak "Not single next for $state symbol $symbol";
                    }
                    $next[0]
                  } @alphabet;
    MyPrintwrap::printwrap(" [".join(',',@row)."]"
                           . ($state == $#states ? "" : ','));
  }
  print ");\n";
}
sub FLAT_print_perl_accepting {
  my ($fa, $name) = @_;
  $name //= FLAT_varname($fa);
  my @accepting = $fa->get_accepting;
  my $start = "\@$name = (";
  my $end = ");\n";
  my $line = $start . join(',',@accepting) . $end;
  if (length $line < 79) {
    print "$line\n";
    return;
  }
  require MyPrintwrap;
  MyPrintwrap::printwrap_indent("  ");
  print $start,"\n";
  foreach my $i (0 .. $#accepting) {
    MyPrintwrap::printwrap("$accepting[$i]"
                           . ($i == $#accepting ? "" : ','));
  }
  MyPrintwrap::printwrap($end);
}

sub FLAT_print_gp_inline_table {
  my ($fa, $name) = @_;
  require MyPrintwrap;
  print "% GP-DEFINE  $name = {[\n";
  MyPrintwrap::printwrap_indent("% GP-DEFINE    ");
  my @alphabet = sort {$a<=>$b} $fa->alphabet;
  my @states = $fa->get_states;
  foreach my $state (@states) {
    my @row = map { scalar($fa->successors($state,$_)) + 1 } @alphabet;
    MyPrintwrap::printwrap(join(',',@row)
                           . ($state == $#states ? "\n" : ';'));
  }
  print "% GP-DEFINE  ]};\n";
}
sub FLAT_print_gp_inline_accepting {
  my ($fa, $name) = @_;
  my @accepting = $fa->get_accepting;
  require MyPrintwrap;
  my $start = "% GP-DEFINE  $name = {[";
  my $end = "]};\n";
  my $line = $start . join(',',@accepting) . $end;
  if (length $line < 79) {
    print "$line\n";
    return;
  }
  print $start,"\n";
  foreach my $i (0 .. $#accepting) {
    printwrap("$accepting[$i]" . ($i == $#accepting ? "\n" : ','));
  }
  print "% GP-DEFINE  $end";
}

sub FLAT_print_tikz {
  my ($fa, %options) = @_;
  my $node_prefix = $options{'node_prefix'} // 's';
  my $flow = $options{'flow'} // $fa->{'flow'} // 'east';

  my @column_to_states;
  my @state_to_column;
  my $put_state = sub {
    my ($state, $column) = @_;
    $state_to_column[$state] = $column;
    push @{$column_to_states[$column]}, $state;
  };

  foreach my $state ($fa->get_starting) {
    $put_state->($state, 0);
  }
  for (my $c = 0; $c <= $#column_to_states; $c++) {
    foreach my $from_state (@{$column_to_states[$c]}) {
      next unless defined $state_to_column[$from_state];
      my $to_column = $state_to_column[$from_state] + 1;
      foreach my $to_state (sort $fa->successors($from_state)) {
        next if defined $state_to_column[$to_state];
        $put_state->($to_state, $to_column);
      }
    }
  }
  # unreached states at end
  foreach my $state ($fa->get_states) {
    next if defined $state_to_column[$state];
    $put_state->($state, scalar(@column_to_states));
  }

  foreach my $column (0 .. $#column_to_states) {
    my $states = $column_to_states[$column];
    foreach my $i (0 .. $#$states) {
      my $state = $states->[$i];
      my $x = $column;
      my $y = $i - int(scalar(@$states)/2);
      if ($flow eq 'west') { $x = -$x; }
      if ($flow eq 'north') { ($x,$y) = ($y,$x); }
      if ($flow eq 'south') { ($x,$y) = ($y,-$x); }
      my $state_name = "$node_prefix$state";
      print "  \\node ($state_name) at ($x,$y) [my box] {$state};\n";
    }
  }
  print "\n";

  my @alphabet = sort {$a<=>$b} $fa->alphabet;
  foreach my $from_state ($fa->get_states) {
    my $from_state_name = "$node_prefix$from_state";
    print "  % $from_state_name\n";
    require Tie::IxHash;
    my %to_lists;
    tie %to_lists, 'Tie::IxHash';
    foreach my $symbol (@alphabet) {
      if (my ($to_state) = $fa->successors($from_state, $symbol)) {
        push @{$to_lists{$to_state}}, $symbol;
      }
    }
    while (my ($to_state, $labels) = each %to_lists) {
      my $to_state_name = "$node_prefix$to_state";
      $labels = join(',', @$labels);
      if ($from_state eq $to_state) {
        print "  \\draw [->,loop below] ($from_state_name) to node[pos=.12,auto=left] {$labels} ();\n";
      } else {
        my $bend = '';
        if ($fa->get_transition($to_state,$from_state)) {
          $bend = ',bend left=10';
        }
        print "  \\draw [->$bend] ($from_state_name) to node[pos=.45,auto=left] {$labels} ($to_state_name);\n";
      }
    }
    print "\n";
  }
}


#------------------------------------------------------------------------------

# $aref is an arrayref of arrayrefs which is a state table.
#         [ [1,2],
#           [2,0],
#           [0,1] ]
# States are numbered C<0> to C<$#$aref> inclusive.
# The table has C<$new_state = $aref-E<gt>[$state]-E<gt>[$digit]>.
# Return a FLAT::DFA of this state table.
#
# Optional further key/value arguments are
#     starting         => $state
#     accepting        => $state
#     accepting_list   => arrayref [ $state, $state, ... ]
#     name             => $string
#
# C<starting> is the starting state, or default 0.
#
# C<accepting> or C<accepting_list> are the state or states which are accepting.
# If both C<accepting> and C<accepting_list> are given then both their states
# specified are made accepting.
#
sub aref_to_FLAT_DFA {
  my ($aref, %options) = @_;
  require FLAT::DFA;
  my $f = FLAT::DFA->new;
  my @fstates = $f->add_states(scalar(@$aref));

  my $starting = $options{'starting'} // 0;
  $f->set_starting($fstates[$starting]);
  ### starting: "$starting (= $fstates[$starting])"

  my @accepting = (@{$options{'accepting_list'} // []},
                   $options{'accepting'} // ());
  if (! @accepting) { @accepting = $#$aref; }
  $f->set_accepting(map {$fstates[$_]} @accepting);

  my $width = @{$aref->[0]};
  foreach my $state (0 .. $#$aref) {
    my $row = $aref->[$state];
    if (@$row != $width) {
      croak "state row $state doesn't have $width entries";
    }
    foreach my $digit (0 .. $#$row) {
      my $to_state = $row->[$digit]
        // croak "state $state digit $digit destination undef";
      ($to_state >= 0 && $to_state <= $#$aref)
        or croak "state $state digit $digit destination $to_state out of range";
      ### transition: "$state(=$fstates[$state]) digit=$digit -> $to_state($fstates[$to_state])"
      $f->add_transition($fstates[$state], $fstates[$to_state], $digit);
    }
  }

  $f->{'name'} = $options{'name'};
  return $f;
}


#------------------------------------------------------------------------------

# $fa is a FLAT::NFA or FLAT::DFA.
# Return a list of how many strings of length $len are accepted, for $len
# running 0 to $max_len inclusive.
# The counts can become large, especially when $fa has a lot of symbols.
# The numeric type of the return is inherited from $max_len, so for example
# if it is a Math::BigInt then that is used for the returns.
# In general, the counts are a linear recurrences with order at most the number
# of states in $fa.  Such recurrences include constants (like one string of
# each length), and polynomials.
#
# MAYBE: length => $len          count strings = $len accepted
# MAYBE: max_length => $len      count strings <= $len accepted
# MAYBE: by_length_upto => $len  counts of strings each length <= $len
#
# count_matrix($fa) = [],[]  $array[$row]->[$col]  with M*initcol = counts
# count_recurrence($fa)
#
sub FLAT_count_contains {
  my ($fa, $max_len) = @_;
  my @states    = $fa->get_states;
  my @accepting = $fa->get_accepting;
  my @alphabet  = $fa->alphabet;
  my @counts = ($max_len*0) x scalar(@states);  # inherit bignum from $max_len

  ### starting: $fa->get_starting
  ### @accepting
  foreach my $state ($fa->get_starting) { $counts[$state]++; }

  my @ret;
  foreach my $k (0 .. $max_len) {
    ### at: "k=$k  ".join(',',map{$_//'_'}@counts)." total ".sum(0,map{$_//0}@counts)." accepting ".sum(0,map{$counts[$_]//0}@accepting)

    push @ret, sum($max_len*0, map {$counts[$_]//0} @accepting);
    last if $k == $max_len;

    my @new_counts;
    foreach my $from_state (@states) {
      my $from_count = $counts[$from_state] || next;
      foreach my $symbol (@alphabet) {
        foreach my $to_state ($fa->successors($from_state, $symbol)) {
          ### add: "$from_count  $from_state -> $to_state"
          $new_counts[$to_state] += $from_count;
        }
      }
    }
    @counts = @new_counts;
  }
  return @ret;
}

#------------------------------------------------------------------------------
# FLAT temporary

sub minimize {
  my ($flat, %options) = @_;
  my $name = eval { $flat->{'name'} };
  if ($options{'verbose'}) {
    print "minimize ",$flat->{'name'}//''," ",$flat->num_states," states ...";
  }
  $flat = $flat->as_dfa;
  $flat = $flat->as_min_dfa;
  if ($options{'verbose'}) {
    print "done, num states ",$flat->num_states,"\n";
  }
  $flat->{'name'} = $name;
  return $flat;
}

# workaround for FLAT::DFA ->as_nfa() leaving itself blessed down in FLAT::DFA
sub as_nfa {
  my ($fa) = @_;
  $fa = $fa->as_nfa;
  if ($fa->isa('FLAT::DFA')) { bless $fa, 'FLAT::NFA'; }
  return $fa;
}
# workaround for FLAT::DFA ->reverse() infinite recursion, can reverse in NFA
sub reverse {
  my ($fa) = @_;
  if ($fa->isa('FLAT::DFA')) {
    $fa->MyFLAT::as_nfa($fa)->reverse->as_dfa;
  } else {
    $fa->reverse;
  }
}
# workaround for FLAT::DFA ->concat() infinite recursion, can reverse in NFA
sub concat {
  my $fa = shift @_;
  my $want_dfa = $fa->isa('FLAT::DFA');
  foreach my $f2 (@_) {
    $fa = $fa->MyFLAT::as_nfa->concat($f2->MyFLAT::as_nfa);
  }
  if ($want_dfa) {
    $fa = $fa->as_dfa;
  }
  return $fa;
}

#------------------------------------------------------------------------------
sub view {
  my ($fa) = @_;
  require MyGraphs;
  if ($fa->can('as_graphviz')) {   # in FLAT::FA, not in FLAT::Regex
    MyGraphs::graphviz_view($fa->as_graphviz);
  } else {
    print $fa->as_string;
  }
}
sub FLAT_to_perl_re {
  my ($fa) = @_;
  my $str = $fa->as_perl_regex;
  $str =~ s/\Q?://g;
  return $str;
}

sub FLAT_check_is_equal {
  my ($f1, $f2, %options) = @_;
  my @names = ($f1->{'name'} // 'first',
               $f2->{'name'} // 'second');
  if ($f1->equals($f2)) {
    print "$names[0] = $names[1], ok\n";
    return;
  }
  my $radix = $options{'radix'}
    // do { my @labels = $f1->alphabet; scalar(@labels) };
  print "$names[0] not equal $names[1]\n";
  foreach my $which (1, 2) {
    my $extra = $f1->as_dfa->difference($f2->as_dfa);
    print "extra in $names[0] over $names[1]\n";
    if ($extra->is_empty) {
      print "  is_empty()\n";
    } else {
      if ($extra->is_finite) {
        print "  is_finite()\n";
      }
      require Math::BaseCnv;

      if ($extra->contains('')) {
        print "  []  zero length string\n";
      }

      my $it = $extra->new_acyclic_string_generator;
      # my $it = $extra->new_deepdft_string_generator(20);
      my $count = 0;
      while (my $str = $it->()) {
        if (++$count > 20) {
          print "  ... and more\n";
          last;
        }
        my $n = Math::BaseCnv::cnv($str,$radix,10);
        print "  $str  N=$n\n";
      }
    }
    @names = CORE::reverse @names;
    ($f1,$f2) = ($f2,$f1);
  }
  exit 1;
}

sub FLAT_check_is_subset {
  my ($fsub, $fsuper) = @_;
  if (! $fsub->as_dfa->is_subset_of($fsuper->as_dfa)) {
    my $f = $fsub->as_dfa->difference($fsuper->as_dfa);
    my $it = $f->new_acyclic_string_generator;
    if (defined(my $sub_name = $fsub->{'name'})
        && defined(my $super_name = $fsuper->{'name'})) {
      print "$sub_name not subset of $super_name, ";
    }
    print "extras in supposed subset\n";
    my $count = 0;
    while (my $str = $it->()) {
      if (++$count > 20) {
        print "  ... and more\n";
        last;
      }
      print "  $str\n";
    }
    exit 1;
  }
  my $fsub_name = $fsub->{'name'} // 'subset';
  my $fsuper_name = $fsuper->{'name'} // 'superset';
  print "$fsub_name subset of $fsuper_name, ok\n";
}

sub FLAT_show_breadth {
  my ($flat, $width, $direction) = @_;
  $direction //= 'hightolow';
  if (defined (my $name = $flat->{'name'})) {
    print "$name ";
  }
  print "contains ($direction, by breadth)\n";
  if ($flat->is_empty) {
    print "  is_empty()\n";
  } elsif ($flat->is_finite) {
    print "  is_finite()\n";
  }
  my $count = 0;
  my $total = 0;

  my @alphabet = sort $flat->alphabet;
  my $radix = @alphabet;

  $total++;
  if ($flat->contains('')) {
    print "  [empty string]\n";
    $count++;
  }
  require Math::BaseCnv;
  foreach my $k (1 .. $width) {
    foreach my $n (0 .. $radix**$k-1) {
      my $str = Math::BaseCnv::cnv($n,10,$radix);
      $str = sprintf '%0*s', $k, $str;
      if ($direction eq 'lowtohigh') { $str = CORE::reverse $str; }
      $total++;
      if ($flat->contains($str)) {
        print "  $str  N=$n\n";
        $count++;
      }
    }
  }
  print "  count $count / $total\n";
}

sub FLAT_show_transitions {
  my ($flat,$str) = @_;
  my @str = split //, $str;
  my $print_states = sub {
    if (@_ == 0) {
      print "(none)";
      return;
    }
    my $join = '';
    foreach my $state (@_) {
      print $join, $state, $flat->is_accepting($state) ? "*" : '';
      $join = ',';
    }
  };
  foreach my $initial ($flat->get_starting) {
    my $state = $initial;
    $print_states->($state);
    foreach my $char (@str) {
      print " ($char)";
      my @next = $flat->successors($state,$char);
      if (! @next) {
        last;
      }
      $state = $next[0];
      print "-> ";
      $print_states->(@next);
    }
    print "\n";
  }
}
sub FLAT_check_accepting_remain_so {
  my ($flat) = @_;
  my @accepting = $flat->get_accepting;
  my @alphabet = $flat->alphabet;
  my $bad = 0;
  my $name = $flat->{'name'} // '';
  foreach my $state (@accepting) {
    foreach my $char (@alphabet) {
      my @next = $flat->successors($state,$char);
      foreach my $to (@next) {
        if (! $flat->is_accepting($to)) {
          print "$name $state ($char) -> $to is no longer accepting\n";
          $bad++;
        }
      }
    }
  }
  if ($bad) { exit 1; }
  print "$name accepting remain so, ok\n";
}

sub FLAT_show_acyclics {
  my ($flat) = @_;
  my $it = $flat->new_acyclic_string_generator;
  if (defined (my $name = $flat->{'name'})) {
    print "$name ";
  }
  print "acyclics\n";
  if ($flat->is_empty) {
    print "  empty\n";
  }
  my $count = 0;
  while (my $str = $it->()) {
    if (++$count > 8) {
      print "  ... and more\n";
      last;
    }
    print "  $str\n";
  }
}
sub FLAT_show_deep {
  my ($flat, $depth) = @_;
  my $it = $flat->new_deepdft_string_generator($depth // 5);
  print "depth $depth\n";
  my $count = 0;
  while (my $str = $it->()) {
    if (++$count > 8) {
      print "  ... and more\n";
      last;
    }
    print "  $str\n";
  }
}

#------------------------------------------------------------------------------

sub set_name {
  my ($flat, $name) = @_;
  $flat->{'name'} = $name;
  return $flat;
}

#------------------------------------------------------------------------------

=pod

=over

=item C<$new_fa = $fa-E<gt>digits_increment (key =E<gt> value, ...)>

C<$fa> is a C<FLAT::NFA> or C<FLAT::DFA> accepting digit strings.  Return a
new FLAT (same DFA or NFA) which accepts numbers +1.  Key/value options are

    add       => integer
    radix     => integer>=2
    direction => "lowtohigh" or "hightolow"

Option C<add =E<gt> $add> is the increment to apply (default 1).  This can
be negative too.

Option C<radix =E<gt> $radix> is the digit radix.  The default is taken from
the digits appearing in C<$fa-E<gt>alphabet> which is usually enough.  The
option can be used if C<$fa> might not have all digits appearing in its
alphabet.

Digit strings are taken as high to low.  Option C<direction =E<gt>
"lowtohigh"> takes them low to high instead.  Low to high is more efficient
here since manipulations are at the low end (add the increment and carry up
through low digits), but both work.

An increment can increase string length, for example 999 -E<gt> 1000.  If
there are high 0s on a string then the carry propagates into them and does
not change the length, so 00999 -E<gt> 01000.

Negative increments do not decrease string length, so 1000 -> 0999.  If
C<$add> reduces a number below 0 then that string is quietly dropped.

ENHANCE-ME: Maybe a width option to stay in given number of digits, discard
anything which would increment to bigger.  Or a wraparound option to ignore
carry above width for modulo radix^width.

ENHANCE-ME: Maybe decrement should trim a high 0 digit.  That would mean a
set of strings without high 0s remains so on decrement.  But if say infinite
high 0s are present then wouldn't want to remove them.  Perhaps when a
decrement goes to 0 it could be checked for an all-0s accepting state above,
and merge with it.

This function works by modifying the digits matched in C<$fa>, low to high.
For example if the starting state has a transition for low digit 4 then the
C<$new_fa> has starting state with transition for digit 5 instead.  At a
given state there is a certain carry to propagate.  At the starting states
this is C<$add>, and later it will be smaller.  Existing states are reckoned
as carry 0.  A new state is introduced for combinations of state and
non-zero carry reached.  Transitions in those new states are based on the
originals.  Where the original state has digit d the new state has (d+carry)
mod 10 and goes to the original successor and new_carry =
floor((4+carry)/10).  If that new_carry is zero then this is the original
successor state since the increment is now fully applied.  If new_carry is
non-zero then it's another new state for combination of state and carry.  In
a C<FLAT::NFA> any epsilon transitions are stepped across to find what
digits in fact occur at the given state.  In general an increment +1
propagates only up through digit 9s so that say 991 -> 002 (low to high).
Often C<$fa> might match only a few initial 9s and so only a few new states
introduced.

ENHANCE-ME: Could have some generality by reckoning the carry as an
arbitrary key or transform state, and go through $fa by a composition.  Any
such transformation can be made with a finite set of possible keys.

=back

=cut

sub digits_increment {
  my ($fa, %options) = @_;
  ### digits_increment() ...

  # starting state is flip
  # in flip 0-bit successor as a 1-bit, and thereafter unchanged
  #         1-bit successor as a 0-bit, continue flip

  my $direction = $options{'direction'} || 'hightolow';
  my $radix     = $options{'radix'} || max($fa->alphabet)+1;
  my $nine      = $radix-1;
  my $add       = $options{'add'} // 1;
  ### $radix
  ### $nine

  my $is_dfa = $fa->isa('FLAT::DFA');
  $fa = $fa->MyFLAT::as_nfa->clone;
  if ($direction eq 'hightolow') { $fa = $fa->reverse; }

  my %state_and_carry_to_new_state;
  require Tie::IxHash;
  tie %state_and_carry_to_new_state, 'Tie::IxHash';
  {
    # states reachable by runs of 9s from starting states
    my @pending = map {[$_,$add]} $fa->get_starting;
    while (my $elem = shift @pending) {
      my ($state, $carry) = @$elem;
      unless (exists $state_and_carry_to_new_state{"$state,$carry"}) {
        my ($new_state) = $fa->add_states(1);
        ### reach: "state=$state  new_state=$new_state carry=$carry"
        $state_and_carry_to_new_state{"$state,$carry"} = $new_state;
        if ($fa->is_starting($state) && $carry==$add) {
          $fa->set_starting($new_state);
          $fa->unset_starting($state);
        }

        foreach my $digit (0 .. $nine) {
          my ($new_carry,$new_digit) = _divrem($digit+$carry, $radix);
          if ($new_carry) {
            push @pending, map {[$_,$new_carry]}
              $fa->successors([$fa->epsilon_closure($state)],$digit);
          }
        }
      }
    }
  }
  ### %state_and_carry_to_new_state

  while (my ($state_and_carry, $new_state)
         = each %state_and_carry_to_new_state) {
    my ($state,$carry) = split /,/, $state_and_carry;
    ### setup: "state=$state carry=$carry   new_state=$new_state"

    foreach my $digit (0 .. $nine) {
      my ($new_carry,$new_digit) = _divrem($digit+$carry, $radix);
      foreach my $successor ($fa->successors([$fa->epsilon_closure($state)],
                                             $digit)) {
        my $new_successor
          = ($new_carry
             ? $state_and_carry_to_new_state{"$successor,$new_carry"}
             : $successor);
        ### digit: "state=$state carry=$carry digit=$digit successor $successor"
        ### new  : " new state $new_state new_digit=$new_digit with new_carry=$new_carry  new_successor=$new_successor"
        $fa->add_transition ($new_state, $new_successor, $new_digit);
      }
    }

    if ($carry > 0 && $fa->is_accepting($state)) {
      # 99...99 accepting becomes 00..00 1 accepting, with a new state for
      # the additional carry
      ### carry above accepting: "carry=$carry"
      my $from_state;
      while ($carry) {
        $from_state = $new_state;
        ($new_state) = $fa->add_states(1);
        ($carry, my $digit) = _divrem($carry, $radix);
        $fa->add_transition($from_state, $new_state, $digit);
        ### transition: "$from_state -> $new_state"
      }
      $fa->set_accepting($new_state);
      ### accepting: $new_state
    }
  }

  if (defined $fa->{'name'}) {
    $fa->{'name'} =~ s{\+(\d+)$}{'+'.($1+1)}e
      or $fa->{'name'} .= '+1';
  }

  if ($direction eq 'hightolow') { $fa = $fa->reverse; }
  if ($is_dfa) { $fa = $fa->as_dfa; }
  return $fa;
}

# sub successors_through_epsilon {
#   my ($fa, $state, $symbol) = @_;
#   return $fa->epsilon_closure($fa->successors($state,$symbol));
# }

sub _divrem {
  my ($n,$d) = @_;
  my $r = $n % $d;
  return (($n-$r)/$d, $r);
}

#------------------------------------------------------------------------------

=item C<$new_lang = $lang-E<gt>skip_initial ()>

=item C<$new_lang = $lang-E<gt>skip_final ()>

Return a new regular language object, of the same type as C<$lang>, which
matches the strings of C<$lang> with 1 initial or final symbol skipped.

A string of 1 symbol in C<$lang> becomes the empty string in C<$new_lang>.
The empty string in C<$lang> cannot have 1 symbol skipped so is ignored when
forming C<$new_lang>.

In a C<FLAT::FA>, C<skip_initial()> works by changing the starting states to
the immediate successors of the current starting states.  For a
C<FLAT::DFA>, if this results in multiple starts then they are converted to
a single start by the usual C<as_dfa()>.  C<skip_final()> works by changing
the accepting states to their immediate predecessors.

No minimization is performed.  It's possible changed starts might leave some
states unreachable.  It's possible changed accepting could leave various
states never reaching an accept.

ENHANCE-ME: maybe parameter $n to skip how many.

=back

=cut

#use Smart::Comments;

sub skip_initial {
  my ($fa) = @_;
  ### skip_initial(): $fa
  my $name = $fa->{'name'};
  my $is_dfa = $fa->isa('FLAT::DFA');

  $fa = $fa->MyFLAT::as_nfa->clone;    # need NFA for new multiple starts
  my @states = $fa->get_starting;
  $fa->unset_starting(@states);
  ### starting: @states
  $fa->set_starting($fa->successors([$fa->epsilon_closure(@states)]));
  ### new starting: [ $fa->get_starting ]

  if ($is_dfa) { $fa = $fa->as_dfa; }
  if (defined $name) {
    $name =~ s{ skip initial( (\d+))?$}{' skip initial '.(($2||0)+1)}e
      or $name .= ' skip initial';
    $fa->{'name'} = $name;
  }
  return $fa;
}

{
  package FLAT::Regex;
  sub MyFLAT_skip_initial {
    my $self = shift;
    $self->_from_op($self->op->MyFLAT_skip_initial(@_));
  }
  sub MyFLAT_skip_final {
    my $self = shift;
    $self->_from_op($self->op->MyFLAT_skip_final(@_));
  }
}
{
  package FLAT::Regex::Op::atomic;
  sub MyFLAT_skip_initial {
    my ($self) = @_;
    ### atomic MyFLAT_skip_initial: $self
    my $member = $self->members;
    return __PACKAGE__->new(defined $member && length($member)
                            ? ''      # symbol, becomes empty string
                            : undef); # empty str or null regex, becomes null
  }
  *MyFLAT_skip_final = \&MyFLAT_skip_initial;

  # return a list of the initial symbols accepted
  sub MyFLAT_initial_symbols {
    my ($self) = @_;
    my $member = $self->members;
    return (defined $member && length($member) ? $member : ());
  }
}
{
  package FLAT::Regex::Op::star;
  # skip_initial(X*) = skip_initial(X) X*
  # skip_final(X*)   = X* skip_final(X)
  # or if X has no non-empty strings then return has no non-empty
  sub MyFLAT_skip_initial {
    my ($self) = @_;
    my $member = $self->members;
    return ($member->has_nonempty_string
            ? FLAT::Regex::Op::concat->new($member->MyFLAT_skip_initial, $self)
            : $member);
  }
  sub MyFLAT_skip_final {
    my ($self) = @_;
    my $member = $self->members;
    return ($member->has_nonempty_string
            ? FLAT::Regex::Op::concat->new($self, $member->MyFLAT_skip_final)
            : $member);
  }

  # initial_symbols(X*) = initial_symbols(X)
  sub MyFLAT_initial_symbols {
    my ($self) = @_;
    return $self->members->MyFLAT_initial_symbols;
  }
}
{
  package FLAT::Regex::Op::concat;
  # skip_initial(X Y Z) = skip_initial(X) Y Z
  # skip_final(X Y Z)   = X Y skip_initial(Z)
  # any X, or Z, without a non-empty string is skipped
  sub MyFLAT_skip_initial {
    my ($self) = @_;
    my @members = $self->members;

    # skip initial members which are the empty string and nothing else
    while (@members >= 2 
           && ! $members[0]->is_empty
           && ! $members[0]->has_nonempty_string) {
      shift @members;
    }
    $members[0] = $members[0]->MyFLAT_skip_initial;
    return (ref $self)->new(@members);
  }
  sub MyFLAT_skip_final {
    my ($self) = @_;
    my @members = $self->members;
    # skip trailing members which are the empty string and nothing else
    while (@members >= 2
           && ! $members[-1]->is_empty
           && ! $members[-1]->has_nonempty_string) {
      pop @members;
    }
    $members[-1] = $members[-1]->MyFLAT_skip_final;
    return (ref $self)->new(@members);
  }

  # initial_symbols(X Y Z) = initial_symbols(X)
  # or whichever of X,Y,Z first has a non-empty string
  sub MyFLAT_initial_symbols {
    my $self = shift;
    my @ret;
    foreach my $member ($self->members) {
      @ret = $member->MyFLAT_initial_symbols and last;
    }
    return @ret;
  }
}
{
  package FLAT::Regex::Op::alt;
  # skip_initial(X | Y) = skip_initial(X) | skip_initial(Y)
  # skip_final(X | Y)   = skip_final(X)   | skip_final(Y)
  sub MyFLAT_skip_initial {
    my $self = shift;
    return $self->MyFLAT__map_method('MyFLAT_skip_initial',@_);
  }
  sub MyFLAT_skip_final {
    my $self = shift;
    return $self->MyFLAT__map_method('MyFLAT_skip_final',@_);
  }

  # initial_symbols(X|Y) = union(initial_symbols(X), initial_symbols(Y))
  sub MyFLAT_initial_symbols {
    my $self = shift;
    my %ret;
    foreach my $member ($self->members) {
      foreach my $symbol ($member->MyFLAT_initial_symbols) {
        $ret{$symbol} = 1;
      }
    }
    return keys %ret;
  }
}
{
  package FLAT::Regex::Op::shuffle;
  # can this be done better?
  sub MyFLAT__map_skip {
    my $self = shift;
    my $method = shift;
    my @members = $self->members;
    my @alts;
    foreach my $i (0 .. $#members) {
      if ($members[$i]->has_nonempty_string) {
        my @skip = @members;
        $skip[$i] = $skip[$i]->MyFLAT_skip_initial(@_);
        push @alts, __PACKAGE__->new(@skip);
      }
    }
    return (@alts
            ? FLAT::Regex::Op::alt->new (@alts)
            : FLAT::Regex::Op::atomic->new(undef))
  }
  sub MyFLAT_skip_initial {
    my $self = shift;
    return $self->MyFLAT__map_skip('MyFLAT_skip_final',@_);
  }
  sub MyFLAT_skip_final {
    my $self = shift;
    return $self->MyFLAT__map_skip('MyFLAT_skip_final',@_);
  }

  # wrong
  # sub MyFLAT_skip_initial {
  #   my $self = shift;
  #   my %initial;
  #   my @members = $self->members;
  #   foreach $member (@members) {
  #     my @symbols = $members[$i]->MyFLAT_initial_symbols or next;
  #     @initial{@symbols} = (); # hash slice
  #     $member = $member->MyFLAT_skip_initial(@_);  # mutate array
  #   }
  #   if (%initial) {
  # 
  #   return (%initial
  #           ? FLAT::Regex::Op::concat->new
  #           (FLAT::Regex::Op::alt->new
  #            (map {FLAT::Regex::Op::atomic->new($_)} keys %initial),
  #           __PACKAGE__->new(@members))
  # 
  #           : FLAT::Regex::Op::atomic->new(undef))
  # 
  #   return $self->MyFLAT__map_skip('MyFLAT_skip_final',@_);
  # }
}

sub skip_final {
  my ($fa, %options) = @_;
  my $name = $fa->{'name'};
  my $is_dfa = $fa->isa('FLAT::DFA');

  $fa = $fa->MyFLAT::as_nfa
    ->MyFLAT::reverse
    ->MyFLAT::skip_initial(%options)
    ->MyFLAT::reverse;
  if ($is_dfa) { $fa = $fa->as_dfa; }

  if (defined $name) {
    $name =~ s{ skip final( (\d+))?$}{' skip final '.(($1||0)+1)}e
      or $name .= ' skip final';
    $fa->{'name'} = $name;
  }
  return $fa;
}

#------------------------------------------------------------------------------

# $fa is a FLAT::NFA or FLAT::DFA which matches strings of bits.
# Return a new FLAT (same DFA or NFA) which accepts the same in base-4.
#
# MAYBE: a general transform of list of symbols -> single symbol
#
# lowtohigh or hightolow only affects how a high 0-bit 
#
sub binary_to_base4 {
  my ($fa, %options) = @_;
  my $direction = $options{'direction'} || 'hightolow';

  my $name = $fa->{'name'};
  my $is_dfa = $fa->isa('FLAT::DFA');

  if ($direction eq 'hightolow') { $fa = $fa->reverse; }
  my $new_fa = FLAT::DFA->new;

  my @state_to_new_state;
  my $state_to_new_state = sub {
    my ($state) = @_;
    my $new_state = $state_to_new_state[$state];
    if (! defined $new_state) {
      ($new_state) = $new_fa->add_states(1);
      ### $new_state
      $state_to_new_state[$state] = $new_state;
      if ($fa->is_accepting($state)) {
        $new_fa->set_accepting($new_state);
      }
    }
    return $new_state;
  };

  my @pending = $fa->get_starting;
  $new_fa->set_starting(map {$state_to_new_state->($_)}
                        $fa->epsilon_closure(@pending));

  my @state_done;
  while (@pending) {
    my $state = pop @pending;
    next if $state_done[$state]++;
    my $new_state = $state_to_new_state->($state);

    foreach my $bit0 (0,1) {
      my @successors = $fa->successors([$fa->epsilon_closure($state)],
                                       $bit0);
      foreach my $bit1 (0,1) {
        my @successors = $fa->successors([$fa->epsilon_closure(@successors)],
                                         $bit1);
        my $digit = $bit0 + 2*$bit1;
        foreach my $successor (@successors) {
          my $new_successor = $state_to_new_state->($successor);
          ### old: "bit0=$bit0 bit1=$bit1   $state to $successor"
          ### new: "digit=$digit   $new_state to $new_successor"
          $new_fa->add_transition($new_state, $new_successor, $digit);
          push @pending, $successor;
        }
      }
    }
  }
  if ($direction eq 'hightolow') { $new_fa = $new_fa->reverse; }

  if ($is_dfa) { $new_fa = $new_fa->as_dfa; }
  if (defined $name) {
    $name =~ s{ skip final( (\d+))?$}{' skip final '.(($2||0)+1)}e
      or $name .= ' base-4';
    $new_fa->{'name'} = $name;
  }
  return $new_fa;
}

# $fa is a FLAT::NFA or FLAT::DFA.
# Return a new FLAT (same DFA or NFA) which accepts blocks of $n many symbols.
#
# New symbols are string concatenation of the existing, so for example
# symbols a,b,c in blocks of 2 would have symbols aa,ab,ba,bb,etc.
#
# ENHANCE-ME: A separator string, or mapper func for blocks to new symbol.
#
sub blocks {
  my ($fa, $n, %options) = @_;

  my @alphabet = $fa->alphabet;
  my $num_symbols = scalar(@alphabet);
  my $num_blocks = $num_symbols ** $n;
  my @states = $fa->get_states;

  # clone with no transitions
  my $new_fa = (ref $fa)->new;
  $new_fa->add_states($fa->num_states);
  $new_fa->set_starting($fa->get_starting);
  $new_fa->set_accepting($fa->get_accepting);

  foreach my $state (@states) {
    ### $state
    foreach my $i (0 .. $num_blocks-1) {
      ### $i
      my $q = $i;
      my $block_symbol = '';
      my @successors = ($state);
      foreach (1 .. $n) {
        my $r = $q % $num_symbols;
        $q = ($q-$r) / $num_symbols;
        my $symbol = $alphabet[$r];
        $block_symbol .= $symbol;
        @successors = $fa->successors([$fa->epsilon_closure(@successors)],
                                      $symbol);
      }
      foreach my $successor (@successors) {
        ### new transition: "$state -> $successor label $block_symbol"
        $new_fa->add_transition($state, $successor, $block_symbol);
      }
    }
  }

  if (defined(my $name = $fa->{'name'})) {
    $name .= " blocks $n";
    $new_fa->{'name'} = $name;
  }
  return $new_fa;
}

#------------------------------------------------------------------------------
sub as_perl {
  my ($fa, %options) = @_;
  my $str = '';
  my $varname = $options{'varname'} // 'fa';
  $str .= "my \$$varname = " . ref($fa) . "->new;\n";
  my @states = sort {$a<=>$b} $fa->get_states;
  $str .= "\$$varname->add_states(" . scalar(@states) . ");\n";
  $str .= "\$$varname->set_starting(" . join(',',$fa->get_starting) . ");\n";
  $str .= "\$$varname->set_accepting(" . join(',',$fa->get_accepting) . ");\n";
  foreach my $from (@states) {
    foreach my $to (@states) {
      my $t = $fa->get_transition($from,$to) // next;
      my @symbols = map {"'$_'"} $t->alphabet;
      $str .= "\$$varname->add_transition($from,$to,".join(',',@symbols).");\n";
    }
  }
}
sub print_perl {
  my $fa = shift;
  print $fa->MyFLAT::as_perl(@_);
}


#------------------------------------------------------------------------------
1;
__END__
