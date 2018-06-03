### Introduction

The motivating application for learning to do this is related to problem of
generating valid strings given a deterministic finite automata (DFA), which is
a machine that can be described using pure regular expressions.

  
Normally these machines are used as string acceptors, but here I wanted to do
the opposite, and use them as string generators. I had recursive solutions,
but I wanted something that I could use as an actual iterator - i.e., produce
the next string and halt the execution until I wanted the next one.

  
The idea of string generation is not as intimidating as it seems (especially
if I am playing with it:) because the DFA can be taken as a directed graph
where the states are the nodes, and the transitions between states are the
edges. Each transition may have multiple labels (i.e., symbols), but this
fortunately does not make what I need to do any more difficult conceptually.

  
In order to find all paths that go from the start state (node) to an accepting
state, one may use a _depth first traversal_ (DFT) of the directed graph.
Using this method, a valid string is simply the concatenation of the symbols
labeling each edge in the _valid_ path. A path is valid if it is acyclic and
goes from the start state to some accepting state. A related method may find
_just_ the acyclic paths, but a DFT is also able to detect (and follow to a
certain depth) cycles.

  
I am familiar with implementing this as a recursive routine, and that works
fine when all I want is a dump of all strings. It doesn't work so well if I
want to create a real iterator that offers some control of the traversal's
execution. Some DFAs may also create a lot of strings depending on how "deep"
one wants to go, so it is not a good idea to have to generate a ton of strings
if all I want is a few.

### The Basic Solution

Conceptually, all that I really needed to do was to intercept the recursive
calls before they were made, push them onto my own call stack, then manage the
call stack in some way.

  
Using this scheme, an "iteration" consists of _pop'ing_ off the top most
anonymous subroutine, executing it, then pushing the set of resulting
anonymous subroutines back down the stack. If on a particular call a
terminating condition of the recursion is met, there are potentially no
subroutines returned.

  
It should be noted that iterators in general do not need to ensure an
exhausted call stack, but a recursive algorithm run indefinitely (like in a
while loop) will eventually halt. Because the caller is in control of the
execution stack, iterators are often used to control memory efficient infinite
data generators.

#### Recursive Iterator Generator Pseudo-code I

  1. initialize the call stack by making a call to the generator function; this will return 0 or more anonymous subroutines that have yet to be executed
  2. if a terminating condition is encountered, no subroutines will be returned
  3. while the stack is not empty pop a sub from the top of the stack, then execute it; this will return 0 or more subroutines; push these down the stack
  4. repeat this process for all levels until the stack has been exhausted

#### Recursive Iterator Generator Pseudo-code II

    
    # this function is not recursive; it is called once
    # and returns with the subroutine calls it /would have/
    # made had it be implicitly recursive
    
    sub get_sub (param1,...,paramN)
      # shift params, which are are assumed to data stucts refs
      initialize @retsubs = ()
      if terminating condition FALSE
        # create/modify params used in recursive call
        initialize new _param1 to some value;
        ...
        initialize _paramN to some value;
        loop to get set of next subs for next level of recursion
          push "sub {return get_sub(_param1,...,paramN);})" onto @retsubs;
        end loop
      endif 
      return {substack=>@retsubs,retval1=>'somevalue'};
    end get_sub
    
    # initialize call stack with first set of subs to call
    my @callstack = array of subs returned by get_sub(param1,...,paramN);
    
    # now execute the call stack until it's been exhausted
    while(@callstack) {
      pop next $sub off of @callstack;
      execute sub ref, $x = $sub->();
      push subs returned by get_sub(param1,...,paramN) onto @callstack;
    end while
    
    
    [[download]][1]

   [1]: http://www.0x743.com/?abspart=1;displaytype=displaycode;node_id=645222;part=2

In the above pseudo-code, it is important to note that the next level of
recursion is _never_ followed immediately. Control is returned back to the
caller once all of the next set of subs are generated. The return value is a
set of 0 or more newly manufactured subroutines that are ready to be pushed
onto the call stack.

  
These dynamically manufactured subroutines are no different than explicitly
declared subroutines except that during their creation, their input parameters
were _determined_. This is why we execute these manufactured subroutines with
out any parameters, for example $sub_ref->().

  
It is perfectly valid to have a manufactured subroutine accept run time
parameters, but more often this is unnecessary. It is merely an additional
dimension of flexibility one may add to these dynamically generated
subroutines.

    
    ...
      return sub { my $arg1 = shift; my $arg2 = shift; ... ;};
    ...
    
    
    [[download]][2]

   [2]: http://www.0x743.com/?abspart=1;displaytype=displaycode;node_id=645222;part=4

### What About Getting Actual Return Values?

Recursive functions are rarely useful if they do not return something to the
original caller. Fortunately, Perl allows us to return complex data
structures, so in this case we would return an anonymous hash where one field
contained the anonymous array of generated subroutines, and anything else that
needed to be returned could be contained in its own hash field.

  
This requires an extra step after each call from the top of the stack is made,
but it is a small price to pay for the convenience. For example, below we
return an anonymous hash reference with an array of subroutine references as
one of its members:

    
      my @subrefs = ();
      # loop, push sub refs onto @subrefs
        push (@subrefs,sub { ... });
      # end loop
    ...
      return { subref => @subrefs, val1 => 1, val2 => 'abc' };
    ...
    
    
    [[download]][3]

   [3]: http://www.0x743.com/?abspart=1;displaytype=displaycode;node_id=645222;part=5

and now we make the call and extract the proper values from the returned hash
ref.

    
    # make call
    my $caller = get_sub(...);
    # extract subrefs from the returned hash ref
    my @subrefs = @{$caller->{subrefs}};
    # push returned subs onto call stack
    push(@callstack,@subrefs);
    
    
    [[download]][4]

   [4]: http://www.0x743.com/?abspart=1;displaytype=displaycode;node_id=645222;part=6

### An Example Interface to My Implementation

This is not the implementation, but the interface to the iterator
implemenation. I show this first to illustrate what I was originally
envisioning. This code provides valid string generation via my hobby module,
[Perl FLaT][5], using both the [acyclic path and deep dft methods][6].

  
Example usage:

    
       [5]: http://www.0x743.com/flat
   [6]: http://www.0x743.com/flat/index.php?title=DFA_string_generation_techniques

#!/usr/bin/env perl

    use strict;
    use warnings;
    use FLAT::DFA;
    use FLAT::NFA;
    use FLAT::PFA;
    use FLAT::Regex::WithExtraOps;
    my $PRE = "abc&(def)*";
    my $dfa = FLAT::Regex::WithExtraOps->new($PRE)->as_pfa->as_nfa->as_dfa
    
    +->as_min_dfa->trim_sinks;
    my $next = $dfa->new_acyclic_string_generator;
    print "PRE: $PRE\n";
    print "Acyclic:\n";
    while (my $string = $next->()) {
      print "  $string\n";
    }
    $next = $dfa->new_deepdft_string_generator();
    print "Deep DFT (default):\n";
    for (1..10) {
     while (my $string = $next->()) {
       print "  $string\n";
       last;
      }
    }
    $next = $dfa->new_deepdft_string_generator(5);
    print "Deep DFT (5):\n";
    for (1..10) {
      while (my $string = $next->()) {
        print "  $string\n";
        last;
      }
    }
    
    
    
    [[download]][7]

   [7]: http://www.0x743.com/?abspart=1;displaytype=displaycode;node_id=645222;part=7

Outputs:

    
    PRE: abc&(def)*
    Acyclic:
      deabfc
      deabcf
      dabcef
      dabefc
      dabecf
      daebfc
      daebcf
      abc
      adbcef
      adbefc
      adbecf
      adebfc
      adebcf
    Deep DFT (default):
      deabfdcef
      deabfc
      deabcf
      deafbdcef
      deafbdecf
      deafbc
      deafdbcef
      deafdbefc
      deafdbecf
      dabcef
    Deep DFT (5):
      defdefdefdefdeabfdcef
      defdefdefdefdeabfdcefdef
      defdefdefdefdeabfdcefdefdef
      defdefdefdefdeabfdcefdefdefdef
      defdefdefdefdeabfdcefdefdefdefdef
      defdefdefdefdeabfdefdcef
      defdefdefdefdeabfdefdcefdef
      defdefdefdefdeabfdefdcefdefdef
      defdefdefdefdeabfdefdcefdefdefdef
      defdefdefdefdeabfdefdcefdefdefdefdef
    
    
    [[download]][8]

   [8]: http://www.0x743.com/?abspart=1;displaytype=displaycode;node_id=645222;part=8

### The Actual Implementation

For the full context of this code snippet, see the [full file][9].

    
       [9]: http://perl-flat.googlecode.com/svn/trunk/lib/FLAT/DFA.pm

sub get_acyclic_sub {

      my $self = shift;
      my ($start,$nodelist_ref,$dflabel_ref,$string_ref,$accepting_ref,$la
    
    +stDFLabel) = @_;
      my @ret = ();
      foreach my $adjacent (keys(%{$nodelist_ref->{$start}})) {
        $lastDFLabel++;
        if (!exists($dflabel_ref->{$adjacent})) {
          $dflabel_ref->{$adjacent} = $lastDFLabel;
          foreach my $symbol (@{$nodelist_ref->{$start}{$adjacent}}) { 
            push(@{$string_ref},$symbol);
              my $string_clone = dclone($string_ref);
            my $dflabel_clone = dclone($dflabel_ref);
            push(@ret,sub { return $self->get_acyclic_sub($adjacent,$nodel
    +ist_ref,$dflabel_clone,$string_clone,$accepting_ref,$lastDFLabel); })
    +; 
            pop @{$string_ref};
          }
        } 
     
      }
      return {substack=>[@ret],
              lastDFLabel=>$lastDFLabel,
              string => ($self->array_is_subset([$start],[@{$accepting_ref
    
    +}]) ? join('',@{$string_ref}) : undef)};
    }
    sub init_acyclic_iterator {
      my $self = shift;
      my %dflabel = (); 
      my @string  = (); 
      my $lastDFLabel = 0; 
      my %nodelist = $self->as_node_list(); 
      my @accepting = $self->get_accepting();
      # initialize
      my @substack = ();
      my $r = $self->get_acyclic_sub($self->get_starting(),\%nodelist,\%df
    +label,\@string,\@accepting,$lastDFLabel);
      push(@substack,@{$r->{substack}});
      return sub {
        while (1) {
          if (!@substack) {
            return undef;
          }
          my $s = pop @substack;
          my $r = $s->();
          push(@substack,@{$r->{substack}}); 
          if ($r->{string}) {
           return $r->{string};
          }
        }
      }
    }
    
    sub new_acyclic_string_generator {
      my $self = shift;
      return $self->init_acyclic_iterator();
    }
    
    
    
    [[download]][10]

   [10]: http://www.0x743.com/?abspart=1;displaytype=displaycode;node_id=645222;part=9

### Many Thanks To...

  * [Limbic~Region][11]
  * [ikegami][12]
  * [blokhead][13]

   [11]: http://www.0x743.com/?node=Limbic~Region
   [12]: http://www.0x743.com/?node=ikegami
   [13]: http://www.0x743.com/?node=blokhead

### Feedback

I welcome feedback of all kinds, so please feel free - especially if you
notice an problem anywhere :).
