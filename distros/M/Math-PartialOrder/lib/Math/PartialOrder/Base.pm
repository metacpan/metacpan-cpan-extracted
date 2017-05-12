# -*- Mode: Perl -*-

#
# Copyright (c) 2001, Bryan Jurish.  All rights reserved.
#
# This package is free software.  You may redistribute it
# and/or modify it under the same terms as Perl itself.
#

###############################################################
#
#      File: Math::PartialOrder::Base.pm
#    Author: Bryan Jurish <jurish@ling.uni-potsdam.de>
#
# Description: Abstract base class for partial orders
#
###############################################################

package Math::PartialOrder::Base;
# System modules
require 5.6.0;                  # for those handy 'our' variables...
use Carp qw(:DEFAULT cluck);
require Exporter;
# 3rd party exstensions
# user extension modules
@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = (
	      qw(&_subsumes_trivial &_psubsumes_trivial),
	      qw(&_subsumes_user &_psubsumes_user),
	      qw(&_lub_trivial &_glb_trivial),
	      qw(&_binop_user &_lub_user &_glb_user),
	      qw($TYPE_NONE $TYPE_TOP),
	     );
%EXPORT_TAGS =
  (
   trivialities => [qw(&_subsumes_trivial &_psubsumes_trivial),
		    qw(&_lub_trivial &_glb_trivial)],
   userhooks => [qw(&_subsumes_user &_psubsumes_user),
		 qw(&_binop_user &_lub_user &_glb_user)],
   typevars => [qw($TYPE_TOP)]
  );

###############################################################
# Package-global variables
###############################################################
our $VERSION = 0.01;

our $WANT_USER_HOOKS = 1;

our $VERBOSE = 1;
our $TYPE_TOP = '__TOP__';
*TYPE_NONE = \$TYPE_TOP;

###############################################################
# Constructor
#   + Hierarchy->new()
#   + Hierarchy->new( att1 => val1, ..., attN => valN )
###############################################################

# $h->new(), $h->new(\%args)
sub new ($;$) {
  my $proto = shift;
  if (ref($proto)) {
    return bless %$proto, ref($proto);
  }
  my $self = shift || {};
  bless $self, $proto;
  $self->initialize(@_) if ($self->can('initialize'));
  return $self;
}

sub clone ($) {
  my $h = shift;
  my $h2 = ref($h)->new();
  $h2->assign($h);
  return $h2;
}

sub compiled ($;$) { return 0; }

sub compile ($) { return 1; }


###############################################################
# Operations
#   + most of these are not defined here, they're just wrappers
#     for the functions we'll want
###############################################################
sub warn_abstract ($) {
  if ($^W && $VERBOSE) {
    my $warn =
      "Attempt to find non-existant method `$_[0]' via Math::PartialOrder::Base.\n"
      ." > (Did you forget to implement an abstract method?)";
    if ($VERBOSE > 1) { cluck($warn); }
    else { carp($warn); }
  }
}

###############################################################
# Hierarchy Manipulation/Information
###############################################################
sub root ($;$) { warn_abstract('root'); }
sub add ($$@) { warn_abstract('add'); }
sub move ($$@) { warn_abstract('move'); }
sub remove ($@) { warn_abstract('remove'); }

sub add_parents ($$;@) {
  my ($self, $type, @parents) = @_;
  return $self->move($type,
		     $self->parents($type),
		     grep { !$self->has_parent($type,$_) } @parents);
}
sub replace ($$$) {
  my ($h, $old, $new) = @_;
  $h->add($new,$h->parents($old));
  foreach ($h->children($old)) { $h->add_parents($_,$new); }
  $h->remove($old);
  return $h;
}

sub ensure_types ($@) {
  my $self = shift;
  if (@_) {
    foreach (@_) {
      $self->add($_, $self->root) unless $self->has_type($_);
    }
    return @_;
  }
  return ($self->root);
}

sub clear ($) {
  $_[0]->remove($_[0]->types);
  %{$_[0]->_hattributes} = ();
}

sub assign ($$) {
  my ($h1,$h2) = @_;
  $h1->clear();
  $h1->replace($h1->root,$h2->root);
  my ($t,$attrs,$newattrs);
  foreach $t ($h2->types) {
    $h1->add($t, $h2->parents($t));
    $attrs = $h2->_attributes($t);
    if (defined($attrs) && %$attrs) {
      $newattrs = {};
      %$newattrs = %$attrs;
      $h1->_attributes($t, $newattrs);
    }
  }
  %{$h1->_hattributes} = %{$h2->_hattributes};
  return $h1;
}

# $h1->merge($h2,$h3,...)
sub merge ($@) {
  my $h1 = shift;
  my ($h2,$t,$attrs,$a,@parents);
  while ($h2 = shift) {
    %{$h1->_hattributes} = (%{$h1->_hattributes}, %{$h2->_hattributes});
    foreach $t ($h2->types) {
      unless ($h1->has_type($t)) {
	# new type for $h1
	$h1->add($t, $h2->parents($t));
      } else {
	# just add any parents this type didn't have before
	@parents = grep { !$h1->has_parent($t,$_) } $h2->parents($t);
	$h1->add_parents($t, @parents) if (@parents);
      }
      # merge attributes
      $attrs = $h2->get_attributes($t);
      if (defined($attrs)) {
	foreach $a (keys(%$attrs)) {
	  $h1->set_attribute($t,$a,$h2->get_attribute($t,$a));
	}
      }
    }
  }
  return $h1;
}



###############################################################
# Hierarchy Information
###############################################################
sub size ($) { return scalar($_[0]->types); }
sub leaves ($) { return grep { !$_[0]->children($_) } $_[0]->types(); }
sub has_type ($$) {
  return
    defined($_[1])
    ? grep { $_ eq $_[1] } $_[0]->types()
    : grep { !defined($_) } $_[0]->types();
}
sub has_types ($$@) {
  my $h = shift;
  foreach (@_) {
    return '' unless ($h->has_type($_));
  }
  return 1;
}

sub types ($) { warn_abstract('types'); }

sub is_equal ($$) {
  my ($h1,$h2) = @_;
  return 1 if ($h1 eq $h2); # object-equality
  my (%alltypes, %allparents, $parent, $type);
  @alltypes{($h1->types,
	     $h2->types)} = ($h1->types,
			     $h2->types);
  foreach $type (values(%alltypes)) {
    return 0 unless ($h1->has_type($type) && $h2->has_type($type));
    %allparents = ();
    @allparents{($h1->parents($type),
		 $h2->parents($type))} = ($h1->parents($type),
					  $h2->parents($type));
    foreach $parent (values(%allparents)) {
      return 0 unless ($h1->has_parent($type, $parent) &&
		       $h2->has_parent($type, $parent));
    }
  }
  return 1;
}

# $bool = $h->is_circular
# --iterative version
*is_circular = \&is_circular_iter;
*is_cyclic = \&is_circular_iter;
sub is_circular_iter ($) {
  return
    $_[0]->iterate_strata($_[0]->can('children'),
			  \&_is_circular_callback,
			  {size=>$_[0]->size, return=>''});
}
sub _is_circular_callback ($$$) {
  return 1 if ($_[2]->{step} > $_[2]->{size});
  return undef;
}
# --logical version : assumes non-iterative has_ancestor...
#*is_circular = \&is_circular_log;
sub is_circular_log ($) {
  foreach ($_[0]->types) { return 1 if ($_[0]->has_ancestor($_,$_)); }
  return '';
}

# $bool = $h->is_deterministic
sub is_deterministic ($) { return !$_[0]->get_nondet_pair; }
# ($t1,$t2) = $h->get_nondet_pair
sub get_nondet_pair ($) {
  my $h = shift;
  my @types = $h->types;
  my (@lubs,$i,$j);
  for ($i = 0; $i <= $#types; ++$i) {
    for ($j = $i+1; $j <= $#types; ++$j) {
      @lubs = $h->_lub($types[$i],$types[$j]);
      return (@types[$i,$j]) if (@lubs && scalar(@lubs) > 1);
    }
  }
  return qw();
}

# $bool = $h->is_treelike
sub is_treelike ($) { return !defined($_[0]->get_multiparent_type); }
# $type = $h->get_multiparent_type
sub get_multiparent_type ($) {
  my $h = shift;
  foreach ($h->types) {
    return $_ if (scalar(@{[ $h->parents($_) ]}) > 1);
  }
  return undef;
}


sub parents ($$) { warn_abstract('parents'); }
sub children ($$) { warn_abstract('children'); }

sub ancestors ($$) {
  return @{$_[0]->iterate_cp_step
	     (\&_ancestors_callback, { start => $_[1], return => [] })};
}
# callback($h,$t,$args)
sub _ancestors_callback ($$$) {
  push(@{$_[2]->{return}}, $_[0]->parents($_[1]));
  return undef;
}
sub descendants ($$) {
  return @{$_[0]->iterate_pc_step
	     (\&_descendants_callback,
	      { start => $_[1], return => [] })};
}
# callback($h,$t,$args)
sub _descendants_callback ($$$) {
  push(@{$_[2]->{return}}, $_[0]->children($_[1]));
  return undef;
}

# $h->has_parent($t,$p)
sub has_parent ($$$) {
  return
    ($_[0]->has_types($_[1],$_[2])
     and
     grep { $_ eq $_[2] } $_[0]->parents($_[1]));
}
# $h->has_child($t,$p)
sub has_child ($$$) {
    ($_[0]->has_types($_[1],$_[2])
     and
     grep { $_ eq $_[2] } $_[0]->children($_[1]));
}

sub has_ancestor ($$$) {
  return
    defined($_[1]) && defined($_[2]) &&
    $_[0]->has_type($_[1]) &&
    $_[0]->has_type($_[2]) &&
      $_[0]->iterate_cp_step(\&_type_search_callback,
			     {
			      start => [$_[0]->parents($_[1])],
			      find => $_[2],
			      return => ''
			     });
}
# callback($h,$t,$args)
sub _type_search_callback ($$$) {
  return $_[2]->{find} eq $_[1] ? 1 : undef;
}

sub has_descendant ($$$) { return $_[0]->has_ancestor($_[2],$_[1]); }

# comparison aliases
*le = \&subsumes;
*lt = \&psubsumes;
*ge = \&extends;
*gt = \&pextends;
*cmp = \&compare;

sub extends ($$$) { return $_[0]->subsumes($_[2],$_[1]); }

*properly_extends = \&pextends;
sub pextends ($$$) { return $_[0]->psubsumes($_[2],$_[1]); }

sub subsumes ($$$) {
  my ($a);
  return
    # easy answers
    (defined($a = _subsumes_trivial($_[1],$_[2]))
     ? $a
     # user-defined subsumption
     : ($WANT_USER_HOOKS && defined($a = _subsumes_user($_[1],$_[2]))
	? $a
	# consult hierarchy (if we can)
	: (ref($_[0])
	   and $_[0]->has_types($_[1],$_[2])
	   and $_[0]->has_ancestor($_[2],$_[1]))));
}

sub _subsumes_trivial ($$) {
  return
    (# undef subsumes everything
     !defined($_[0]) ? 1
     : (# nothing else subsumes undef
	!defined($_[1]) ? 0
	: (# object-identity counts as subsumption
	   $_[0] eq $_[1] ? 1
	   : (# everything subsumes $TYPE_TOP
	      $_[1] eq $TYPE_TOP ? 1
	      : (# nothing else subsumes $TYPE_TOP
		 $_[0] eq $TYPE_TOP ? 0
		 : # ... can't do it the easy way
		   undef)))));
}

# _subsumes_user($t1,$t2)
# user-defined subsumption
sub _subsumes_user ($$) {
  return
    (# object-oriented user-defined subsumption
     UNIVERSAL::can($_[0], 'subsumes')
     ? (1,$_[0]->subsumes($_[1]))
     : (# functional user-defined subsumption
	ref($_[0]) && ref($_[0]) eq 'CODE'
	? &{$_[0]}('subsumes',$_[1])
	: # ... nope
	undef));
}


*properly_subsumes = \&psubsumes;
sub psubsumes ($$$) {
  my ($ans);
  return
    (# easy answers
     defined($ans = _psubsumes_trivial($_[1],$_[2])) ? $ans
      : (# user-defined subsumption
	 $WANT_USER_HOOKS && defined($ans = _psubsumes_user($_[1],$_[2])) ? $ans
	 : (# consult hierarchy
	    ref($_[0])
	    and $_[0]->has_types($_[1],$_[2])
	    and $_[0]->has_ancestor($_[2],$_[1]))));
}
*_properly_subsumes_trivial = \&_psubsumes_trivial;
sub _psubsumes_trivial ($$) {
  return
    (defined($_[0])
     ? (# nothing defined p-subsumes undef
	!defined($_[1]) ? 0
	: (# TOP p-subsumes nothing
	   $_[0] eq $TYPE_TOP ? 0
	   : (# everything else p-subsumes TOP
	      $_[1] eq $TYPE_TOP ? 1
	      : (# nothing p-subsumes itself
		 $_[0] eq $_[1] ? 0
		 : # ... can't do it this way
		 undef))))
     : (# undef subsumes all and only defined values
	defined($_[1]) ? 1 : 0));
}

# non-method: _psubsumes_user($t1,$t2)
sub _psubsumes_user ($$) {
  return
    (# object-oriented user-defined proper subsumption
     UNIVERSAL::can($_[0], 'properly_subsumes')
     ? $_[0]->properly_subsumes($_[1])
     : (# functional user-defined p-subsumption
	ref($_[0]) && ref($_[0]) eq 'CODE'
	? &{$_[0]}('properly_subsumes',$_[1])
	# nope
	: undef));
}
*_properly_subsumes = \&_psubsumes;
sub _psubsumes ($$$) {
  return
    # check hierarchy structure
    $_[0]->has_ancestor($_[2],$_[1]);
}



#####################################################################
# Sorting/Comparison
#####################################################################
sub compare ($$$) {
  return  0 if (# object-equality is easy
		(defined($_[1]) and defined($_[2]) and $_[1] eq $_[2])
		or
		# so is undef
		(!defined($_[1]) and !defined($_[2])));
  return -1 if ($_[0]->properly_subsumes($_[1],$_[2]));
  return  1 if ($_[0]->properly_subsumes($_[2],$_[1]));
  return  undef; # incomparable
}
sub _compare ($$$) {
  return undef unless ($_[0]->has_types($_[1],$_[2])); # sanity check
  return  0 if (# object-equality is easy
		(defined($_[1]) and defined($_[2]) and $_[1] eq $_[2])
		or
		# so is undef
		(!defined($_[1]) and !defined($_[2])));
  return  1 if ($_[0]->has_ancestor($_[1],$_[2]));
  return -1 if ($_[0]->has_ancestor($_[2],$_[1]));
  return  undef; # incomparable
}


# @min = $h->min(@types)
sub min ($@) {
  my $self = shift;
  my ($t1,$t2,@results);
 MIN_T1:
  foreach $t1 (@_) {
    foreach $t2 (@_) {
      #next unless ($self->has_type($t1)); # sanity check -- not needed with 'extends'
      next MIN_T1 if ($self->properly_extends($t1,$t2));
    }
    push(@results,$t1);
  }
  return @results;
}
# @max = $h->max(@types)
sub max ($@) {
  my $self = shift;
  my ($t1,$t2,@results);
 MAX_T1:
  foreach $t1 (@_) {
    #next unless ($self->has_type($t1)); # sanity check -- not needed w/ 'subsumes'
    foreach $t2 (@_) {
      next MAX_T1 if ($self->properly_subsumes($t1,$t2));
    }
    push(@results,$t1);
  }
  return @results;
}



# @min = $h->min_extending($base,@types)
# (logical version)
*min_extending = \&_min_extending_log;
sub _min_extending_log ($$@) {
  my $h = shift;
  my $base = shift;
  return $h->min(grep { $h->extends($_,$base) } @_);
}

# @max = $h->max_subsuming($base,@types)
# (logical version)
*max_subsuming = \&_max_subsuming_log;
sub _max_subsuming_log ($$@) {
  my $h = shift;
  my $base = shift;
  return $h->max(grep { $h->subsumes($_,$base) } @_);
}


# --- iterative version
*subsort = \&_subsort_it;
sub _subsort_it ($@) {
  my $h = shift;
  my %find = map { $_ => $_ } @_;
  my %found = ();
  my %found2step = ();
  $h->iterate_strata($h->can('children'),
		     \&_subsort_callback,
		     {
		      find => \%find,
		      found => \%found,
		      found2step => \%found2step,
		      maxstep => $h->size,
		     });
  return
    @found{sort { $found2step{$a} <=> $found2step{$b} } keys(%found)},
    values(%find);
}
# callback($hi,$type,$args)
sub _subsort_callback ($$$) {
  return '' if ($_[2]->{step} > $_[2]->{maxstep});
  if (exists($_[2]->{find}{$_[1]})) {
    $_[2]->{found2step}{$_[1]} = $_[2]->{step};
    $_[2]->{found}{$_[1]} = $_[1];
    delete($_[2]->{find}{$_[1]});
  } elsif (exists($_[2]->{found}{$_[1]})) {
    $_[2]->{found2step}{$_[1]} = $_[2]->{step};
  }
  return undef;
}

# logical version -- nice if we've got a fast 'has_ancestor'
#*subsort = \&_subsort_log;
sub _subsort_log ($@) {
  my $h = shift;
  my ($i,$j,$cmp);
  for ($i = 0; $i < $#_; ++$i) {
    for ($j = $i+1; $j <= $#_; ++$j) {
      $cmp = $h->compare($_[$i],$_[$j]);
      next if (!$cmp || $cmp < 0);
      @_[$i,$j] = @_[$j,$i];
    }
  }
  return @_;
}


sub stratasort ($@) {
  my $h = shift;
  my %find = map { defined($_) ? ($_ => $_) : qw() } @_;
  my $stratah = $h->get_strata(@_);
  my @strata = ();
  my $last = [];
  foreach (@_) {
    if (defined($_) && exists($stratah->{$_})) {
      unless (exists($strata[$stratah->{$_}])) {
	$strata[$stratah->{$_}] = [$_];
      } else {
	push(@{$strata[$stratah->{$_}]}, $_);
      }
    } else {
      push(@$last, $_);
    }
  }
  push(@strata, $last) if (@$last);
  return grep { $_ } @strata;
}


# iterative version
*get_strata = \&_get_strata_it;
sub _get_strata_it ($@) {
  return
    $_[0]->iterate_strata
      ($_[0]->can('children'),
       \&_get_strata_callback,
       {
	maxstrat => scalar($_[0]->types),
	laststep => {},
	return => {},
       });
}
# callback($h,$type,$args)
sub _get_strata_callback ($$$) {
  # circular hierarchy -- bail out
  return $_[2]->{return} if ($_[2]->{step} >= $_[2]->{maxstrat});

  if (!exists($_[2]->{laststep}{$_[1]}) ||
      $_[2]->{laststep}{$_[1]} < $_[2]->{step})
    {
      # ... we need to move it to this virtual step-stratum
      $_[2]->{return}{$_[1]} = $_[2]->{step};
    }

  $_[2]->{laststep}{$_[1]} = $_[2]->{step}; # keep this for *all* types
  return undef;
}

# --- assumes we have a fast has_ancestor()
# : pretty but slow
#*get_strata = \&_get_strata_log;
sub _get_strata_log ($@) {
  my $h = shift;
  my @types = grep { $h->has_type($_) } @_;
  my %strata = ( map { $_ => 0 } @types );
  my ($cmp,$i,$j);
  my $changed = 1;
  my $step = 1;

  while ($changed) {
    last if ($step > scalar(@_));
    $changed = 0;

    for ($i = 0; $i < $#types; ++$i) {
      next unless ($h->has_type($types[$i]));

      for ($j = $i+1; $j <= $#types; ++$j) {
	next unless ($h->has_type($types[$j]));

	$cmp = $h->_compare($types[$i],$types[$j]);
	next unless ($cmp);

	if ($cmp < 0) {
	  next if ($strata{$types[$i]} < $strata{$types[$j]});
	  $changed = 1;
	  $strata{$types[$j]} = $strata{$types[$i]} + 1;
	}
	elsif ($cmp > 0) {
	  next if ($strata{$types[$i]} > $strata{$types[$j]});
	  $changed = 1;
	  $strata{$types[$i]} = $strata{$types[$j]} + 1;
	}
      }
    }
  }
  return \%strata;
}

###############################################################
# Type Operations
###############################################################

# $h->warn_nondet($op,$t1,$t2,$default,@warnings)
# --> sets '$!'
sub warn_nondet ($$$$$@) {
  if ($^W && $VERBOSE) {
    my ($h,$op,$t1,$t2,$default) = @_;
    my @warnings =
      ("Warning: unsupported deterministic operation in non-ccpo hierarchy\n",
       " >       Class: ", (ref($h)||$h), "\n",
       " >   Operation: $op(", (defined($t1) ? "'$t1'" : "undef",
			       defined($t2) ? ",'$t2'" : ",undef"), ")\n",
       " > Defaults to: ", defined($default) ? "'$default'" : 'undef', "\n",
       " >");
    if ($VERBOSE > 1) { cluck(@warnings); }
    else { carp(@warnings); }
  }
}

#--------------------------------------------------------------
# njoin : deterministc n-ary lub()
sub njoin ($@) {
  my $h = shift;
  my $val = shift;
  my (@lubs);
  foreach (@_) {
    @lubs = $h->lub($val,$_);
    return $TYPE_TOP unless (@lubs);
    $h->warn_nondet('lub', $val, $_, $lubs[0]) if (scalar(@lubs) > 1);
    $val = $lubs[0];
  }
  return $val;
}

#--------------------------------------------------------------
# type_join : deterministic n-ary lub(), defined types only
sub type_join ($@) {
  my $h = shift;
  return $TYPE_TOP unless ($h->has_types(@_)); # sanity check
  my $val = shift;
  my (@lubs);
  foreach (@_) {
    @lubs = $h->_lub($val,$_);
    return $TYPE_TOP unless (@lubs);
    $h->warn_nondet('_lub', $val, $_, $lubs[0]) if (scalar(@lubs) > 1);
    $val = $lubs[0];
  }
  return $val;
}


#--------------------------------------------------------------
# nmeet : deterministic n-ary glb()
sub nmeet ($@) {
  my $h = shift;
  my $val = shift;
  my (@glbs);
  foreach (@_) {
    @glbs = $h->glb($val,$_);
    return undef unless (@glbs);
    $h->warn_nondet('glb', $val, $_, $glbs[0]) if (scalar(@glbs) > 1);
    $val = $glbs[0];
  }
  return $val;
}
#--------------------------------------------------------------
# type_meet : deterministic n-ary glb(), types only
sub type_meet ($@) {
  my $h = shift;
  return undef unless ($h->has_types(@_));
  my $val = shift;
  my (@glbs);
  foreach (@_) {
    @glbs = $h->_glb($val,$_);
    return undef unless (@glbs);
    $h->warn_nondet('_glb', $val, $_, $glbs[0]) if (scalar(@glbs) > 1);
    $val = $glbs[0];
  }
  return $val;
}



#--------------------------------------------------------------
# lub : least upper bounds
#--------------------------------------------------------------
*least_upper_bounds = \&lub;
sub lub ($$$) {
  my ($l);
  return
    (# get the easy answers
     defined($l = _lub_trivial($_[1],$_[2])) ? @$l
     : (# user hooks
	($WANT_USER_HOOKS && defined($l = _lub_user($_[1],$_[2]))) ? @$l
	: (# are we an instance with these types?
	   (ref($_[0]) && $_[0]->has_types($_[1],$_[2]))
	   # ... then do the lookup
	   ? ($_[0]->_lub($_[1],$_[2]))
	   : # ... guess not
	   qw())));
}

# lub: iterative version
*_lub = \&_lub_iter;
sub _lub_iter ($$$) {
  return
    values(%{$_[0]->_get_bounds_iter($_[0]->can('children'),
				     -1,
				     $_[1], $_[2],
				     {$_[1]=>$_[1]},
				     {$_[2]=>$_[2]})});
}

# non-method -- easy answers for lub()
# $listref_or_undef = _lub_trivial($t1,$t2)
sub _lub_trivial ($$) {
  return
    (# X * undef = X
     !defined($_[1]) ? [$_[0]]
     : (# undef * X = X
	!defined($_[0]) ? [$_[1]]
	: (# X * top = top * X = top
	   ($_[0] eq $TYPE_TOP || $_[1] eq $TYPE_TOP) ? [$TYPE_TOP]
	   : (# X * X = X
	      $_[0] eq $_[1] ? [$_[0]]
	      :  # ... can't do it the easy way
	      undef))));
}

# non-method -- user hooks for lub()
# $listref_or_undef = _lub_user($t1,$t2)
sub _lub_user ($$) { return Math::PartialOrder::Base::_binop_user('lub',$_[0],$_[1]); }

# $listref_or_undef = binop_user($op,$t1,$t2)
sub _binop_user ($$$) {
  return
    (# delegate to $t1 (func)
     ref($_[1]) && ref($_[1]) eq 'CODE'
     ? [&{$_[1]}($_[0],$_[2])]
     : (# delegate to $t2 (func)
	ref($_[2]) && ref($_[2]) eq 'CODE'
	? [&{$_[2]}($_[0],$_[1])]
	: (# delegate to $t1 (oop)
	   UNIVERSAL::can($_[1], $_[0])
	   ? [&{UNIVERSAL::can($_[1],$_[0])}($_[1],$_[2])]
	   : (# delegate to $t2 (oop)
	      UNIVERSAL::can($_[2], $_[0])
	      ? [&{UNIVERSAL::can($_[2],$_[0])}($_[2],$_[1])]
	      : # ... nope
	      undef))));
}

# $_[1] : STOP $_[0] :STOP 'lub' STOP

# lub: logical version
#*_lub = \&_lub_log;
sub _lub_log ($$$) {
  my ($cmp);
  if (defined($cmp = $_[0]->compare($_[1],$_[2]))) {
    # more easy answers
    return $_[2] if ($cmp <= 0);
    return $_[1];
  }
  # do the lookup
  return $_[0]->mcd_log($_[1],$_[2]);
}

#--------------------------------------------------------------
# mcd : minimal common descendants
#--------------------------------------------------------------
#*mcd= \&mcd_log;
*mcd = \&mcd_iter;
*minimal_common_descendants = \&mcd;

# iterative version
sub mcd_iter ($$$) {
  return qw() unless ($_[0]->has_types($_[1],$_[2]));
  return
    values(%{$_[0]->_get_bounds_iter($_[0]->can('children'),
				     -1, $_[1], $_[2])});
}


#--------------------------------------------------------------
# _get_bounds_iter: abstract iterative bound-getting method
#
# iterative version:
# lub:test = has_ancestor
# lub:next = children
# glb:test = has_descendant
# glb:next = parents
#--------------------------------------------------------------

# $h->get_bounds_iter(\&next,$cmpkeep,$t1,$t2)
# $h->get_bounds_iter(\&next,$cmpkeep,$t1,$t2,$t1hash,$t2hash)
# --> $cmpkeep is -1 to keep minimal, 1 to keep maximal
#     i.e. min={ x \in solns | y \in solns and !_compare(x,y) or (_compare(x,y) == cmpkeep }
sub _get_bounds_iter ($&$$$;$$) {
  my $self = shift;
  my $next = shift;
  my $cmpkeep = shift;
  my @t1q = (shift);
  my @t2q = (shift);
  my $t1set = shift || {};
  my $t2set = shift || {};
  my %solns = ();
  my %q = ();
  my $step = $self->size;
  my ($e,@next,$cmp,$want);
  while ((@t1q || @t2q) && $step >= 0) {
    --$step;
    %q = ();
    foreach $e (@t1q) {
      $t1set->{$e} = $e;
      if (exists($t2set->{$e})) {
	$want = 1;
	foreach (values(%solns)) {
	  $cmp = $self->_compare($e,$_);
	  next if (!$cmp);
	  if ($cmp != $cmpkeep) {
	    $want = 0;
	    last;
	  }
	  delete($solns{$_});
	}
	$solns{$e} = $e if ($want);
      } else {
	@next = &$next($self,$e);
	@q{@next} = @next;
      }
    }
    @t1q = values(%q);
    %q = ();
    foreach $e (@t2q) {
      $t2set->{$e} = $e;
      if (exists($t1set->{$e})) {
	$want = 1;
	foreach (values(%solns)) {
	  $cmp = $self->_compare($e,$_);
	  next if (!$cmp);
	  if ($cmp != $cmpkeep) {
	    $want = 0;
	    last;
	  }
	  delete($solns{$_});
	}
	$solns{$e} = $e if ($want);
      } else {
	@next = &$next($self,$e);
	@q{@next} = @next;
      }
    }
    @t2q = values(%q);
  }
  return \%solns;
}


# mcd($h,$t1,$t2): logical version
# *mcd = \&mcd_log;
sub mcd_log ($$$) {
  # get intersection of descendants
  my (@t1descs,%t1hash);
  @t1descs = $_[0]->descendants($_[1]);
  @t1hash{@t1descs} = @t1descs;
  # delegate the gruntwork to min()
  return
    $_[0]->min(grep { exists($t1hash{$_}) } $_[0]->descendants($_[2]));
}


#--------------------------------------------------------------
# glb : greatest lower bounds
#--------------------------------------------------------------
*greatest_lower_bounds = \&glb;

sub glb ($$$) {
  my (@l);
  return
    (# get the easy answers
     defined($l = _glb_trivial($_[1],$_[2])) ? @$l
     : (# user hooks
	($WANT_USER_HOOKS && defined($l = _glb_user($_[1],$_[2]))) ? @$l
	: (# are we an instance with these types?
	   (ref($_[0]) && $_[0]->has_types($_[1],$_[2]))
	   # ... then do the lookup
	   ? ($_[0]->_glb($_[1],$_[2]))
	   : # ... guess not
	   undef)));
}

# non-method -- easy answers for glb()
# $listref_or_undef = _lub_trivial($t1,$t2)
sub _glb_trivial ($$) {
  return
    (# X / undef = undef / X = undef
     !defined($_[0]) or !defined($_[1]) ? [undef]
     : (# top / X = X
	$_[0] eq $TYPE_TOP ? [$_[1]]
	: (# X / top = X
	   $_[1] eq $TYPE_TOP ? [$_[0]]
	   : # ... can't do it the easy way
	   undef)));
}

# non-method -- user hooks for glb()
# $listref_or_undef = _glb_user($t1,$t2)
sub _glb_user ($$) { return Math::PartialOrder::Base::_binop_user('glb',$_[0],$_[1]); }

# glb: logical version
#*_glb = \&_glb_log;
sub _glb_log ($$$) {
  my ($cmp);
  if (defined($cmp = $_[0]->compare($_[1],$_[2]))) {
    # more easy answers
    return $_[2] if ($cmp >= 0);
    return $_[1];
  }
  # do the lookup
  return $_[0]->mca_log($_[1],$_[2]);
}


# glb: iterative version
*_glb = \&_glb_iter;
sub _glb_iter ($$$) {
  return
    values(%{$_[0]->_get_bounds_iter($_[0]->can('parents'),
				     1,
				     $_[1], $_[2],
				     {$_[1]=>$_[1]},
				     {$_[2]=>$_[2]})});
}


#--------------------------------------------------------------
# mca : maximal common ancestors
#--------------------------------------------------------------
*mca = \&mca_iter;
#*mca = \&mca_log;
*maximal_common_ancestors = \&mca;

# iterative version
sub mca_iter ($$$) {
  return values(%{$_[0]->_get_bounds_iter($_[0]->can('parents'),
					  1,
					  $_[1], $_[2])});
}

# mca: logical version
# *mca = \&mca_log;
sub mca_log ($$$) {
  # get intersection of ancestors
  my (@t1descs,%t1hash);
  @t1descs = $_[0]->ancestors($_[1]);
  @t1hash{@t1descs} = @t1descs;
  # delegate the gruntwork to max()
  return
    $_[0]->max(grep { exists($t1hash{$_}) } $_[0]->ancestors($_[2]));
}


#####################################################################
# User-Defined Attributes
#####################################################################

sub get_attributes ($$) { return $_[0]->_attributes($_[1]); }
sub get_attribute ($$$) {
  my ($self,$type,$attr) = @_;
  my ($tattrs);
  return
    defined($tattrs = $self->_attributes($type))
    ? $tattrs->{$attr}
    : undef;
}
sub set_attribute ($$$$) {
  my ($self,$type,$attr,$val) = @_;
  my ($tattrs);
  if (defined($tattrs = $self->_attributes($type))) {
    return $tattrs->{$attr} = $val;
  }
  # need new attributes
  $self->_attributes($type, {$attr => $val});
  return $val;
}
sub _attributes ($$;$) {
  my $self = shift;
  return undef unless (ref($self) && $self =~ /=HASH\(/);
  my $type = shift;
  my $attr = shift;
  if (@_) {
    # set attributes
    return $self->{attributes}->{$type} = shift;
  }
  # get attributes
  if (exists($self->{attributes}) && exists($self->{attributes}->{$type}))
    {
      return $self->{attributes}->{$type};
    }
  return undef;
}

# _hattributes(), _hattributes($attrs)
# --> automagic creation!
*_hattrs = \&_hattributes;
sub _hattributes ($;$) {
  if (scalar(@_) == 1) {
    return $_[0]->_attributes->{$_[0]} = {} unless
      (defined($_[0]->_attributes) &&
       exists($_[0]->_attributes->{$_[0]}));
    return $_[0]->_attributes->{$_[0]};
  }
  return $_[0]->_attributes->{$_[0]} = $_[1];
}

# $val = $h->get_hattribute($a)
sub get_hattribute ($$) {
  return defined($_[1]) ? $_[0]->_hattributes->{$_[1]} : undef;
}
# $val = $h->set_hattribute($a,$v)
sub set_hattribute ($$;$) {
  return
    defined($_[1])
      ? defined($_[2])
	? $_[0]->_hattributes->{$_[1]} = $_[2]
        : delete($_[0]->_hattributes->{$_[1]})
      : undef;
}


#####################################################################
# Iteration Utilitiles
#####################################################################

sub iterate ($&&;$) {
  my ($self,$next,$callback,$args) = @_;
  return undef unless (defined($next) && defined($callback));
  my ($t,$r);
  my @q = defined($args->{start})
          ? ref($args->{start})
	    ? @{$args->{start}}
	    : $args->{start}
	  : ($self->root);
  return undef unless ($self->has_types(@q));

  while (@q) {
    $t = shift(@q);
    $r = &$callback($self, $t, $args) if (defined($callback));
    return $r if (defined($r));
    push(@q, &$next($self,$t,$args));
  }
  return $args->{return};
}


sub iterate_step ($&&;$) {
  my ($self,$next,$callback,$args) = @_;
  return undef unless (defined($next));

  my @q = defined($args->{start})
          ? ref($args->{start})
	    ? @{$args->{start}}
	    : ($args->{start})
	  : ($self->root);
  return undef unless ($self->has_types(@q));

  my $visited =
    defined($args->{visited})
      ? $args->{visited}
      : ($args->{visited} = {});

  my ($t,$r,%qh,@next);
  @qh{@q} = @q;
  $args->{step} = 0 unless (defined($args->{step}));
  while (%qh) {
    @q = values(%qh);
    %qh = ();
    while (defined($t = shift(@q))) {
      next if (exists($visited->{$t}));
      $visited->{$t} = undef;
      $r = &$callback($self, $t, $args) if (defined($callback));
      return $r if (defined($r));
      @next = grep { !exists($visited->{$_}) } &$next($self,$t);
      @qh{@next} = @next;
    }
    ++$args->{step};
  }
  return $args->{return};
}


sub iterate_tracking ($&&;$) {
  my ($self,$next,$callback,$args) = @_;
  return undef unless (defined($next) && defined($callback));

  my @q = defined($args->{start})
          ? ref($args->{start})
	    ? @{$args->{start}}
	    : ($args->{start})
	  : ($self->root);

  my $ignore =
    defined($args->{ignore})
      ? $args->{ignore}
      : ($args->{ignore} = {});

  my $prev =
    defined($args->{prev})
      ? $args->{prev}
      : ($args->{prev} = {});

  my ($t,$r,%qh,@next);
  @qh{@q} = @q;
  $args->{step} = 0 unless (defined($args->{step}));

  while (%qh) {
    @q = values(%qh);
    %qh = ();
    while (defined($t = shift(@q))) {
      next if (exists($ignore->{$t}));

      $r = &$callback($self, $t, $args);
      return $r if (defined($r));

      next if (exists($ignore->{$t}));

      @next = &$next($self,$t,$args);

      foreach (@next) { $prev->{$_}{$t} = undef; }
      @next = grep { !exists($ignore->{$_}) } @next;
      @qh{@next} = @next;
    }
    ++$args->{step};
  }
  return $args->{return};
}

sub iterate_strata ($&&;$) {
  my ($self,$next,$callback,$args) = @_;

  return undef unless (defined($next) && defined($callback));

  my @q = defined($args->{start})
          ? ref($args->{start})
	    ? @{$args->{start}}
	    : ($args->{start})
	  : ($self->root);

  my $prev =
    defined($args->{prev})
      ? $args->{prev}
      : ($args->{prev} = {});

  my ($t,$r,%qh,@next);
  @qh{@q} = @q;
  $args->{step} = 0 unless (defined($args->{step}));

  while (%qh) {
    @q = values(%qh);
    %qh = ();
    while (defined($t = shift(@q))) {
      $r = &$callback($self, $t, $args);
      return $r if (defined($r));

      @next = &$next($self,$t,$args);

      foreach (@next) {
	if (!defined($prev->{$_}{$t}) || $prev->{$_}{$t} < $args->{step}) {
	  $prev->{$_}{$t} = $args->{step}
	}
      }
      @qh{@next} = @next;
    }
    ++$args->{step};
  }
  return $args->{return};
}

sub iterate_pc ($&;$) {
  return $_[0]->iterate
    (UNIVERSAL::can($_[0], 'children'),
     $_[1],
     defined($_[2]) ? $_[2] : {});
}

sub iterate_pc_step ($&;$) {
  return $_[0]->iterate_step
    (UNIVERSAL::can($_[0], 'children'),
     $_[1],
     defined($_[2]) ? $_[2] : {});
}

sub iterate_cp ($&;$) {
  $_[2]->{start} = [$_[0]->leaves] if
    (defined($_[2]) && !defined($_[2]->{start}));
  return $_[0]->iterate
    (UNIVERSAL::can($_[0], 'parents'),
     $_[1],
     defined($_[2]) ? $_[2] : {});
}

sub iterate_cp_step ($&;$) {
  $_[2]->{start} = [$_[0]->leaves] if
    (defined($_[2]) && !defined($_[2]->{start}));
  return $_[0]->iterate_step
    (UNIVERSAL::can($_[0], 'parents'),
     $_[1],
     defined($_[2]) ? $_[2] : {});
}


#####################################################################
# Miscellaneous
#####################################################################

sub dump ($) {
  eval "use Data::Dumper";
  return Data::Dumper->Dump([$_[0]], [$_[0]]);
}



1;
__END__

