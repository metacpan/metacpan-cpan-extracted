package Gfsm::XL::Cascade::Lookup;

use IO::File;
use Carp;

##======================================================================
## Constants
##======================================================================
our $NULL = bless \(my $x=0), 'Gfsm::XL::Cascade::Lookup';

##======================================================================
## Attributes: Wrappers
##======================================================================

BEGIN {

  ## _wrap_attribute($attrName)
  ##  + defines sub "$attrName()" for get/set
  sub _wrap_attribute {
    my $attr = shift;
    eval
    "sub $attr {
      \$_[0]->_${attr}_set(\@_[1..\$#_]) if (\$#_ > 0);
      return \$_[0]->_${attr}_get();
     }";
  }

  _wrap_attribute('cascade');
  _wrap_attribute('max_weight');
  _wrap_attribute('max_paths');
  _wrap_attribute('max_ops');
  _wrap_attribute('n_ops');
}

##======================================================================
## Operation
##======================================================================

## $result = $cl->lookup_nbest($input)
## $result = $cl->lookup_nbest($input,$result)
*lookup = \&lookup_nbest;
sub lookup_nbest {
  my ($cl,$input,$result) = @_;
  $result = Gfsm::Automaton->new() if (!$result);
  $cl->_lookup_nbest($input,$result);
  return $result;
}

## \@paths = $cl->lookup_nbest_paths($input)
*lookup_paths = \&lookup_nbest_paths;

##======================================================================
## Operation
##======================================================================

##--------------------------------------------------------------
## I/O: Wrappers: Binary: Storable

## ($serialized, $ref1, ...) = $cl->STORABLE_freeze($cloning)
sub STORABLE_freeze {
  my ($cl,$cloning) = @_;
  #return $cl->clone if ($cloning); ##-- weirdness

  ## $saveref = { cascade=>$csc, max_weight=>$w, ... }
  my $saveref = { map { ($_=>$cl->can($_)->($cl)) } qw(cascade max_weight max_paths max_ops n_ops) };
  return ('',$saveref);
}

## $cl = STORABLE_thaw($cl, $cloning, $serialized, $ref1,...)
sub STORABLE_thaw {
  my ($cl,$cloning) = @_[0,1];

  ##-- STRANGENESS (race condition on perl program exit)
  ##   + Storable already bless()d a reference to undef for us: this is BAD
  ##   + hack: set its value to 0 (NULL) so that DESTROY() ignores it
  $$cl = 0;

  ##-- check for dclone() operations: weirdness here
  #if ($cloning) {
  #  $$cl = ${$_[2]};
  #  ${$_[2]} = 0; ##-- and don't DESTROY() the clone...
  #  return;
  #}

  ##-- we must make a *real* new object: $clnew
  my $clnew = ref($cl)->new(undef);
  $$cl    = $$clnew;
  $$clnew = 0;                ##-- ... but not destroy it...
  undef($clnew);

  ##-- now do the actual deed
  my $ref = $_[3];
  foreach (keys(%$ref)) {
    $cl->can($_)->($cl,$ref->{$_}) if ($cl->can($_));
  }

  return $cl;
}

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=pod

=head1 NAME

Gfsm::XL::Cascade::Lookup - libgfsmxl finite-state cascade lookup routines

=head1 SYNOPSIS

 use Gfsm;
 use Gfsm::XL;

 ##------------------------------------------------------------
 ## Constructors, etc.

 $cl  = Gfsm::XL::Cascade::Lookup->new($max_weight, $max_paths, $max_ops);

 ##--------------------------------------------------------------
 ## Attributes

 $csc = $cl->cascade();		##-- get underlying cascade
 $csc = $cl->cascade($csc);	##-- set underlying cascade

 $w = $cl->max_weight(?$w);	##-- get/set max weight (-1 for none)
 $n = $cl->max_paths(?$n);	##-- get/set max number of paths (-1 for none)
 $n = $cl->max_ops(?$n);	##-- get/set max number of heap extractions (-1 for none)
 $n = $cl->n_ops();		##-- get number of heap extractions for last run

 ##--------------------------------------------------------------
 ## Lookup

 $fst   = $cl->lookup(\@ilabs,?$result); ##-- n-best lookup (FST)
 $paths = $cl->lookup_paths(\@ilabs);	 ##-- n-best lookup (paths)

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
