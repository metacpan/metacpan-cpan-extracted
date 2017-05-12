# -*- Mode: Perl -*-

#
# Copyright (c) 2001, Bryan Jurish.  All rights reserved.
#
# This package is free software.  You may redistribute it
# and/or modify it under the same terms as Perl itself.
#

###############################################################
#
#      File: Math::PartialOrder::CEnum.pm
#    Author: Bryan Jurish <jurish@ling.uni-potsdam.de>
#
# Description: QuD Hierarchy class using
#              Bit::Vector objects to manipulate hierarchy
#              information, internal storage as 'Enum'-type
#              strings (compiling version)
#
###############################################################

package Math::PartialOrder::CEnum;
# System modules
use Carp;
#require Exporter;
# 3rd party exstensions
# user extension modules
use Math::PartialOrder::CMasked qw(:bincompat :bvutils :enumutils);
@ISA       = qw(Math::PartialOrder::CMasked);
#@EXPORT    = qw();
#@EXPORT_OK = qw();
#%EXPORT_TAGS = (
#	       );

our $VERSION = 0.01;


###############################################################
# Initialization
#   + object structure:
#     [
#       --- inherited ---
#       indices     => { Type0 => Index0, ... }
#       types       => [ Type0, Type1, ... ]
#       root        => scalar type-name
#       parents     => [ Type0Parents, Type1Parents, ... ]
#       children    => [ Type0Children, Type1Children, ... ]
#       attributes  => [ { attr1.1 => val1.1, ... }, ... ]
#       removed     => [ FirstFreeIndex, SecondFreeIndex, ... ]
#       vectors     => [ Bit::Vector0, Bit::Vector1 ]
#       compiled    => scalar boolean
#       hattributes => { a1 => v1, ... }
#       --- overriden ---
#       ancestors   => [ Type0Ancs, Type1Ancs, ... ]  # Ancs are Enum-strings!
#       descendants => [ Type0Dscs, Type1Dscs, ... ]  # Dscs are Enum-strings!
#     ]
###############################################################

#----------------------------------------------------------------------
# new({root=>$r}) : inherited from CMasked



#--------------------------------------------------------------
# $bool = $h->compile();
sub compile ($) {
  my $h = shift;
  my $rv = $h->SUPER::compile();
  return $rv unless ($rv);
  # compact ancestors/descendants
  @{$h->{ancestors}} =
    map {
      defined($_) ? $_->to_Enum : undef
    } @{$h->{ancestors}};
  @{$h->{descendants}} =
    map {
      defined($_) ? $_->to_Enum : undef
    } @{$h->{descendants}};
  return $rv;
}

#--------------------------------------------------------------
# $h->decompile() : inherited from CMasked

#--------------------------------------------------------------
# $h->compiled() : inherited from CMasked



###############################################################
# Hierarchy Maintainance
###############################################################

#--------------------------------------------------------------
# @types = $h->types(): inherited from CMasked

#--------------------------------------------------------------
# $h = $h->add($t,@ps) : inherited from CMasked

#--------------------------------------------------------------
# $bool = $h->has_type($t) : inherited from CMasked

#--------------------------------------------------------------
# $h = $h->add_parents($t,@ps) : inherited from CMasked

#--------------------------------------------------------------
# $h = $h->replace($old,$new) : inherited from CMasked

#--------------------------------------------------------------
# $h = $h->move($t,@ps) : inherited from CMasked

#--------------------------------------------------------------
# $h = $h->remove(@types) : inherited from CMasked

#--------------------------------------------------------------
# @prts = $h->parents($type) : inherited from CMasked

#--------------------------------------------------------------
# @kids = $h->children($type) : inherited from CMasked

#--------------------------------------------------------------
sub ancestors ($$) {
  my ($i);
  return
    defined($_[1]) && defined($i = $_[0]->{indices}{$_[1]}) &&
    $_[0]->compiled(1)
      ? $_[0]->_enum2types($_[0]->{ancestors}[$i],
			   $_[0]->{vectors}[0])
      : qw();
}

#--------------------------------------------------------------
sub descendants ($$) {
  my ($i);
  return
    defined($_[1]) && defined($i = $_[0]->{indices}{$_[1]}) &&
    $_[0]->compiled(1)
      ? $_[0]->_enum2types($_[0]->{descendants}[$i],
			   $_[0]->{vectors}[0])
      : qw();
}

#--------------------------------------------------------------
# $bool = $h->has_parent($typ,$prt) : inherited from CMasked


#--------------------------------------------------------------
# $bool = $h->has_child($typ,$kid) : inherited from CMasked


#--------------------------------------------------------------
# $bool = $h->has_ancestor($typ,$anc) : inherited from CMasked
# --> delegates to has_ancestor_index($typ_idx,$anc_idx)

#--------------------------------------------------------------
# $bool = $h->has_descendant($typ,$anc) : inherited from CMasked
# --> delegates to has_descendant_index($typ_idx,$anc_idx)


#--------------------------------------------------------------
# @sorted = subsort(@types)
sub subsort ($@) {
  my $h = shift;
  return qw() unless (@_);
  $h->compiled(1);
  my @indices = map { defined($_) ? $h->{indices}{$_} : undef } @_;
  my @other = qw();
  my $v = $h->{vectors}[0];
  my ($i,$j,$e);
  for ($i = 0; $i <= $#_; ++$i) {
    for ($j = $i+1; $j <= $#_; ++$j) {
      if (!defined($indices[$i])
	  ||
	  (defined($indices[$j]) &&
	   defined($e = $h->{ancestors}[$indices[$i]]) &&
	   $e ne '' &&
	   _enum_bit_test($e, $indices[$j], $v)))
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
  my $v = $h->{vectors}[0];
  my ($cmp,$i,$j,$e);
  my $changed = 1;
  my $step = 1;

  while ($changed) {
    last if ($step > scalar(@_));
    $changed = 0;

    for ($i = 0; $i < $#indices; ++$i) {
      for ($j = $i+1; $j <= $#indices; ++$j) {
	
	if (defined($e = $h->{ancestors}[$indices[$j]]) &&
	    $e ne '' &&
	    _enum_bit_test($e, $indices[$i], $v))
	  {
	    next if ($strata[$indices[$i]] < $strata[$indices[$j]]);
	    $changed = 1;
	    $strata[$indices[$j]] = $strata[$indices[$i]] + 1;
	  }
	elsif (defined($e = $h->{ancestors}[$indices[$i]]) &&
	       $e ne '' &&
	       _enum_bit_test($e, $indices[$j], $v))
	  {
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
# $bv = $h->_minimize($bv,$tmp)
sub _minimize ($$;$) {
  my $self = shift;
  my $bv = shift;
  my $tmp = shift || $self->{vectors}[1];
  $self->compiled(1);
  foreach ($bv->Index_List_Read) {
    $tmp->from_Enum(defined($self->{descendants}[$_])
		    ? $self->{descendants}[$_]
		    : '');
    $bv->Difference($bv,$tmp);
  }
  return $bv;
}

#--------------------------------------------------------------
# $bv = $h->_maximize($bv,$tmp)
sub _maximize ($$;$) {
  my $self = shift;
  my $bv = shift;
  my $tmp = shift  || $self->{vectors}[1];;
  $self->compiled(1);
  foreach ($bv->Index_List_Read) {
    $tmp->from_Enum(defined($self->{ancestors}[$_])
		    ? $self->{ancestors}[$_]
		    : '');
    $bv->Difference($bv,$tmp);
  }
  return $bv;
}


#--------------------------------------------------------------
# $val = $h->get_attribute($t,$a) : inherited from Base

#--------------------------------------------------------------
# $v = $h->set_attribute($t,$a,$v) : inherited from Base

#--------------------------------------------------------------
# $h1 = $h1->assign($h2) : inherited from CMasked

#--------------------------------------------------------------
# $h = $h->merge($h1,...) : inherited from Base

#--------------------------------------------------------------
# $h = $h->clear() : inherited from CMasked



###############################################################
# Additional Hierarchy Maintainence Operations
###############################################################

#--------------------------------------------------------------
# $root = $h->ensure_types(@types): inherited from Base

#--------------------------------------------------------------
# $bool = $h->has_types(@types): inherited from Base

# $bool = $h->has_ancestor_index($typ_idx,$anc_idx);
sub has_ancestor_index ($$$) {
  my ($e);
  return
    defined($_[1]) && defined($_[2]) &&
    $_[0]->compiled(1) &&
    defined($e = $_[0]->{ancestors}[$_[1]]) && $e ne '' &&
    _enum_bit_test($e, $_[2], $_[0]->{vectors}[0]);
}

# $bool = $h->has_descendant_index($typ_idx,$dsc_idx);
sub has_descendant_index ($$$) {
  my ($e);
  return
    defined($_[1]) && defined($_[2]) &&
    $_[0]->compiled(1) &&
    defined($e = $_[0]->_descendants->[$_[1]]) && $e ne '' &&
    _enum_bit_test($e, $_[2], $_[0]->_vectors->[0]);
}

# $bv = $h->ancestors_mask($typ_idx)
sub ancestors_mask ($$) {
  if (defined($_[0]) && defined($_[1]) && $_[0]->compiled(1)) {
    my $v = $_[0]->{vectors}[0];
    $v->from_Enum($_[0]->{ancestors}[$_[1]]);
    return $v->Clone;
  }
  return undef;
}

# $bv = $h->descendants_mask($typ_idx)
sub descendants_mask ($$) {
  if (defined($_[0]) && defined($_[1]) && $_[0]->compiled(1)) {
    my $v = $_[0]->{vectors}[0];
    $v->from_Enum($_[0]->{descendants}[$_[1]]);
    return $v->Clone;
  }
  return undef;
}

#--------------------------------------------------------------
# $rv = $h->iterate_i(\&next,\&callback,\%args) : inherited from CMasked

#--------------------------------------------------------------
# $rv = $h->iterate_pc_i(\&callback,\%args) : inherited from CMasked

#--------------------------------------------------------------
# $rv = $h->iterate_cp_i(\&callback,\%args) : inherited from CMasked


###############################################################
# Type Operations
###############################################################

#--------------------------------------------------------------
# _get_bounds_log($i1,$i2,\@enums,$want_indices,$min_or_max)
sub _get_bounds_log ($$$$;$$) {
  my $self = shift;
  my $i1 = shift;
  my $i2 = shift;
  my $enums = shift;

  # sanity checks
  return undef unless
    (defined($i1) && defined($i2) && $self->compiled(1));

  # set up solutions vector
  my $tmp = $self->{vectors}[0];
  my $solns = $tmp->Shadow;

  # do the *real* computation
  $solns->from_Enum(defined($enums->[$i1]) ? $enums->[$i1] : '');
  $tmp->from_Enum(defined($enums->[$i2]) ? $enums->[$i2] : '');
  if (shift) { # $want_indices
    $solns->Bit_On($i1);
    $tmp->Bit_On($i2);
  }
  $solns->Intersection($solns,$tmp);
  if ($_[0] < 0) {
    return $self->_minimize($solns,$tmp);
  } elsif ($_[0] > 0) {
    return $self->_maximize($solns,$tmp);
  }
  # well that's odd -- let's just return the intersection
  return $solns;
}


#--------------------------------------------------------------
# @lubs = $h->_lub($t1,$t2) : inherited from CMasked
# --> $h->types($h->_get_bounds_log($i1,$i2,$h->descendants,1,-1)->Index_List_Read)

#--------------------------------------------------------------
# @mcds = $h->_mcd($i1,$i2) : inherited from CMasked
# --> $h->types($h->_get_bounds_log($i1,$i2,$h->descendants,0,-1)->Index_List_Read)

#--------------------------------------------------------------
# @glbs = $h->_glb($t1,$t2) : inherited from CMasked
# --> $h->types($h->_get_bounds_log($i1,$i2,$h->ancestors,1,1)->Index_List_Read)

#--------------------------------------------------------------
# @mcas = $h->_mca($i1,$i2)
# --> $h->types($h->_get_bounds_log($i1,$i2,$h->ancestors,0,1)->Index_List_Read)


###############################################################
# Low-level Accessors/manipulators : inherited from CMasked
###############################################################


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
	(defined($h->{types}[$i]) ? "'" . $h->{types}[$i] . "'" : 'undef');
    }
    $dump .= "\n ],\n";
  }
  if (!defined($what) || $what =~ /\bindices\b/) {
    $dump .= " INDICES: {";
    foreach $i (keys(%{$h->{indices}})) {
      $dump .= "\n  '$i' => '" . $h->{indices}{$i} . "'";
    }
    $dump .= "\n },\n";
  }
  if (!defined($what) || $what =~ /\broot\b/) {
    $dump .= " ROOT: '" . $h->{root} . "',\n";
  }
  if (!defined($what) || $what =~ /\bparents\b/) {
    $dump .= " PARENTS: [";
    for ($i = 0; $i <= $#{$h->{parents}}; ++$i) {
      $dump .= "\n  $i: (" . $h->{parents}[$i] . ")";
    }
    $dump .= "\n ],\n";
  }
  if (!defined($what) || $what =~ /\bchildren\b/) {
    $dump .= " CHILDREN: [";
    for ($i = 0; $i <= $#{$h->{children}}; ++$i) {
      $dump .= "\n  $i: (" . $h->{children}[$i] . ")";
    }
    $dump .= "\n ],\n";
  }
  if (!defined($what) || $what =~ /\bremoved\b/) {
    $dump .= " REMOVED: [" . join(',', @{$h->{removed}}) . "],\n";
  }
  if (!defined($what) || $what =~ /\bancestors\b/) {
    $dump .= " ANCESTORS: [";
    for ($i = 0; $i <= $#{$h->{ancestors}}; ++$i) {
      $dump .= "\n  $i: (" . $h->{ancestors}[$i] . ")";
    }
    $dump .= "\n ],\n";
  }
  if (!defined($what) || $what =~ /\bdescendants\b/) {
    $dump .= " DESCENDANTS: [";
    for ($i = 0; $i <= $#{$h->{descendants}}; ++$i) {
      $dump .= "\n  $i: (" . $h->{descendants}[$i] . ")";
    }
    $dump .= "\n ],\n";
  }
  if (!defined($what) || $what =~ /\bcompiled\b/) {
    $dump .= " COMPILED: " . ($h->compiled ? '1' : '0') . "\n";
  }
  if (!defined($what) || $what =~ /\bhattr/) {
    $dump .= " HATTRS: {";
    foreach $i (keys(%{$h->{hattributes}})) {
      $dump .= "\n  '$i' => '" . $h->{hattributes}{$i} . "'";
    }
    $dump .= "\n },\n";
  }
  return $dump . "];\n";
}


#--------------------------------------------------------------
# Storage/retrieval

#---------------------------------------------------------------------
# $hashref = $h->_get_bin_compat() : inherited from CMasked

#---------------------------------------------------------------------
# $h->_store_before($retr)
sub _store_before {
  my ($h,$retr) = @_;
  $retr->{RemovedIndices} = $h->{removed};
  $retr->{ParentsEnums} = $h->{parents};
  $retr->{ChildrenEnums} = $h->{children};
  $retr->{CompiledFlag} = $h->{compiled};
  if ($h->{compiled}) {
    $retr->{AncestorsEnums} = $h->{ancestors};
    $retr->{DescendantsEnums} = $h->{descendants};
  }
  return $retr;
}

#--------------------------------------------------------------
# $h->_store_type($tr,$retr) : inherited from CMasked

#--------------------------------------------------------------
# $h->_retrieve_type($tr,$retr) : inherited from CMasked

#--------------------------------------------------------------
# $h->_retrieve_after($h,$retr)
sub _retrieve_after {
  my ($h,$retr) = @_;
  @{$h->{removed}} = @{$retr->{RemovedIndices}};
  @{$h->{parents}} = @{$retr->{ParentsEnums}};
  @{$h->{children}} = @{$retr->{ChildrenEnums}};
  $h->{compiled} = $retr->{CompiledFlag};
  if ($h->{compiled}) {
    $h->_ensure_vector_sizes();
    @{$h->{ancestors}} = @{$retr->{AncestorsEnums}};
    @{$h->{descendants}} = @{$retr->{DescendantsEnums}};
  }
}

1;
__END__

