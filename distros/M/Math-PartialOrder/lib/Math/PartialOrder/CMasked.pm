# -*- Mode: Perl -*-

#
# Copyright (c) 2001, Bryan Jurish.  All rights reserved.
#
# This package is free software.  You may redistribute it
# and/or modify it under the same terms as Perl itself.
#

###############################################################
#
#      File: Math::PartialOrder::CMasked.pm
#    Author: Bryan Jurish <jurish@ling.uni-potsdam.de>
#
# Description: Compilingt Math::PartialOrder class using
#              Bit::Vector objects to store hierarchy information,
#              internal storage of parents/children as 'Enum' strings.
#
###############################################################


package Math::PartialOrder::CMasked;
# System modules
use Carp;
require Exporter;
# 3rd party exstensions
use Bit::Vector;
# user extension modules
use Math::PartialOrder::Base;
use Math::PartialOrder::Loader qw(:trvars);
@ISA       = qw(Math::PartialOrder::Base);
@EXPORT    = qw();
@EXPORT_OK = (
	      qw($INITIAL_VECTOR_SIZE $VECTOR_GROW_STEP),
	      qw(%BIN_COMPAT &_get_bin_compat $_tr_index),
	      qw(&_bv_make_comparable &_bv_ensure_size
		 &_bv_bit_test &_bv_bit_on &_bv_bit_off
		 &_bv_union_d &_bv_intersection_d &_bv_difference_d),
	      qw(&_enum2indices &_enum_bit_test &_enum_bit_on &_enum_bit_off
		 &_enum_union &_enum_intersection &_enum_difference),
	     );
%EXPORT_TAGS =
  (
   sizevars => [qw($INITIAL_VECTOR_SIZE $VECTOR_GROW_STEP)],
   bincompat => [qw(%BIN_COMPAT &_get_bin_compat $_tr_index)],
   bvutils => [qw(&_bv_make_comparable &_bv_ensure_size
		  &_bv_bit_test &_bv_bit_on &_bv_bit_off
		  &_bv_union_d &_bv_intersection_d &_bv_difference_d)],
   enumutils => [qw(&_enum2indices &_enum_bit_test &_enum_bit_on &_enum_bit_off
		    &_enum_union &_enum_intersection &_enum_difference)],
  );


###############################################################
# Package Variables
###############################################################

our $VERSION = 0.01;

our $INITIAL_VECTOR_SIZE = 32;
our $VECTOR_GROW_STEP = 32;

# for storage/binary compatibility
our %BIN_COMPAT =
  (
   Math::PartialOrder::CMasked => 0.01,
   Math::PartialOrder::CEnum => 0.01,
   QuD::Hierarchy::CMasked => 0.03,
   QuD::Hierarchy::CEnum => 0.04,
   QuD::Hierarchy::CVec => 0.02,
  );
our $_tr_index = 3;


###############################################################
# Initialization
#   + object structure:
#     {
#       indices     => { Type0 => Index0, ... }
#       types       => [ Type0, Type1, ... ]
#       root        => scalar type-name
#       parents     => [ Type0Parents, Type1Parents, ... ]
#       children    => [ Type0Children, Type1Children, ... ]
#       attributes  => [ { attr1.1 => val1.1, ... }, ... ]
#       removed     => [ FirstFreeIndex, SecondFreeIndex, ... ]
#       vectors     => [ Bit::Vector0, Bit::Vector1 ]
#       ancestors   => [ Type0Ancs, Type1Ancs, ... ]  #-- Ancs are Bit::Vectors!
#       descendants => [ Type0Decs, Type1Decs, ... ]  #-- Decs are Bit::Vectors!
#       compiled    => scalar boolean
#       hattributes => { a1 => v1, ... }
#     }
###############################################################
#----------------------------------------------------------------------
# new( {root=>$r} )
#----------------------------------------------------------------------
sub new ($;$) {
  my $proto = shift;
  my $args = shift;
  my $self = bless {
		    indices => {},
		    types => [],
		    root => undef,
		    parents => [],
		    children => [],
		    attributes => [],
		    removed => [],
		    vectors =>
		    [
		     Bit::Vector->new($INITIAL_VECTOR_SIZE), # [0]: vector(0)
		     Bit::Vector->new($INITIAL_VECTOR_SIZE), # [1]: vector(1)
		    ],
		    # --- new ---
		    ancestors => [],
		    descendants => [],
		    compiled => 0,
		    hattributes => {}
		   }, ref($proto)||$proto;
  # root node
  $self->_root($args->{root}||'BOTTOM');
  return $self;
}



#--------------------------------------------------------------
sub compile ($) {
  my $self = shift;

  # variables
  my $size = $self->_size;
  my $ancs = $self->{ancestors};
  my $dscs = $self->{descendants};
  my ($i);

  $self->_ensure_vector_sizes();
  my ($psv, $csv) = @{$self->{vectors}};   # working vectors
  my ($pse,$cse);                          # enums
  my ($j,$jmin,$jmax);                     # interval-indices
  my $q = Bit::Vector->new($psv->Size);    # queue as a bit-vector
  my $hv = Bit::Vector->new($psv->Size);   # hierarchy-vector

  # tc-encoding masks: initialization
  for ($i = 0; $i < $size; ++$i) {
    next unless (exists($self->{types}[$i]));
    # initialize ancestors
    if (exists($ancs->[$i])) {
      _bv_ensure_size($ancs->[$i], $psv->Size);
      $ancs->[$i]->Empty;
    } else {
      $ancs->[$i] = $psv->Shadow; # new empty vector, same size
    }
    # intialize descendants
    if (exists($dscs->[$i])) {
      _bv_ensure_size($dscs->[$i], $psv->Size);
      $dscs->[$i]->Empty;
    } else {
      $dscs->[$i] = $psv->Shadow
    }
  }

  $hv->Fill;
  $hv->Index_List_Remove(@{$self->{removed}});

  $q->Bit_On($self->_indices->{$self->{root}});
  while (!$q->is_empty) {
    $i = $q->Min;
    $q->Bit_Off($i);

    $pse = $self->{parents}[$i];
    $cse = $self->{children}[$i];

    $psv->from_Enum($pse || '');
    $csv->from_Enum($cse || '');

    # sanity-check
    if (($ancs->[$i]->equal($hv) && $cse) || ($dscs->[$i]->equal($hv) && $pse))
      {
	carp("PartialOrder compilation error: circularity detected for type `$t'");
	$self->decompile;
	return 0;
      }

    if ($cse) {
      $ancs->[$i]->Union($ancs->[$i],$psv);
      $dscs->[$i]->Union($dscs->[$i],$csv);

      # propagate all known ancestors to direct descendants
      foreach ($csv->Index_List_Read) {
	$ancs->[$_]->Union($ancs->[$_], $ancs->[$i]);
	$ancs->[$_]->Bit_On($i);
      }

      # propagate (direct) descendants to all known ancestors
      $j = 0;
      while ($j <= $size && (($jmin,$jmax) = $ancs->[$i]->Interval_Scan_inc($j)))
	{
	  for ($j = $jmin; $j <= $jmax; ++$j) {
	    $dscs->[$j]->Union($dscs->[$j], $dscs->[$i]);
	  }
	  $j = $jmax + 2;
	}
      # ...and keep going
      $q->Union($q,$csv);
    }
  }
  return $self->_compiled(1);
}

#--------------------------------------------------------------
sub decompile ($) {
  @{$_[0]->{ancestors}} = qw();
  @{$_[0]->{descendants}} = qw();
  return $_[0]->{compiled} = 0;  # and set the compiled-flag
}
*uncompile = \&decompile;


#--------------------------------------------------------------
# $bool = compiled(), compiled($bool)
sub compiled ($;$) {
  return $_[0]->{compiled} unless (exists($_[1]));
  if ($_[1]) {
    # do compile
    return $_[0]->compile unless ($_[0]->{compiled});
    return 1; # we're already compiled...
  }
  return $_[0]->decompile if ($_[0]->{compiled});
  return 0;
}



###############################################################
# Hierarchy Maintainance: Type Operations
###############################################################

#--------------------------------------------------------------
# @types = $h->types()
sub types ($) { return grep { defined($_) } @{$_[0]->{types}}; }

#--------------------------------------------------------------
# $h = $h->add($t,@ps)
sub add {
  my $self = shift;
  my $type = shift;

  # sanity checks
  return $self->move($type, @_) if ($self->has_type($type));
  unless (defined($type)) {
    carp("Undefined type not supported in ".ref($self)."::add()");
    return $self;
  }
  $self->{compiled} = 0;

  # add this type
  my $i = $self->_next_index();
  $self->{types}[$i] = $type;
  $self->{indices}{$type} = $i;

  # ensure parents are well-defined & well-placed
  @_ = $self->ensure_types(@_);

  # set parents-relation for new $type
  $self->_ensure_vector_sizes();
  $self->{parents}[$i] = $self->_types2enum(@_);

  # set children-relation for new $type
  my $kids = $self->{children};
  $kids->[$i] = '';
  foreach (@{$self->{indices}}{@_}) {
    if ($kids->[$_]) { $kids->[$_] .= ",$i"; }
    else { $kids->[$_] = $i; }
  }
  return $self;
}



#--------------------------------------------------------------
# $bool = $h->has_type($t)
sub has_type ($$) {
  return
    defined($_[1]) &&
    defined($_[0]->{indices}{$_[1]}) &&
    defined($_[0]->{types}[$_[0]->{indices}{$_[1]}]);
}


#--------------------------------------------------------------
# $h = $h->add_parents($t,@ps)
sub add_parents ($$@) {
  my $self = shift;
  my $type = shift;

  # sanity check(s)
  return $self->add($type,@_) unless ($self->has_type($type));
  unless (defined($type)) {
    carp("Undefined type not supported in ".ref($self)."::add_parents()");
    return $self;
  }
  $self->compiled(0);

  my $i = $self->{indices}{$type};

  # ensure parents are well-defined & well-placed
  @_ = $self->ensure_types(@_);

  # ensure that our vectors can handle this
  $self->_ensure_vector_sizes();

  # set parents-relation for new $type
  $self->{parents}[$i] =
    _enum_union($self->{parents}[$i],
		join(',',@{$self->{indices}}{@_}),
		@{$self->{vectors}}[0..1]);

  # set children-relation for new $type
  my $kids = $self->{children};
  foreach (@{$self->{indices}}{@_}) {
    $kids->[$_] = _enum_bit_on($kids->[$_], $i, $self->{vectors}[0]);
  }
  return $self;
}


#--------------------------------------------------------------
# $h = $h->replace($old,$new)
sub replace ($$$) {
  my ($h, $old, $new) = @_;
  unless (defined($old)) {
    carp("Undefined type not supported in ".ref($self)."::replace()");
    return $h;
  }
  my $i = $h->{indices}{$old};
  return $h->add($new,$h->{root}) unless (defined($i));
  $h->{indices}{$new} = $i;
  $h->{types}[$i] = $new;
  if ($old eq $h->{root}) { $h->{root} = $new; }
  return $h;
}

#--------------------------------------------------------------
# $h = $h->move($t,@ps)
sub move ($$@) {
  my $self = shift;
  my $type = shift;

  # sanity check(s)
  if (!defined($type)) {
    carp("Undefined type not supported in ".ref($self)."::move()");
    return $h;
  }
  if ($type eq $self->{root}) {
    if (@_) { croak("Cannot move hierarchy root in ".ref($self)." object"); }
    else { return $self; }
  }
  return $self->add($type, @_) unless ($self->has_type($type));
  $self->compiled(0);

  # ensure parents are well-defined & well-placed
  @_ = $self->ensure_types(@_);

  # adjust old child-relations for moved $type
  my $i = $self->{indices}{$type};
  my $v = $self->{vectors}[0];
  my $kids = $self->{children};
  foreach (@$kids[$self->_parents_indices($type)])
    {
      next unless (defined($_));
      $_ = _enum_bit_off($_,$i,$v);
    }

  # add new child-relations for moved $type
  my @pindices = @{$self->{indices}}{@_};
  foreach (@$kids[@pindices]) {
    $_ = _enum_bit_on($_, $i, $v);
  }

  # adjust parent-relation for moved $type
  $self->{parents}[$i] = join(',',@pindices);
  return $self;
}


#--------------------------------------------------------------
# remove(???): inherited from CEnum
sub remove ($@) {
  my $self = shift;

  @_ =
    grep {
      # sanity check
      $self->has_type($_) &&
	($_ ne $self->root || (carp("attempt to remove hierarchy root!") &&
			       0))
      } @_;
  return $self unless (@_); # not really deleting anything

  $self->compiled(0);

  my ($kids,$parents,$type,$idx);
  my ($v0,$v1) = @{$self->{vectors}}[0,1];
  foreach $type (@_) {
    # get type-information
    $idx = $self->{indices}{$type};
    $kids = $self->{children}[$idx];
    $parents = $self->{parents}[$idx];

    # adopt orphans
    foreach (@{$self->{parents}}[_enum2indices($kids,$v0)]) {
      # $_ is the parents-enum of an orphaned child
      $_ = _enum_bit_off(_enum_union($_, $parents, $v0, $v1),  $idx, $v0);
    }
    foreach (@{$self->{children}}[_enum2indices($parents,$v0)]) {
      # $_ is the kids-enum of an adopting grandparent
      $_ = _enum_bit_off(_enum_union($_, $kids, $v0, $v1),  $idx, $v0);
    }

    # actually remove the type
    delete($self->{indices}{$type});
    delete($self->{types}[$idx]);
    delete($self->{parents}[$idx]);
    delete($self->{children}[$idx]);

    # ... and mark its index as re-usable
    push(@{$self->{removed}}, $idx);
  }
  # ensure 'removed' is sorted...
  @{$self->{removed}} = sort { $a <=> $b } @{$self->{removed}};
  return $self;
}

#--------------------------------------------------------------
# @prts = $h->parents($type)
sub parents ($$) {
  return
    $_[0]->has_type($_[1])
      ? $_[0]->_enum2types($_[0]->{parents}[$_[0]->{indices}{$_[1]}],
			   #$_[0]->_parents_enum($_[1]),
			   $_[0]->{vectors}[0])
      : qw();
}

#--------------------------------------------------------------
# @kids = $h->children($type)
sub children ($$) {
    $_[0]->has_type($_[1])
      ? $_[0]->_enum2types($_[0]->{children}[$_[0]->{indices}{$_[1]}],
			   #$_[0]->_children_enum($_[1]),
			   $_[0]->{vectors}[0])
      : qw();
}


#--------------------------------------------------------------
sub ancestors ($$) {
  my ($i);
  return
    defined($_[1]) && defined($i = $_[0]->{indices}{$_[1]}) &&
    $_[0]->compiled(1)
      ? $_[0]->mask2types($_[0]->{ancestors}[$i])
      : qw();
}

#--------------------------------------------------------------
sub descendants ($$) {
  my ($i);
  return
    defined($i = $_[0]->{indices}{$_[1]}) &&
    $_[0]->compiled(1)
      ? $_[0]->mask2types($_[0]->{descendants}[$i])
      : qw();
}

#--------------------------------------------------------------
# $bool = $h->has_parent($typ,$prt)
sub has_parent ($$$) {
  return
    $_[0]->has_types(@_[1,2]) &&
    _enum_bit_test($_[0]->{parents}[$_[0]->{indices}{$_[1]}],
		   $_[0]->{indices}{$_[2]},
		   $_[0]->{vectors}[0]);
}


#--------------------------------------------------------------
# $bool = $h->has_child($typ,$kid)
sub has_child ($$$) {
  return
    $_[0]->has_types(@_[1,2]) &&
    _enum_bit_test($_[0]->{children}[$_[0]->{indices}{$_[1]}],
		   $_[0]->{indices}{$_[2]},
		   $_[0]->{vectors}[0]);
}



#--------------------------------------------------------------
# $bool = $h->has_ancestor($typ,$anc)
sub has_ancestor ($$$) {
  return
    $_[0]->has_types(@_[1,2])
      && $_[0]->has_ancestor_index($_[0]->{indices}{$_[1]},
				   $_[0]->{indices}{$_[2]});

}


#--------------------------------------------------------------
# $bool = $h->has_descendent($typ,$dsc)
sub has_descendant ($$$) {
  return
    $_[0]->has_types(@_[1,2])
      && $_[0]->has_descendant_index($_[0]->{indices}{$_[1]},
				     $_[0]->{indices}{$_[2]});

}

#--------------------------------------------------------------
# @sorted = subsort(@types)
sub subsort ($@) {
  my $h = shift;
  return qw() unless (@_);
  $h->compiled(1);
  my @indices = map { defined($_) ? $h->{indices}{$_} : undef } @_;
  my @other = qw();
  my ($i,$j);
  for ($i = 0; $i <= $#_; ++$i) {
    for ($j = $i+1; $j <= $#_; ++$j) {
      if (!defined($indices[$i])
	  ||
	  (defined($indices[$j]) &&
	   $h->{ancestors}[$indices[$i]]->bit_test($indices[$j])))
	{
	  @indices[$i,$j] = @indices[$j,$i];
	  @_[$i,$j] = @_[$j,$i];
	}
    }
  }
  return @_, @other;
}



#--------------------------------------------------------------
# \%strata = get_strata(@types)
sub get_strata ($@) {
  my $h = shift;
  $h->compiled(1);
  my @indices = @{$h->{indices}}{grep { defined($_) && exists($h->{indices}{$_}) } @_};
  my (@strata);
  foreach (@indices) { $strata[$_] = 0; }
  my ($cmp,$i,$j);
  my $changed = 1;
  my $step = 1;

  while ($changed) {
    last if ($step > scalar(@_));
    $changed = 0;

    for ($i = 0; $i < $#indices; ++$i) {
      for ($j = $i+1; $j <= $#indices; ++$j) {

	if ($h->{ancestors}[$indices[$j]]->bit_test($indices[$i])) {
	  next if ($strata[$indices[$i]] < $strata[$indices[$j]]);
	  $changed = 1;
	  $strata[$indices[$j]] = $strata[$indices[$i]] + 1;
	}
	elsif ($h->{ancestors}[$indices[$i]]->bit_test($indices[$j])) {
	  next if ($strata[$indices[$i]] > $strata[$indices[$j]]);
	  $changed = 1;
	  $strata[$indices[$i]] = $strata[$indices[$j]] + 1;
	}
      }
    }
  }
  my %strata =
    (map { $h->{types}[$_] => $strata[$_]  } @indices);
  return \%strata;
}


#--------------------------------------------------------------
# $h->_compare_index($i1,$i2);
sub _compare_index ($$$) {
  return  0 if (# object-equality is easy
		(defined($_[1]) and defined($_[2]) and $_[1] == $_[2])
		or
		# so is undef
		(!defined($_[1]) and !defined($_[2])));
  return  1 if ($_[0]->has_ancestor_index($_[1],$_[2]));
  return -1 if ($_[0]->has_ancestor_index($_[2],$_[1]));
  return  undef; # incomparable
}


#--------------------------------------------------------------
# @min = $h->min(@types)
sub min ($@) {
  return
    $_[0]->mask2types
      ($_[0]->_minimize($_[0]->types2mask(@_[1..$#_])));
}


#--------------------------------------------------------------
# @max = $h->max(@types)
sub max ($@) {
  return
    $_[0]->mask2types
      ($_[0]->_maximize($_[0]->types2mask(@_[1..$#_])));
}


#--------------------------------------------------------------
# $bv = $h->_minimize($bv,$tmp)
sub _minimize ($$) {
  my $self = shift;
  my $bv = shift;
  $self->compiled(1);
  my $vecary = $self->{descendants};
  my ($bmin,$bmax);
  my $i = 0;
  while ($i < $self->_size && (($bmin,$bmax) = $bv->Interval_Scan_inc($i)))
    {
      for ($i = $bmin; $i <= $bmax; ++$i) {
	last unless ($bv->bit_test($i)); # it might already have been removed
	$bv->Difference($bv, $vecary->[$i]);
      }
      if ($i >= $bmax) { $i = $bmax + 2; }
      else { ++$i; }
    }
  return $bv;
}

#--------------------------------------------------------------
# $bv = $h->_maximize($bv,$tmp)
sub _maximize ($$) {
  my $self = shift;
  my $bv = shift;
  $self->compiled(1);
  my ($bmin,$bmax);
  my $vecary = $self->{ancestors};
  my $i = $self->_size;
  while ($i >= 0 && (($bmin,$bmax) = $bv->Interval_Scan_dec($i)))
    {
      for ($i = $bmax; $i >= $bmin; --$i) {
	last unless ($bv->bit_test($i)); # it might already have been removed
	$bv->Difference($bv, $vecary->[$i]);
      }
      if ($i <= $bmin) { $i = $bmin - 2; }
      else { --$i; }
    }
  return $bv;
}


#--------------------------------------------------------------
# get_attribute($t,$a) : inherited from Base

#--------------------------------------------------------------
# set_attribute($t,$a,$v) : inherited from Base

#--------------------------------------------------------------
# $h1 = $h1->assign($h2)
sub assign ($$) {
  my ($h1,$h2) = @_;
  return $h1->SUPER::assign($h2) unless (ref($h1) eq ref($h2));
  #$h1->clear();

  %{$h1->{indices}} = %{$h2->{indices}};
  @{$h1->{types}} = @{$h2->{types}};
  @{$h1->{removed}} = @{$h2->{removed}};
  @{$h1->{attributes}} = @{$h2->{attributes}};

  @{$h1->{parents}} = @{$h2->{parents}};
  @{$h1->{children}} = @{$h2->{children}};

  @{$h1->{ancestors}} =
    map {
      defined($_) ? $_->Clone : undef
    } @{$h2->{ancestors}};
  @{$h1->{descendants}} =
    map {
      defined($_) ? $_->Clone : undef
    } @{$h2->{descendants}};

  @$h1{qw(root compiled)} = @$h2{qw(root compiled)};

  %{$h1->{hattributes}} = %{$h2->{hattributes}};

  $h1->_ensure_vector_sizes();
  return $h1;
}


#--------------------------------------------------------------
# $h1 = $h1->merge($h2,...) : inherited from Base


#--------------------------------------------------------------
# $h = $h->clear();
sub clear ($) {
  my $self = shift;
  @{$self->{types}} = qw();
  %{$self->{indices}} = ();
  @{$self->{parents}} = qw();
  @{$self->{children}} = qw();
  @{$self->{attributes}} = qw();
  @{$self->{removed}} = qw();
  @{$self->{ancestors}} = qw();
  @{$self->{descendants}} = qw();
  $self->{compiled} = 0;
  %{$self->{hattributes}} = ();

  # make sure we still have the root type!
  $self->_root($self->{root});
  return $self;
}


###############################################################
# Additional Hierarchy Info/Maintainence Operations
###############################################################

#--------------------------------------------------------------
# $root = $h->ensure_types(@types): inherited from Base

#--------------------------------------------------------------
# has_types: inherited from Base

# $bool = $h->has_ancestor_index($typ_idx,$anc_idx);
sub has_ancestor_index ($$$) {
  return
    defined($_[0]) && defined($_[1]) && defined($_[2]) &&
    $_[0]->compiled(1) &&
    defined($_[0]->{ancestors}[$_[1]]) &&
    $_[0]->{ancestors}[$_[1]]->bit_test($_[2]);
}

# $bool = $h->has_descendant_index($typ_idx,$dsc_idx);
sub has_descendant_index ($$$) {
  return
    defined($_[0]) && defined($_[1]) && defined($_[2]) &&
    $_[0]->compiled(1) &&
    defined($_[0]->{descendants}[$_[1]]) &&
    $_[0]->{descendants}[$_[1]]->bit_test($_[2]);
}

# $bv = $h->ancestors_mask($typ_idx)
sub ancestors_mask ($$) {
  return
    (defined($_[0]->{types}[$_[1]]) && $_[0]->compiled(1)
     ? $_[0]->{ancestors}[$_[1]]->Clone
     : undef);
}

# $bv = $h->descendants_mask($typ_idx)
sub descendants_mask ($$) {
  return
    (defined($_[0]->{types}[$_[1]]) && $_[0]->compiled(1)
     ? $_[0]->{ancestors}[$_[1]]->Clone
     : undef);
}


#--------------------------------------------------------------
# $rv = $h->iterate_i(\&next,\&callback,\%args)
sub iterate_i ($&&;$) {
  my ($self,$next,$callback,$args) = @_;
  my ($i,$r);
  my @q = defined($args->{start})
          ? ref($args->{start})
	    ? @{$args->{start}}
	    : ($args->{start})
	  : ($self->{indices}{$self->root});
  while (@q) {
    $i = shift(@q);
    $r = &$callback($self, $i, $args);
    return $r if (defined($r));
    push(@q, &$next($self,$i,$args));
  }
  return $args->{return};
}

#--------------------------------------------------------------
# $rv = $h->iterate_pc_i(\&callback,\%args)
sub iterate_pc_i ($&;$) {
  return
    $_[0]->iterate_i(\&_iterate_pc_i_next, $_[1], $_[2]);
}
sub _iterate_pc_i_next ($$) {
  return
    _enum2indices($_[0]->{children}[$_[1]],
		  $_[0]->{vectors}[0])
      if (defined($_[0]->{children}[$_[1]]));
}


#--------------------------------------------------------------
# $rv = $h->iterate_cp_i(\&sub,\%args)
sub iterate_cp_i ($&;$) {
  return
    $_[0]->iterate_i(\&_iterate_cp_i_next, $_[1], $_[2]);
}
sub _iterate_cp_i_next ($$) {
  return
    _enum2indices($_[0]->{parents}[$_[1]],
		  $_[0]->{vectors}[0])
      if (defined($_[0]->{parents}[$_[1]]));
}




###############################################################
# Type Operations
###############################################################

#--------------------------------------------------------------
# _get_bounds_log($i1,$i2,\@vectors,$want_indices,$min_or_max)
sub _get_bounds_log ($$$$;$$) {
  my $self = shift;
  my $i1 = shift;
  my $i2 = shift;
  my $vecary = shift;

  # sanity checks
  return undef unless
    (defined($i1) && defined($i2) && $self->compiled(1));

  # set up solutions-vector
  my $solns = $self->{vectors}[0]->Shadow;

  if (shift) { # $want_indices
    # get the easy answers
    if ($vecary->[$i1]->bit_test($i2)) {
      $solns->Bit_On($i2);
      return $solns;
    }
    elsif ($vecary->[$i2]->bit_test($i1)) {
      $solns->Bit_On($i1);
      return $solns;
    }
  }

  # the guts
  $solns->Intersection($vecary->[$i1],$vecary->[$i2]);
  if ($_[0] < 0) {
    return $self->_minimize($solns);
  } elsif ($_[0] > 0) {
    return $self->_maximize($solns);
  }
  # well that's odd -- let's just return the intersection
  return $solns;
}


#--------------------------------------------------------------
# @lubs = $h->_lub($t1,$t2)
sub _lub ($$$) {
  return
    @{$_[0]->{types}}[$_[0]->_get_bounds_log
		      ($_[0]->{indices}{$_[1]},
		       $_[0]->{indices}{$_[2]},
		       $_[0]->{descendants},
		       1, -1)->Index_List_Read];
}

#--------------------------------------------------------------
# @mcds = $h->_mcd($i1,$i2)
sub _mcd ($$$) {
  return
    @{$_[0]->{types}}[$_[0]->_get_bounds_log
		      ($_[0]->{indices}{$_[1]},
		       $_[0]->{indices}{$_[2]},
		       $_[0]->{descendants},
		       0, -1)->Index_List_Read];
}

#--------------------------------------------------------------
# @glbs = $h->_glb($t1,$t2)
sub _glb ($$$) {
  return
    @{$_[0]->{types}}[$_[0]->_get_bounds_log
		      ($_[0]->{indices}{$_[1]},
		       $_[0]->{indices}{$_[2]},
		       $_[0]->{ancestors},
		       1, 1)->Index_List_Read];
}

#--------------------------------------------------------------
# @mcas = $h->_mca($i1,$i2)
sub _mca ($$$) {
  return
    @{$_[0]->{types}}[$_[0]->_get_bounds_log
		      ($_[0]->{indices}{$_[1]},
		       $_[0]->{indices}{$_[2]},
		       $_[0]->{ancestors},
		       0, 1)->Index_List_Read];
}




###############################################################
# Low-level Accessors/manipulators
###############################################################

# $h->_ensure_vector_sizes(), $h->_ensure_vector_sizes($size)
sub _ensure_vector_sizes ($;$) {
  my $size = exists($_[1]) ? $_[1] : scalar(@{$_[0]->{types}});
  $size = int(1 + ($size / $VECTOR_GROW_STEP)) * $VECTOR_GROW_STEP;
  foreach (@{$_[0]->{vectors}}) {
    $_->Resize($size) unless ($_->Size > $size);
  }
}

#--------------------------------------------------------------
sub _indices ($) { return $_[0]->{indices}; }
sub _types ($) { return $_[0]->{types}; }

#--------------------------------------------------------------
sub _root ($;$) {
  my $self = shift;
  return $self->{root} unless (@_);
  my $root = shift;

  unless ($self->has_type($root) && $self->{root} eq $root) {
    $self->compiled(0);

    my $i = $self->{indices}{$root};

    unless (defined($i)) {
      $i = $self->_next_index();
      $self->{indices}{$root} = $i;   # ... add index
      $self->{types}[$i] = $root;     # ... add element
    }

    # ... add parents
    $self->{parents}[$i]  = '';

    # adopt parentless types
    my $c = '';
    my $j;
    for ($j = 0; $j <= $#{$self->{parents}}; ++$j) {
      next if ($i == $j);
      $c = $c ? ",$j" : $j unless ($self->{parents}[$j]);
    }
    # ... add children
    $self->{children}[$i] = $c;
  }
  return $self->{root} = $root;
}
*root = \&_root;


#--------------------------------------------------------------
sub _set_root ($$) { return $_[0]->{root} = $_[1]; }

#--------------------------------------------------------------
sub _parents ($) { return $_[0]->{parents}; }

#--------------------------------------------------------------
sub _children ($) { return $_[0]->{children}; }



#--------------------------------------------------------------
sub _ancestors ($) { return $_[0]->{ancestors}; }

#--------------------------------------------------------------
sub _descendants ($) { return $_[0]->{descendants}; }

#--------------------------------------------------------------
# $bool = _compiled(), _compiled($bool)
sub _compiled ($;$) {
  return exists($_[1]) ? $_[0]->{compiled} = $_[1] : $_[0]->{compiled};
}

#--------------------------------------------------------------
# \@attrs = $h->_attributes
# \%type_attrs_or_undef = $h->_attributes($type)
# \%attrs = $h->_attributes($type,\%attrs)
sub _attributes ($;$$) {
  return $_[0]->{attributes} if (scalar(@_) == 1);
  my ($i);
  return undef unless (defined($_[1]) && defined($i = $_[0]->{indices}{$_[1]}));
  return $_[0]->{attributes}[$i] if (scalar(@_) == 2);
  return $_[0]->{attributes}[$i] = $_[2];
}


#--------------------------------------------------------------
# $hashref = $h->_hattributes(), $h->_hattributes($hashref);
sub _hattributes ($;$) {
  return $_[0]->{hattributes} if (!exists($_[1]));
  return $_[0]->{hattributes} = $_[1];
}

#--------------------------------------------------------------
# $aryref = $h->_removed
sub _removed ($) { return $_[0]->{removed}; }

#--------------------------------------------------------------
# $aryref = $h->_vectors()
# @vecs = $h->_vectors(@indices)
sub _vectors($;@) {
  return
    exists($_[1])
      ? @{$_[0]->{vectors}}[@_[1..$#_]]
      : $_[0]->{vectors};
}


#--------------------------------------------------------------
# $free_idx = $h->_next_index
sub _next_index ($) {
  return
    scalar(@{$_[0]->{removed}})
      ? shift(@{$_[0]->{removed}})
      : scalar(@{$_[0]->{types}});
}

#--------------------------------------------------------------
# $size = $h->_size;
sub _size ($) { return scalar(@{$_[0]->{types}}); }

#--------------------------------------------------------------
# $bv = $h->mask;
sub mask ($) {
  my $bv = Bit::Vector->new(scalar(@{$_[0]->{types}}));
  $bv->Fill;
  $bv->Index_List_Remove(@{$_[0]->{removed}});
  return $bv;
}



###############################################################
# Misc
###############################################################

#--------------------------------------------------------------
sub dump ($;$$) {
  my $h = shift;
  my $name = shift || "$h";
  my $what = shift;
  my $dump = "\$$name = [\n";
  my ($i);
  if (!defined($what) || $what =~ /\btypes\b/) {
    $dump .= " TYPES: [";
    for ($i = 0; $i <= $#{$h->{types}}; ++$i) {
      $dump .=
	"\n  $i: " .
	(defined($h->{types}->[$i]) ? "'" . $h->{types}->[$i] . "'" : 'undef');
    }
    $dump .= "\n ],\n";
  }
  if (!defined($what) || $what =~ /\bindices\b/) {
    $dump .= " INDICES: {";
    foreach $i (keys(%{$h->{indices}})) {
      $dump .= "\n  '$i' => '" . $h->{indices}->{$i} . "'";
    }
    $dump .= "\n },\n";
  }
  if (!defined($what) || $what =~ /\broot\b/) {
    $dump .= " ROOT: '" . $h->{root} . "',\n";
  }
  if (!defined($what) || $what =~ /\bparents\b/) {
    $dump .= " PARENTS: [";
    for ($i = 0; $i <= $#{$h->{parents}}; ++$i) {
      $dump .= "\n  $i: (" . (defined($h->{parents}->[$i]) ? $h->{parents}->[$i] : 'undef') . ")";
    }
    $dump .= "\n ],\n";
  }
  if (!defined($what) || $what =~ /\bchildren\b/) {
    $dump .= " CHILDREN: [";
    for ($i = 0; $i <= $#{$h->{children}}; ++$i) {
      $dump .= "\n  $i: (" . (defined($h->{children}->[$i]) ? $h->{children}->[$i] : 'undef') . ")";
    }
    $dump .= "\n ],\n";
  }
  if (!defined($what) || $what =~ /\bremoved\b/) {
    $dump .= " REMOVED: [" . join(',', @{$h->{removed}}) . "],\n";
  }
  if (!defined($what) || $what =~ /\bancestors\b/) {
    $dump .= " ANCESTORS: [";
    for ($i = 0; $i <= $#{$h->{ancestors}}; ++$i) {
      $dump .= "\n  $i: (" .
	(defined($h->{ancestors}->[$i])
	 ? $h->{ancestors}->[$i]->to_Enum
	 : 'undef') . ")";
    }
    $dump .= "\n ],\n";
  }
  if (!defined($what) || $what =~ /\bdescendants\b/) {
    $dump .= " DESCENDANTS: [";
    for ($i = 0; $i <= $#{$h->{descendants}}; ++$i) {
      $dump .= "\n  $i: (" .
	(defined($h->{descendants}->[$i])
	 ? $h->{descendants}->[$i]->to_Enum
	 : 'undef') . ")";

    }
    $dump .= "\n ],\n";
  }
  if (!defined($what) || $what =~ /\bhattr/) {
    $dump .= " HATTRS: {";
    foreach $i (keys(%{$h->{hattributes}})) {
      $dump .= "\n  '$i' => '" . $h->{hattributes}->{$i} . "'";
    }
    $dump .= "\n },\n";
  }
  if (!defined($what) || $what =~ /\bcompiled\b/) {
    $dump .= " COMPILED: " . ($h->compiled ? '1' : '0') . "\n";
  }
  return $dump . "];\n";
}



###############################################################
# Storage/retrieval
###############################################################

#--------------------------------------------------------------
# $hashref = $h->_get_bin_compat() : for binary compatibility
sub _get_bin_compat { return \%BIN_COMPAT; }


#--------------------------------------------------------------
# $h->_store_before($retr)
sub _store_before {
  my ($h,$retr) = @_;
  $retr->{RemovedIndices} = $h->{removed};
  $retr->{ParentsEnums} = $h->{parents};
  $retr->{ChildrenEnums} = $h->{children};
  $retr->{CompiledFlag} = $h->{compiled};
  if ($h->{compiled}) {
    $retr->{AncestorsEnums} =
      [ map { defined($_) ? $_->to_Enum : undef } @{$h->{ancestors}} ];
    $retr->{DescendantsEnums} =
      [ map { defined($_) ? $_->to_Enum : undef } @{$h->{descendants}} ];
  }
  return $retr;
}

#--------------------------------------------------------------
# $h->_store_type($tr,$retr) : add index to type-record
sub _store_type {
  $_[1]->[$_tr_index] = $_[0]->{indices}{$_[1]->[0]};
}


#--------------------------------------------------------------
# $h->_retrieve_type($tr,$retr)
sub _retrieve_type {
  my ($h,$tr,$retr) = @_;
  my $type = $retr->{Refs}{$tr->[$_tr_name]};
  $h->{types}[$tr->[$_tr_index]] = $type;
  $h->{indices}{$type} = $tr->[$_tr_index];
  $h->_attributes($type, $retr->{Refs}{$tr->[$_tr_attrs]})
    if (defined($tr->[$_tr_attrs]));
}

#--------------------------------------------------------------
# $h->_retrieve_after($retr)
sub _retrieve_after {
  my ($h,$retr) = @_;
  @{$h->{removed}} = @{$retr->{RemovedIndices}};
  @{$h->{parents}} = @{$retr->{ParentsEnums}};
  @{$h->{children}} = @{$retr->{ChildrenEnums}};
  $h->{compiled} = $retr->{CompiledFlag};

  if ($h->{compiled}) {
    $h->_ensure_vector_sizes();
    my $size = $h->{vectors}[0]->Size;

    @{$h->{ancestors}} =
      map {
	defined($_) ? Bit::Vector->new_Enum($size,$_)  : undef
      } @{$retr->{AncestorsEnums}};

    @{$h->{descendants}} =
      map {
	defined($_) ? Bit::Vector->new_Enum($size,$_)  : undef
      } @{$retr->{DescendantsEnums}};

  }
  return $h;
}

###############################################################
# Mask Utility Methods
###############################################################

# $bv = $h->_types2mask(@types)
sub _types2mask ($@) {
  my $self = shift;
  my $bv = Bit::Vector->new($self->_size+1);
  $bv->Index_List_Store(@{$self->{indices}}{@_});
  return $bv;
}

sub types2mask ($@) {
  my $self = shift;
  my $bv = Bit::Vector->new($self->_size+1);
  $bv->Index_List_Store(grep { defined($_) } @{$self->{indices}}{@_});
  return $bv;
}

#--------------------------------------------------------------
# _mask2types($bv) -- @types list for bit-vector mask
#--------------------------------------------------------------
sub _mask2types ($$) {
  return @{$_[0]->{types}}[$_[1]->Index_List_Read];
  # $_[0]->types_at($_[1]->Index_List_Read);
}

sub mask2types ($$) {
  return grep { defined($_) } @{$_[0]->{types}}[$_[1]->Index_List_Read];
    #grep { defined($_) } $_[0]->_types_at($_[1]->Index_List_Read);
}


###############################################################
# Enum Utility Methods
###############################################################

# $enum = $h->_types2enum(@types)
sub _types2enum ($@) {
  return
    scalar(@_) > 1
    ? join(',',@{$_[0]->{indices}}{@_[1..$#_]})
      #join(',', $_[0]->_indices_of(@_[1..$#_]))
    : '';
}

# $enum = $h->types2enum(@types)
sub types2enum ($@) {
  return
    scalar(@_) > 1
    ? join(',', grep { defined($_) } @{$_[0]->{indices}}{@_[1..$#_]})
      #join(',', grep { defined($_) } $_[0]->_indices_of(@_[1..$#_]))
    : '';
}

# @types = $h->_enum2types($enum,$bv)
sub _enum2types ($$$) {
  $_[2]->from_Enum($_[1]);
  return @{$_[0]->{types}}[$_[2]->Index_List_Read];
    #$_[0]->_mask2types($_[2]);
}

# @types = $h->enum2types($enum,$bv)
sub enum2types ($$$) {
  $_[2]->from_Enum($_[1]);
  return grep { defined($_) } @{$_[0]->{types}}[$_[2]->Index_List_Read];
    #$_[0]->mask2types($_[2]);
}



# $enum = $h->_parents_enum($type)
sub _parents_enum ($$) {
  return $_[0]->{parents}[$_[0]->{indices}{$_[1]}];
}
# $enum = $_[0]->_children_enum($type)
sub _children_enum ($$) {
  return $_[0]->{children}[$_[0]->{indices}{$_[1]}];
}


# $bv = $h->_parents_mask($type)
sub _parents_mask ($$) {
  $_[0]->{vectors}[0]->from_Enum($_[0]->{parents}[$_[0]->{indices}{$_[1]}]);
  return $_[0]->{vectors}[0];
}
# $bv = $h->_children_mask($type)
sub _children_mask ($$) {
  $_[0]->{vectors}[0]->from_Enum($_[0]->{children}[$_[0]->{indices}{$_[1]}]);
  return $_[0]->{vectors}[0];
}


# @indices = $h->_parents_indices($type);
sub _parents_indices ($$) {
  $_[0]->{vectors}[0]->from_Enum($_[0]->{parents}[$_[0]->{indices}{$_[1]}]);
  return $_[0]->{vectors}[0]->Index_List_Read;
  #return $_[0]->_parents_mask($_[1])->Index_List_Read;
}
# @indices = $h->_children_indices($type);
sub _children_indices ($$) {
  $_[0]->{vectors}[0]->from_Enum($_[0]->{children}[$_[0]->{indices}{$_[1]}]);
  return $_[0]->{vectors}[0]->Index_List_Read;
}



###############################################################
# Non-method Utilities: Bit-vectors
###############################################################

# _bv_ensure_size($bv,$size)
sub _bv_ensure_size ($$) {
  return ($_[0]->Size < $_[1]) ? $_[0]->Resize($_[1]) : undef;
}

# $size = _bv_make_comparable($bv1,$bv2)
sub _bv_make_comparable ($$) {
  _bv_ensure_size($_[0],$_[1]->Size);
  _bv_ensure_size($_[1],$_[0]->Size);
  return $_[0]->Size;
}

# $bool = _bv_bit_test($bv,$idx)
sub _bv_bit_test ($$) { return $_[0]->Size > $_[1] && $_[0]->bit_test($_[1]); }

# _bv_bit_on($bv,$idx)
sub _bv_bit_on ($$) {
  $_[0]->Resize($_[1]+1) if ($_[0]->Size <= $_[1]);
  $_[0]->Bit_On($_[1]);
}

# _bv_bit_off($bv,$idx)
sub _bv_bit_off ($$) {
  $_[0]->Bit_Off($_[1]) if ($_[0]->Size > $_[1]);
}

# _bv_union_d($bv1,$bv2);
sub _bv_union_d ($$) {
  _bv_make_comparable($_[0],$_[1]);
  $_[0]->Union(@_[0,1]);
}

# _bv_intersection_d($bv1,$bv2)
sub _bv_intersection_d ($$) {
  _bv_make_comparable($_[0],$_[1]);
  $_[0]->Intersection(@_[0,1]);
}

# _bv_difference_d($bv1,$bv2)
sub _bv_difference_d ($$) {
  _bv_make_comparable($_[0],$_[1]);
  $_[0]->Difference($_[0],$_[1]);
}


###############################################################
# Non-method Utilities: Enums
###############################################################

# @indices = _enum2indices($enum,$bv)
sub _enum2indices ($$) {
  $_[1]->from_Enum(defined($_[0]) ? $_[0] : '');
  return $_[1]->Index_List_Read;
}

# $bool = _enum_bit_test($enum,$bit,$bv)
sub _enum_bit_test ($$$) {
  $_[2]->from_Enum(defined($_[0]) ? $_[0] : '');
  return $_[2]->bit_test($_[1]);
}

# $enum2 = _enum_bit_on($enum1,$bit,$bv)
sub _enum_bit_on ($$$) {
  $_[2]->from_Enum(defined($_[0]) ? $_[0] : '');
  _bv_bit_on($_[2],$_[1]);
  return $_[2]->to_Enum;
}

# $enum2 = _enum_bit_off($enum1,$bit,$bv)
sub _enum_bit_off ($$$) {
  $_[2]->from_Enum(defined($_[0]) ? $_[0] : '');
  _bv_bit_off($_[2],$_[1]);
  return $_[2]->to_Enum;
}

# $enum3 = _enum_union($enum1,$enum2,$bv1,$bv2);
sub _enum_union ($$$$) {
  $_[2]->from_Enum(defined($_[0]) ? $_[0] : '');
  $_[3]->from_Enum(defined($_[1]) ? $_[1] : '');
  _bv_union_d($_[2],$_[3]);
  return $_[2]->to_Enum;
}

# $enum3 = _enum_intersection($enum1,$enum2,$bv1,$bv2);
sub _enum_intersection ($$$$) {
  $_[2]->from_Enum(defined($_[0]) ? $_[0] : '');
  $_[3]->from_Enum(defined($_[1]) ? $_[1] : '');
  _bv_intersection_d($_[2],$_[3]);
  return $_[2]->to_Enum;
}

# $enum3 =_enum_difference($enum1,$enum2,$bv1,$bv2);
sub _enum_difference ($$$$) {
  $_[2]->from_Enum(defined($_[0]) ? $_[0] : '');
  $_[3]->from_Enum(defined($_[1]) ? $_[1] : '');
  _bv_difference_d($_[2],$_[3]);
  return $_[2]->to_Enum;
}




1;
__END__
