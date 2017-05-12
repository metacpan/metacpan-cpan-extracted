package Gfsm::Automaton::Indexed;
require Gfsm::Automaton;
require Gfsm::Alphabet;

use IO::File;
use Carp;

##======================================================================
## Constants
##======================================================================
our $NULL = bless \(my $x=0), 'Gfsm::Automaton::Indexed';

##======================================================================
## I/O: Wrappers
##======================================================================

##--------------------------------------------------------------
## I/O: Wrappers: Binary

## $bool = $fsm->load($filename_or_fh);
sub load {
  my ($fsm,$file) = @_;
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  if (!$fh) {
    carp(ref($fsm),"::load(): could not open file '$file': $!");
    return 0;
  }
  my $rc = $fsm->_load($fh);
  carp(ref($fsm),"::load(): error loading file '$file': $Gfsm::Error\n") if (!$rc);
  $fh->close() if (!ref($file));
  return $rc;
}

## $bool = $fsm->save($filename_or_fh, $zlevel=-1);
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
  return $rc;
}

##--------------------------------------------------------------
## I/O: Wrappers: Binary: strings

## $bool = $fst->load_string($str)
## - XS

## $bool = $fst->save_string($str)
## $str_or_undef  = $fst->as_string()
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
## I/O: Wrappers: Draw

## $bool = $fsm->draw_vcg($filename_or_fh, %opts);
sub draw_vcg { $_[0]->to_automaton->draw_vg(@_[1..$#_]) }

## $bool = $fsm->draw_dot($filename_or_fh, %opts);
sub draw_dot { $_[0]->to_automaton->draw_dot(@_[1..$#_]) }

##======================================================================
## Visualization
##======================================================================

## undef = $fsm->viewps(%opts)
##   %opts: as for draw_dot()
##      bg => $bool, ##-- view in background
sub viewps { $_[0]->to_automaton->viewps(@_[1..$#_]) }



1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=pod

=head1 NAME

Gfsm::Automaton::Indexed - libgfsm finite-state automata, indexed

=head1 SYNOPSIS

 use Gfsm;

 ##------------------------------------------------------------
 ## Constructors, etc.

 $xfsm = Gfsm::Automaton::Indexed->new();
 $xfsm = Gfsm::Automaton::Indexed->new($is_transducer,$srtype,$n_states,$n_arcs);

 $xfsm2 = $xfsm->clone();     # copy constructor
 $xfsm2->assign($xfsm1);      # assigns $fsm1 to $fsm2

 $xfsm->clear();              # clear automaton structure


 ##--------------------------------------------------------------
 ## Import & Export

 $fsm  = $xfsm->to_automaton();   # convert Gfsm::Automaton::Indexed -> Gfsm::Automaton
 $xfsm = $fsm->to_indexed();      # convert Gfsm::Automaton -> Gfsm::Automaton::Indexed


 ##------------------------------------------------------------
 ## Accessors/Manipulators: Properties

 $bool = $xfsm->is_transducer();           # get 'is_transducer' flag
 $bool = $xfsm->is_transducer($bool);      # ... or set it

 $bool = $xfsm->is_weighted(?$bool);       # get/set 'is_weighted' flag
 $mode = $xfsm->sort_mode(?$mode);         # get/set sort-mode flag (dangerous)
 $bool = $xfsm->is_deterministic(?$bool);  # get/set 'is_deterministic' flag (dangerous)
 $srtype = $xfsm->semiring_type(?$srtype); # get/set semiring type

 $n = $xfsm->n_states();                   # get number of states
 $n = $xfsm->n_arcs();                     # get number of arcs

 $id   = $xfsm->root(?$id);                # get/set id of initial state
 $bool = $xfsm->has_state($id);            # check whether a state exists


 ##------------------------------------------------------------
 ## Accessors/Manipulators: States

 $id = $xfsm->add_state();                 # add a new state
 $id = $xfsm->ensure_state($id);           # ensure that a state exists

 $xfsm->remove_state($id);                 # remove a state from an FSM (currently does nothing)

 $bool = $xfsm->is_final($id,?$bool);      # get/set final-flag for state $id

 $deg  = $xfsm->out_degree($id);           # get number of outgoing arcs for state $id

 $w    = $xfsm->final_weight($id,?$w);     # get/set final weight for state $id


 ##------------------------------------------------------------
 ## Accessors/Manipulators: Arcs

 $fsm->arcsort($fsm,$mode);               # sort automaton arcs

 ##-- TODO: arc range iterator access!


 ##--------------------------------------------------------------
 ## I/O

 $bool = $xfsm->load($filename_or_handle);   # load binary file
 $bool = $xfsm->save($filename_or_handle);   # save binary file

 $bool = $xfsm->load_string($buffer);        # load from in-memory buffer $string
 $bool = $xfsm->save_string($buffer);        # save to in-memory buffer $string

 $bool = $xfsm->viewps(%options);            # for debugging (uses to_automaton())


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
Gfsm::Automaton(3perl),
gfsmutils(1).


=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
