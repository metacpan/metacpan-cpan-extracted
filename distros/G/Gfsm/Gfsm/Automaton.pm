package Gfsm::Automaton;
require Gfsm::Alphabet;

use IO::File;
use Carp;

##======================================================================
## Constants
##======================================================================
our $NULL = bless \(my $x=0), 'Gfsm::Automaton';
our $GV   = 'gv -spartan';
our $DOT  = 'dot';

##======================================================================
## I/O: Wrappers
##======================================================================

##--------------------------------------------------------------
## I/O: Wrappers: Binary

## $fsm_or_undef = $fsm->load($filename_or_fh);
## $fsm_or_undef = CLASS->load($filename_or_fh);
sub load {
  my ($fsm,$file) = @_;
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  if (!$fh) {
    carp(ref($fsm),"::load(): could not open file '$file': $!");
    return 0;
  }
  $fsm = $fsm->new() if (!ref($fsm));
  my $rc = $fsm->_load($fh);
  carp(ref($fsm),"::load(): error loading file '$file': $Gfsm::Error\n") if (!$rc);
  $fh->close() if (!ref($file));
  return $rc ? $fsm : undef;
}

## $fsm_or_undef = $fsm->save($filename_or_fh, $zlevel=-1);
sub save {
  my ($fsm,$file,$zlevel) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  if (!$fh) {
    carp(ref($fsm),"::save(): could not open file '$file': $!");
    return 0;
  }
  $zlevel = -1 if (!defined($zlevel));
  my $rc = $fsm->_save($fh,$zlevel);
  carp(ref($fsm),"::save(): error saving file '$file': $Gfsm::Error\n") if (!$rc);
  $fh->close() if (!ref($file));
  return $rc ? $fsm : undef;
}

##--------------------------------------------------------------
## I/O: Wrappers: Binary: strings

## $fsm_or_undef = $fsm->load_string($str)
## $fsm_or_undef = CLASS->load_string($str)
sub load_string {
  my $fsm = shift;
  $fsm = $fsm->new() if (!ref($fsm));
  my $rc = $fsm->_load_string(@_);
  return $rc ? $fsm : undef;
}

## $fsm_or_undef = $fsm->save_string($str)
sub save_string {
  my $fsm = shift;
  return $fsm->_save_string(@_) ? $fsm : undef;
}

## $str_or_undef = $fst->as_string()
sub as_string {
  my $fst = shift;
  my $str = '';
  return $fst->save_string($str) ? $str : undef;
}

##--------------------------------------------------------------
## I/O: Wrappers: Binary: Storable

## ($serialized, $ref1, ...) = $fsm->STORABLE_freeze($cloning)
sub STORABLE_freeze {
  my ($fsm,$cloning) = @_;
  #return $fsm->clone if ($cloning); ##-- weirdness

  my $buf = '';
  $fsm->save_string($buf)
    or croak(ref($fsm)."::STORABLE_freeze(): error saving to string: $Gfsm::Error\n");

  return ('',\$buf);
}

## $fsm = STORABLE_thaw($fsm, $cloning, $serialized, $ref1,...)
sub STORABLE_thaw {
  my ($fsm,$cloning) = @_[0,1];

  ##-- STRANGENESS (race condition on perl program exit)
  ##   + Storable already bless()d a reference to undef for us: this is BAD
  ##   + hack: set its value to 0 (NULL) so that DESTROY() ignores it
  $$fsm = 0;

  ##-- check for dclone() operations: weirdness here
  #if ($cloning) {
  #  $$fsm = ${$_[2]};
  #  ${$_[2]} = 0; ##-- and don't DESTROY() the clone...
  #  return;
  #}

  ##-- we must make a *real* new object: $fsmnew
  my $fsmnew = ref($fsm)->new();
  $$fsm    = $$fsmnew;
  $$fsmnew = 0;                ##-- ... but not destroy it...
  undef($fsmnew);

  ##-- now do the actual deed
  $fsm->load_string(${$_[3]})
    or croak(ref($fsm)."::STORABLE_thaw(): error loading from string: $Gfsm::Error\n");
}

##--------------------------------------------------------------
## I/O: Wrappers: Text

## $fsm_or_undef = $fsm->compile($filename_or_fh,%opts);
##  + %opts:
##     lower => $alphabet_lower,
##     upper => $alphabet_upper,
##     states => $alphabet_states,
sub compile {
  my ($fsm,$file,%opts) = @_;
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  if (!$fh) {
    carp(ref($fsm),"::compile(): could not open file '$file': $!");
    return 0;
  }
  $fsm = $fsm->new() if (!ref($fsm));
  my $rc = $fsm->_compile($fh,
			  ($opts{lower} ? $opts{lower} : ($opts{labels} ? $opts{labels} : $Gfsm::Alphabet::NULL)),
			  ($opts{upper} ? $opts{upper} : ($opts{labels} ? $opts{labels} : $Gfsm::Alphabet::NULL)),
			  ($opts{states} ? $opts{states} : $Gfsm::Alphabet::NULL));
  carp(ref($fsm),"::compile(): error compiling file '$file': $Gfsm::Error\n") if (!$rc);
  $fh->close() if (!ref($file));
  return $rc ? $fsm : undef;
}

## $fsm_or_undef = $fsm->print_att($filename_or_fh, %opts);
##  + %opts:
##     lower => $alphabet_lower,
##     upper => $alphabet_upper,
##     states => $alphabet_states,
sub print_att {
  my ($fsm,$file,%opts) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  if (!$fh) {
    carp(ref($fsm),"::print_att(): could not open file '$file': $!");
    return 0;
  }
  my $rc = $fsm->_print_att($fh,
			    ($opts{lower} ? $opts{lower} : ($opts{labels} ? $opts{labels} : $Gfsm::Alphabet::NULL)),
			    ($opts{upper} ? $opts{upper} : ($opts{labels} ? $opts{labels} : $Gfsm::Alphabet::NULL)),
			    ($opts{states} ? $opts{states} : $Gfsm::Alphabet::NULL));
  carp(ref($fsm),"::print_att(): error saving text file '$file': $Gfsm::Error\n") if (!$rc);
  $fh->close() if (!ref($file));
  return $rc;
}

## $fsm_or_undef = $fsm->compile_string($string, ?$abet_lo, ?$abet_hi, ?$abet_states);
sub compile_att_string {
  my $fsm = shift;
  $fsm = $fsm->new() if (!ref($fsm));
  return $fsm->_compile_string(@_) ? $fsm : undef;
}

## $fsm_or_undef = $fsm->print_att_string($string, ?$abet_lo, ?$abet_hi, ?$abet_states);
sub print_att_string {
  my $fsm = shift;
  return $fsm->_print_att_string(@_) ? $fsm : undef;
}

##--------------------------------------------------------------
## I/O: Wrappers: Draw

## $bool = $fsm->draw_vcg($filename_or_fh, %opts);
##  + %opts:
##     lower => $alphabet_lower,
##     upper => $alphabet_upper,
##     labels => $alphabet_lower_and_upper,
##     states => $alphabet_states,
##     title => $title,
##     xspace=>$xspace,
##     yspace=>$yspace,
##     orientation=>$orient,
##     state_shape=>$shape,
##     state_color=>$color,
##     final_color=>$color,
sub draw_vcg {
  my ($fsm,$file,%opts) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  if (!$fh) {
    carp(ref($fsm),"::draw_vcg(): could not open file '$file': $!");
    return 0;
  }
  my $rc = $fsm->_draw_vcg($fh,
			   ($opts{lower} ? $opts{lower} : ($opts{labels} ? $opts{labels} : $Gfsm::Alphabet::NULL)),
			   ($opts{upper} ? $opts{upper} : ($opts{labels} ? $opts{labels} : $Gfsm::Alphabet::NULL)),
			   ($opts{states} ? $opts{states} : $Gfsm::Alphabet::NULL),
			   ($opts{title} ? $opts{title} : "$fsm"),
			   (defined($opts{xspace}) ? $opts{xspace} : 40),
			   (defined($opts{yspace}) ? $opts{yspace} : 20),
			   ($opts{orientation} ? $opts{orientation} : 'left_to_right'),
			   ($opts{state_shape} ? $opts{state_shape} : 'box'),
			   ($opts{state_color} ? $opts{state_color} : 'white'),
			   ($opts{final_color} ? $opts{final_color} : 'lightgrey'));
  carp(ref($fsm),"::draw_vcg(): error saving text file '$file': $Gfsm::Error\n") if (!$rc);
  $fh->close() if (!ref($file));
  return $rc;
}


## $bool = $fsm->draw_dot($filename_or_fh, %opts);
##  + %opts:
##     lower => $alphabet_lower,
##     upper => $alphabet_upper,
##     labels => $alphabet_lower_and_upper,
##     states => $alphabet_states,
##     title => $title,
##     width=>$inches,
##     height=>$inches,
##     fontsize=>$points,
##     fontname=>$font,
##     portrait=>$bool,
##     vertical=>$bool,
##     nodesep=>$distance,
##     ranksep=>$distance,
sub draw_dot {
  my ($fsm,$file,%opts) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  if (!$fh) {
    carp(ref($fsm),"::draw_dot(): could not open file '$file': $!");
    return 0;
  }
  my $rc = $fsm->_draw_dot($fh,
			   ($opts{lower} ? $opts{lower} : ($opts{labels} ? $opts{labels} : $Gfsm::Alphabet::NULL)),
			   ($opts{upper} ? $opts{upper} : ($opts{labels} ? $opts{labels} : $Gfsm::Alphabet::NULL)),
			   ($opts{states} ? $opts{states} : $Gfsm::Alphabet::NULL),
			   ($opts{title} ? $opts{title} : "$fsm"),
			   ($opts{width} ? $opts{width}   : 0),
			   ($opts{height} ? $opts{height} : 0),
			   ($opts{fontsize} ? $opts{fontsize} : 14),
			   ($opts{fontname} ? $opts{fontname} : ''),
			   ($opts{portrait} ? $opts{portrait} : 1),
			   ($opts{vertical} ? $opts{vertical} : 0),
			   ($opts{nodesep} ? $opts{nodesep} : 0.25),
			   ($opts{ranksep} ? $opts{ranksep} : 0.40)
			  );
  carp(ref($fsm),"::draw_dot(): error saving text file '$file': $Gfsm::Error\n") if (!$rc);
  $fh->close() if (!ref($file));
  return $rc;
}


##======================================================================
## Visualization
##======================================================================

## undef = $fsm->viewps(%opts)
##   %opts: as for draw_dot()
##      bg => $bool, ##-- view in background
sub viewps {
  my ($fsm,%opts) = @_;
  my ($fh,$dotfilename,$psfilename);
  require File::Temp;
  ($fh,$dotfilename) = File::Temp::tempfile("gfsmXXXXX", SUFFIX=>'.dot', UNLINK=>1);
  $fh->close;
  if (!$fsm->draw_dot($dotfilename,%opts)) {
    carp(ref($fsm),"::viewps(): draw_dot(): Error\n");
    return;
  }
  $fh->close;
  ($fh,$psfilename) = File::Temp::tempfile("gfsmXXXXX", SUFFIX=>'.ps', UNLINK=>1);
  if (system("$DOT -Tps -o$psfilename $dotfilename")!=0) {
    carp(ref($fsm),"::viewps(): dot: Error: $!");
    return;
  }

  if ($opts{bg}) {
    system("$GV $psfilename &");
  }
  elsif (system("$GV $psfilename".($opts{bg} ? '&' : ''))!=0) {
    carp(ref($fsm),"::viewps(): gv: Error: $!");
    return;
  }
}


##======================================================================
## Algebra: Wrappers
##======================================================================

sub optional  { my $fsm=shift->clone; $fsm->_optional(@_); return $fsm;}
sub closure   { my $fsm=shift->clone; $fsm->_closure(@_); return $fsm;}
sub n_closure { my $fsm=shift->clone; $fsm->_n_closure(@_); return $fsm;}
sub complement { my $fsm=shift->clone; $fsm->_complement(@_); return $fsm;}
sub complete { my $fsm=shift->clone; $fsm->_complete(@_); return $fsm;}
sub compose_full {
  my ($fsm1,$fsm2,$fsmout) = @_;
  $fsmout = $fsm1->shadow() if (!$fsmout);
  $fsm1->_compose_full($fsm2, $fsmout);
  return $fsmout;
}
sub compose {my $fsm=shift->clone; $fsm->_compose(@_); return $fsm;}
sub concat { my $fsm=shift->clone; $fsm->_concat(@_); return $fsm;}
sub connect {my $fsm=shift->clone; $fsm->_connect(@_); return $fsm;}
sub determinize {
  my $nfa=shift;
  my $dfa = $nfa->shadow;
  $nfa->_determinize_full($dfa);
  return $dfa;
}
sub difference_full {
  my ($fsm1,$fsm2,$fsmout) = @_;
  $fsmout = $fsm1->shadow() if (!$fsmout);
  $fsm1->_difference_full($fsm2,$fsmout);
  return $fsmout;
}
sub difference {my $fsm=shift->clone; $fsm->_difference(@_); return $fsm;}
sub encode {
  my $fsm=shift->clone;
  my $key=shift;
  $key = defined($key) ? $key->clone : $fsm->shadow;
  $fsm->_encode($key,@_);
  return wantarray ? ($fsm,$key) : $fsm;
}
sub decode { my $fsm=shift->clone; $fsm->_decode(@_); return $fsm; }
sub intersect_full {
  my ($fsm1,$fsm2,$fsmout) = @_;
  $fsmout = $fsm1->shadow() if (!$fsmout);
  $fsm1->_intersect_full($fsm2,$fsmout);
  return $fsmout;
}
sub intersect {my $fsm=shift->clone; $fsm->_intersect(@_); return $fsm;}
sub invert   {my $fsm=shift->clone; $fsm->_invert(@_); return $fsm;}
sub minimize {my $fsm=shift->clone; $fsm->_minimize(@_); return $fsm; }
sub compact {my $fsm=shift->clone; $fsm->_compact(@_); return $fsm; }
sub product {my $fsm=shift->clone; $fsm->_product(@_); return $fsm;}
sub project {my $fsm=shift->clone; $fsm->_project(@_); return $fsm;}
sub reverse {my $fsm=shift->clone; $fsm->_reverse(@_); return $fsm;}
sub replace {my $fsm=shift->clone; $fsm->_reverse(@_); return $fsm;}
sub insert_automaton {
  my ($fsm1,$q1from,$q1to,$fsm2,$w) = @_;
  $w = Gfsm::Semiring->new($fsm1->semiring_type)->one if (!defined($w));
  $fsm1=$fsm1->clone;
  $fsm1->_insert_automaton($q1from,$q1to,$fsm2,$w);
  return $fsm1;
}
sub rmepsilon {my $fsm=shift->clone; $fsm->_rmepsilon(@_); return $fsm;}
sub union {my $fsm=shift->clone; $fsm->_union(@_); return $fsm;}

##======================================================================
## Lookup: Wrappers
##======================================================================

## $result = $fst->lookup($input)
## $result = $fst->lookup($input,$result)
## $result = $fst->lookup($input,$result,$max_states)
sub lookup {
  my ($fst,$input,$result,$maxq) = @_;
  $result  = $fst->shadow() if (!$result);
  $maxq  ||= 0;
  $fst->_lookup($input,$result,$maxq);
  return $result;
}

##-- list context:
## ($result,$statemap) = $fst->lookup_full($input)
## ($result,$statemap) = $fst->lookup_full($input,$result,$max_states)
##   + in scalar context, returns only $statemap
sub lookup_full {
  my ($fst,$input,$result,$maxq) = @_;
  $result = $fst->shadow() if (!$result);
  $maxq  ||= 0;
  my $map = $fst->_lookup_full($input,$result,$maxq);
  return wantarray ? ($result,$map) : $map;
}


## $trellis = $fst->lookup_viterbi($input)
## $trellis = $fst->lookup_viterbi($input,$trellis)
sub lookup_viterbi {
  my ($fst,$input,$trellis) = @_;
   $trellis = $fst->shadow() if (!$trellis);
  $fst->_lookup_viterbi($input,$trellis);
  return $trellis;
}

##======================================================================
## Paths: Wrappers
##======================================================================

#sub paths {
#  my ($fsm,$which) = @_;
#  return $fsm->paths(defined($which) ? $which : -1);
#}

##======================================================================
## Trie: Wrappers & aliases
##======================================================================
#*add_paths    = \&add_path;
#*find_prefixes = \&find_prefix;

##======================================================================
## Composition: low-level: DEPRECATED
##======================================================================

## $abet = $fsm->alphabet($which)
## $abet = $fsm->alphabet($which,$abet)
sub alphabet {
  my ($fsm,$which,$abet) = @_;
  $abet = Gfsm::Alphabet->new() if (!defined($abet));
  my $ai = Gfsm::ArcIter->new();
  my ($qid);
  foreach $qid (0..($fsm->n_states-1)) {
    for ($ai->open($fsm,$qid); $ai->ok; $ai->next) {
      if    ($which == $Gfsm::LSLower) { $abet->insert(''.$ai->lower,$ai->lower); }
      elsif ($which == $Gfsm::LSUpper) { $abet->insert(''.$ai->upper,$ai->upper); }
      else { #if ($which == $Gfsm::LSBoth)
	$abet->insert(''.$ai->lower,$ai->lower);
	$abet->insert(''.$ai->upper,$ai->upper);
      }
    }
  }
  return $abet;
}

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=pod

=head1 NAME

Gfsm::Automaton - object-oriented interface to libgfsm finite-state automata

=head1 SYNOPSIS

 use Gfsm;

 ##------------------------------------------------------------
 ## Constructors, etc.
 
 $fsm = Gfsm::Automaton->new();
 $fsm = Gfsm::Automaton->new($is_transducer,$srtype,$n_preallocated_states);
 
 $fsm2 = $fsm->clone();     # copy constructor
 $fsm2 = $fsm->shadow();    # copy non-structural elements
 $fsm2->assign($fsm1);      # assigns $fsm1 to $fsm2
 
 $fsm->clear();             # clear automaton structure

 ##------------------------------------------------------------
 ## Accessors/Manipulators: Properties
 
 $bool = $fsm->is_transducer();           # get 'is_transducer' flag
 $bool = $fsm->is_transducer($bool);      # ... or set it
 
 $bool = $fsm->is_weighted(?$bool);       # get/set 'is_weighted' flag
 $mode = $fsm->sort_mode(?$mode);         # get/set sort-mode flag (dangerous)
 $bool = $fsm->is_deterministic(?$bool);  # get/set 'is_deterministic' flag (dangerous)
 $srtype = $fsm->semiring_type(?$srtype); # get/set semiring type
 
 $n = $fsm->n_states();                   # get number of states
 $n = $fsm->n_final_states();             # get number of final states
 $n = $fsm->n_arcs();                     # get number of arcs
 
 $id = $fsm->root(?$id);                  # get/set id of initial state
 
 $bool = $fsm->has_state($id);            # check whether a state exists
 $bool = $fsm->is_cyclic();               # check for cyclicity

 ##------------------------------------------------------------
 ## Accessors/Manipulators: States
 $id = $fsm->add_state();                 # add a new state
 $id = $fsm->ensure_state($id);           # ensure that a state exists
 
 $fsm->remove_state($id);                 # remove a state from an FSM
 
 $bool = $fsm->is_final($id,?$bool);      # get/set final-flag for state $id
 
 $deg  = $fsm->out_degree($id);           # get number of outgoing arcs for state $id
 
 $w    = $fsm->final_weight($id,?$w);     # get/set final weight for state $id
 
 $fsm->renumber_states();                 # close gaps in stateid numbering
 $fsm->statesort_aff();			  # ... same thing
 $fsm->statesort_dfs();			  # depth-first state sort
 $fsm->statesort_bfs();			  # breadth-first state sort

 ##------------------------------------------------------------
 ## Accessors/Manipulators: Arcs
 
 $fsm->add_arc($fsm,$id_from,$id_to,$lab_lo,$lab_hi,$weight); # add an arc
 $fsm->arcsort($fsm,$mode);                                   # sort automaton arcs
 
 $ai = Gfsm::ArcIter->new();              # create new arc-iterator
 $ai = Gfsm::ArcIter->new($fsm,$stateid); # create & open
 
 $ai->open($fsm,$stateid);                # open outgoing arcs from $stateid in $fsm
 $ai->reset();                            # reset to 1st outgoing arc
 $ai->close();                            # close an arc iterator
 
 $bool = $ai->ok();                       # check iterator validity
 $ai->remove();                           # remove current arc from the automaton
 
 $stateid = $ai->target(?$stateid);       # get/set current arc target StateId
 $lab     = $ai->lower(?$lab);            # get/set current arc lower label
 $lab     = $ai->upper(?$lab);            # get/set current arc upper label
 $weight  = $ai->weight(?$weight);        # get/set current arc weight
 
 $ai->next();                             # increment to next outgoing arc
 $ai->seek_lower($lab);                   # (inclusive) seek next arc with lower label $lab
 $ai->seek_upper($lab);                   # (inclusive) seek next arc with upper label $lab
 $ai->seek_both($lo,$hi);                 # (inclusive) seek next arc with labels $lo,$hi

 ##--------------------------------------------------------------
 ## I/O
 
 $fsm_or_undef = $fsm->load($filename_or_handle);   # load binary file (class method ok)
 $fsm_or_undef = $fsm->save($filename_or_handle);   # save binary file
 
 $fsm_or_undef = $fsm->load_string($buffer);        # load from in-memory buffer $string (class method ok)
 $fsm_or_undef = $fsm->save_string($buffer);        # save to in-memory buffer $string
 
 $fsm_or_undef = $fsm->compile($filename_or_handle, %options);
         # compile AT&T-style text format file (transducer format only; class method ok)
 
 $fsm_or_undef = $fsm->print_att($filename_or_handle, %options);
         # save AT&T-style text format file (transducer format only)
 
 $fsm_or_undef = $fsm->compile_string($string, ?$abet_lo, ?$abet_hi, ?$abet_states);
         # compile AT&T-style text format $string (class method ok)
 
 $fsm_or_undef = $fsm->print_att_string($string, ?$abet_lo, ?$abet_hi, ?$abet_states);
         # save AT&T-style text format $string
 
 $bool = $fsm->draw_vcg($filename_or_handle,%options);  # save in VCG format
 $bool = $fsm->draw_dot($filename_or_handle,%options);  # save in DOT format
 
 $bool = $fsm->viewps(%options);                        # for debugging

 ##--------------------------------------------------------------
 ## Algebra (constructive)
 
 $fsm = $fsm1->optional();    # set optional
 $fsm = $fsm1->closure();     # reflexive + transitive closure
 $fsm = $fsm1->closure(1);    # transitive closure
 $fsm = $fsm1->n_closure($n); # n-ary closure
 
 $fsm = $fsm1->compact($rmeps);   # heuristic compaction (encoded minimization)
 
 $fsm = $fsm1->complement();      # lower complement wrt. internal alphabet
 $fsm = $fsm1->complement($abet); # lower complement wrt. alphabet $abet
 
 $sinkid = $fsm->complete($abet); # complete lower wrt. $abet, returns sink-state Id
 
 $fsm = $fsm1->compose($fsm2);    # transducer composition
 
 $fsm = $fsm1->concat($fsm2);     # concatenate automata
 
 $fsm = $fsm1->connect();         # remove non co-accessible states
 
 $fsm = $fsm1->determinize();     # acceptor determinization
 
 $fsm = $fsm1->difference($fsm2); # lower difference
 
 ($fsm,$key) = $fsm1->encode($key,$encode_labels,$encode_weights); # encode labels and/or weights
 $fsm        = $fsm1->decode($key,$decode_labels,$decode_weights); # ... or decode them
 
 $fsm = $fsm1->insert_automaton($qfrom,$qto,$fsm2,$w); # insert a whole automaton
 
 $fsm = $fsm1->intersect($fsm2);  # lower acceptor intersection
 
 $fsm = $fsm1->invert();          # invert transdcuer sides
 
 $fsm = $fsm1->minimize($rmeps);  # acceptor minimization
 
 $fsm = $fsm1->product($fsm2);    # compute Cartesian product of acceptors
 
 $fsm = $fsm1->project($side);    # project 1 side of a transducer
 
 $fsm = $fsm1->replace($lo,$hi,$fsm2);  # replace arcs over ($lo:$hi) with $fsm2 in $fsm1
 
 $fsm = $fsm1->rmepsilon();       # remove epsilon-arcs
 
 $fsm = $fsm1->union($fsm2);      # compute automaton union

 ##--------------------------------------------------------------
 ## Algebra ((pseudo-)destructive)
 
 $fsm->_closure();                # destructive closure
 #... etc.

 ##--------------------------------------------------------------
 ## Composition (low-level)
 
 $fsmout = $fsm1->compose_full($fsm2,$fsmout); # mid-level composition

 ##--------------------------------------------------------------
 ## Lookup
 
 $fsm = $fst->lookup($labs);                   # string+fst composition: $fsm=compose(id($labs),$fst)
 $fsm = $fst->lookup($labs,$fsm);              # ... specifying result fsm
 $fsm = $fst->lookup($labs,$fsm,$maxq);        # ... specifying result and result size limit
 
 ($fsm,$map) = $fst->lookup_full($labs);             # ... returning state-id map
 ($fsm,$map) = $fst->lookup_full($labs,$fsm);        # ... specifying result
 ($fsm,$map) = $fst->lookup_full($labs,$fsm,$maxq);  # ... specifying result and size limit
 $map        = $fst->lookup_full($labs,$fsm,$maxq);  # ... in scalar context returns only map.
 
 $trellis = $fst->lookup_viterbi($labs);  # Viterbi trellis construction

 ##--------------------------------------------------------------
 ## Serialization
 
 $paths = $fsm->paths();                  	# enumerate paths (non-cyclic $fsm only!)
 
 $paths = $trellis->viterbi_trellis_paths();    # enumerate Viterbi trellis paths
 $best  = $trellis->viterbi_trellis_bestpath(); # get best Viterbi trellis path
 
 $arcpaths = $fsm->arcpaths();               	# enumerate alignments (packed)
 @arcs = Gfsm::unpack_arcpath($arcpath);	# ... get all arcs in an arc-path
 ($q,$r,$lo,$hi,$w) = Gfsm::unpack_arc($arc);	# ... unpack a single arc

 ##--------------------------------------------------------------
 ## Tries
 
 $trie = Gfsm::Automaton->newTrie;
 
 $qid = $trie->add_path(\@lo,\@hi);
 $qid = $trie->add_path(\@lo,\@hi, $w);
 $qid = $trie->add_path(\@lo,\@hi, $w, $add_to_arcs, $add_to_state_final, $add_to_path_final);
 
 ($qid, $lo_i,$hi_i,$w_last) = $trie->find_prefix(\@lo,\@hi);
 
 $qids = $trie->add_path_states(\@lo,\@hi);
 $qids = $trie->add_path_states(\@lo,\@hi, $w);
 $qids = $trie->add_path_states(\@lo,\@hi, $w, $add_to_arcs, $add_to_state_final, $add_to_path_final);
 
 ($qids,$lo_i,$hi_i,$w_last) = $trie->find_prefix_states(\@lo,\@hi);
 
 $qid_to = $trie->find_arc_lower($qid_from, $lab_lo);  ##-- target state or Gfsm::noState()
 $qid_to = $trie->find_arc_upper($qid_from, $lab_hi);  ##-- target state or Gfsm::noState()
 
 $qid_to = $trie->get_arc_lower($qid_from, $lab_lo);   ##-- find or insert arc
 $qid_to = $trie->get_arc_upper($qid_from, $lab_hi);   ##-- find or insert arc

=head1 DESCRIPTION

Not yet written.

=cut

########################################################################
## FOOTER
########################################################################

=pod

=head1 BUGS AND LIMITATIONS

Probably many.

=head1 SEE ALSO

Gfsm(3perl),
gfsmutils(1).


=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2014 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
