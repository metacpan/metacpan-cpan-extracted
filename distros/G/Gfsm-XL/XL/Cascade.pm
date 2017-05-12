package Gfsm::XL::Cascade;

use IO::File;
use Carp;

##======================================================================
## Constants
##======================================================================
our $NULL = bless \(my $x=0), 'Gfsm::XL::Cascade';

##======================================================================
## Manipulation: Wrappers
##======================================================================

## $indexed = _ensure_indexed($fsm_or_xfsm)
sub _ensure_indexed {
  return UNIVERSAL::isa(ref($_[0]),'Gfsm::Automaton::Indexed') ? $_[0] : $_[0]->to_indexed();
}

## $csc = $csc->append(@fsms_or_xfsms)
sub append {
  my $csc   = shift;
  my @xfsms = map {_ensure_indexed($_)} @_;
  foreach (@xfsms) {
    $_->arcsort($Gfsm::ACLower) if (Gfsm::acmask_nth($_->sort_mode,0) != $Gfsm::ACLower);
  }
  $csc->_append(@xfsms);
  return $csc;
}

## @xfsms = $csc->get_all()
sub get_all {
  my $csc = shift;
  return map { $csc->get($_) } (0..($csc->depth-1));
}

## $old_nth = $csc->set($nth, $xfsm_or_fsm)
sub set {
  my $csc   = shift;
  my $xfsm  = _ensure_indexed($_[1]);
  $xfsm->arcsort($Gfsm::ACLower) if (Gfsm::acmask_nth($xfsm->sort_mode,0) != $Gfsm::ACLower);
  return $csc->_set($_[0],$xfsm);
}

##======================================================================
## I/O: Wrappers
##======================================================================

##--------------------------------------------------------------
## I/O: Wrappers: Binary

## $bool = $csc->load($filename_or_fh);
sub load {
  my ($csc,$file) = @_;
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  if (!$fh) {
    carp(ref($csc),"::load(): could not open file '$file': $!");
    return 0;
  }
  my $rc = $csc->_load($fh);
  carp(ref($csc),"::load(): error loading file '$file': $Gfsm::Error\n") if (!$rc);
  $fh->close() if (!ref($file));
  return $rc;
}

## $bool = $csc->save($filename_or_fh, $zlevel=-1);
sub save {
  my ($csc,$file,$zlevel) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  if (!$fh) {
    carp(ref($csc),"::save(): could not open file '$file': $!");
    return 0;
  }
  $zlevel = -1 if (!defined($zlevel));
  my $rc = $csc->_save($fh,$zlevel);
  carp(ref($csc),"::save(): error saving file '$file': $Gfsm::Error\n") if (!$rc);
  $fh->close() if (!ref($file));
  return $rc;
}

##--------------------------------------------------------------
## I/O: Wrappers: Binary: strings

## $bool = $csc->load_string($str)
## - XS

## $bool = $csc->save_string($str)
## $str_or_undef  = $csc->as_string()
sub as_string {
  my $csc = shift;
  my $str = '';
  return $csc->save_string($str) ? $str : undef;
}

##--------------------------------------------------------------
## I/O: Wrappers: Binary: Storable

## ($serialized, $ref1, ...) = $csc->STORABLE_freeze($cloning)
sub STORABLE_freeze {
  my ($csc,$cloning) = @_;
  #return $csc->clone if ($cloning); ##-- weirdness

  my $buf = '';
  $csc->save_string($buf)
    or croak(ref($csc)."::STORABLE_freeze(): error saving to string: $Gfsm::Error\n");

  return ('',\$buf);
}

## $csc = STORABLE_thaw($csc, $cloning, $serialized, $ref1,...)
sub STORABLE_thaw {
  my ($csc,$cloning) = @_[0,1];

  ##-- STRANGENESS (race condition on perl program exit)
  ##   + Storable already bless()d a reference to undef for us: this is BAD
  ##   + hack: set its value to 0 (NULL) so that DESTROY() ignores it
  $$csc = 0;

  ##-- check for dclone() operations: weirdness here
  #if ($cloning) {
  #  $$csc = ${$_[2]};
  #  ${$_[2]} = 0; ##-- and don't DESTROY() the clone...
  #  return;
  #}

  ##-- we must make a *real* new object: $cscnew
  my $cscnew = ref($csc)->new();
  $$csc    = $$cscnew;
  $$cscnew = 0;                ##-- ... but not destroy it...
  undef($cscnew);

  ##-- now do the actual deed
  $csc->load_string(${$_[3]})
    or croak(ref($csc)."::STORABLE_thaw(): error loading from string: $Gfsm::Error\n");
}

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=pod

=head1 NAME

Gfsm::XL::Cascade - object-oriented interface to libgfsmxl finite-state cascades

=head1 SYNOPSIS

 use Gfsm;
 use Gfsm::XL;

 ##------------------------------------------------------------
 ## Constructors, etc.

 $csc = Gfsm::XL::Cascade->new();
 $csc = Gfsm::XL::Cascade->new($depth, $srtype);

 $csc->clear();             # clear cascade

 ##------------------------------------------------------------
 ## Accessors/Manipulators: Properties

 $csc   = $csc->append(@fsms);            # append a Gfsm::Automaton::Indexed (by reference if possible)
 $xfsm  = $csc->get($n);                  # retrieve reference to $n-th automaton in the cascade (indexed)
 @xfsms = $csc->get_all();                # retrieve list of references to all automata in cascade
 $xold  = $csc->set($n,$fsm);		  # set the $n-th automaton in the cascade; returns old $n-th automaton
 $xold  = $csc->pop();            	  # pop the deepest automaton in the cascade

 $depth  = $csc->depth();                 # get cascade depth
 $srtype = $csc->semiring_type(?$srtype); # get/set semiring type

 $csc->sort_all($sort_mask);              # sort all automata in cascade

 ##--------------------------------------------------------------
 ## I/O

 $bool = $csc->load($filename_or_handle);   # load binary file
 $bool = $csc->save($filename_or_handle);   # save binary file

 $bool = $csc->load_string($buffer);        # load from in-memory buffer $string
 $bool = $csc->save_string($buffer);        # save to in-memory buffer $string

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

Copyright (C) 2005-2012 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
