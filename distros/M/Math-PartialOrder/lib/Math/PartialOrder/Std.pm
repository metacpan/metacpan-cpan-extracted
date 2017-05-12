# -*- Mode: Perl -*-

#
# Copyright (c) 2001, Bryan Jurish.  All rights reserved.
#
# This package is free software.  You may redistribute it
# and/or modify it under the same terms as Perl itself.
#

###############################################################
#
#      File: Math::PartialOrder::Std.pm
#    Author: Bryan Jurish <jurish@ling.uni-potsdam.de>
#
# Description: standard iterative PartialOrder class
#
###############################################################

package Math::PartialOrder::Std;
# System modules
use Carp;
#require Exporter;
# 3rd party exstensions
# user extension modules
use Math::PartialOrder::Base;
@ISA       = qw(Math::PartialOrder::Base);
@EXPORT    = qw();
@EXPORT_OK = qw();

our $VERSION = 0.01;

###############################################################
# Initialization
#   + object structure:
#     {
#       types      => {type1=>type1, ... }
#       root       => scalar
#       parents    => { type1 => {p1a=>p1a, c1b=>c1b,... }, ... }
#       children   => { type1 => {c1a=>c1a, c1b=>c1b,... }, ... }
#       attributes => { type1 => { attr1.1 => val1.1, ... }, ... }
#     }
###############################################################

#----------------------------------------------------------------------
# new( {root=>$r} )
#   + initialization routine: returns the object
#----------------------------------------------------------------------
sub new ($;$) {
  my $class = shift;
  my $args = shift;
  my $self = bless {
		    types => {},
		    root => '',
		    parents => {},
		    children => {},
		    attrs => {}
		   }, $class;
  # root node
  $self->_root($args->{root}||'BOTTOM');

  # hierarchy attributes
  $self->_hattributes({});

  return $self;
}

###############################################################
# Hierarchy Information
# information
###############################################################
# @types = $h->types()
sub types ($) { return values(%{$_[0]->{types}}); }

#--------------------------------------------------------------
# $bool = $h->has_type($t)
sub has_type ($$) { return (defined($_[1]) && exists($_[0]->{types}{$_[1]})); }

# $bool = $h->has_types(@types)
sub has_types ($@) {
  my $types = shift->{types};
  grep {
    return '' unless (defined($_) && exists($types->{$_}));
  } @_;
  return 1;
}

#--------------------------------------------------------------
# @ps = $h->parents($typ)
sub parents ($$) {
  return
    (defined($_[1]) && exists($_[0]->{parents}{$_[1]})
     ? values(%{$_[0]->{parents}{$_[1]}})
     : qw());
}

#--------------------------------------------------------------
# @cs = $h->children($typ)
sub children ($$) {
  return
    (defined($_[1]) && exists($_[0]->{children}{$_[1]})
     ? values(%{$_[0]->{children}{$_[1]}})
     : qw());
}

#--------------------------------------------------------------
# $bool = $h->has_parent($kid,$prt);
sub has_parent ($$) {
  return
    (defined($_[1]) && exists($_[0]->{parents}{$_[1]})
     ? exists($_[0]->{parents}{$_[1]}{$_[2]})
     : '');
}

#--------------------------------------------------------------
# $bool = $h->has_child($prt,$kid);
sub has_child ($$) {
  return
    (defined($_[1]) && exists($_[0]->{parents}{$_[1]})
     ? exists($_[0]->{parents}{$_[1]}{$_[2]})
     : '');
}

#--------------------------------------------------------------
# @ancs = $h->ancestors($typ)
sub ancestors ($$) { return values(%{$_[0]->_ancestors($_[1])}); }

#--------------------------------------------------------------
# @dscs = $h->descendants($typ)
sub descendants ($$) { return values(%{$_[0]->_ancestors($_[1])}); }

#--------------------------------------------------------------
# $bool = has_ancestor($t1,$t2) : inherited

#--------------------------------------------------------------
# $bool = has_descendant($t1,$t2) : inherited


###############################################################
# Additional Information
###############################################################

# $hashref = $h->_ancestors($t)
sub _ancestors ($$) {
  return
    ($_[0]->has_type($_[1])
     ? $_[0]->iterate_cp_step(\&_ancestors_callback,
			      {
			       start => $_[1],
			       return => {}
			      })
     : {});
}
sub _ancestors_callback ($$$) {
  @{$_[2]->{return}}{$_[0]->parents($_[1])} = $_[0]->parents($_[1]);
  return undef;
}

# $hashref = $h->_descendants($t)
sub _descendants ($$) {
    ($_[0]->has_type($_[1])
     ? $_[0]->iterate_pc_step(\&_descendants_callback,
			      {
			       start => $_[1],
			       return => {}
			      })
     : {});
}
sub _descendants_callback ($$$) {
  @{$_[2]->{return}}{$_[0]->children($_[1])} = $_[0]->children($_[1]);
  return undef;
}

# end information


###############################################################
# Hierarchy Manipulation
###############################################################

#--------------------------------------------------------------
# add($type,@parents)
sub add ($$@) {
  my $self = shift;
  my $type = shift;

  # sanity checks
  unless (defined($type)) {
    carp("cannot add undefined type");
    return $self;
  }
  return $self->move($type, @_) if ($self->has_type($type));

  # add this type
  $self->{types}{$type} = $type;

  # ensure parents are well-defined & well-placed
  @_ = $self->ensure_types(@_);

  # set parents-relation for new $type
  if (@_) {
    $self->{parents}{$type} = {};
    @{$self->{parents}{$type}}{@_} = @_;
  }
  # set children-relation for new $type
  my $kids = $self->{children};
  foreach (@_) { $kids->{$_}{$type} = $type; }
  return $self;
}

#--------------------------------------------------------------
# sub add_parents($h,$type,@parents) : INHERITED

#--------------------------------------------------------------
# replace($old,$new)
sub replace ($$$) {
  my ($h, $old, $new) = @_;
  return $h->add($new,$h->root) unless ($h->has_type($old));
  unless (defined($old) && defined($new)) {
    carp("cannot add undefined type");
    return $h;
  }
  $h->{types}{$new} = $new;
  foreach (qw(parents children attrs)) {
    if (exists($h->{$_}{$old})) {
      $h->{$_}{$new} = $h->{$_}{$old};
      delete($h->{$_}{$old});
    } else {
      delete($h->{$_}{$new});
    }
  }
  if ($old eq $h->{root}) { $h->_root($new); }
  return $h;
}



#--------------------------------------------------------------
# $move($type,@newps)
sub move ($$@) {
  my $self = shift;
  my $type = shift;

  # sanity check: type existence
  return $self->add($type, @_) unless ($self->has_type($type));
  # sanity check: root node
  if ($type eq $self->{root}) {
    if (@_) { croak("Cannot move hierarchy root '$type'"); }
    else { return $self; }
  }

  # ensure parents are well-defined & well-placed
  @_ = $self->ensure_types(@_);

  my $kids = $self->{children};
  my $prts = $self->{parents};
  if (exists($prts->{$type})) {
    # adjust old child-relations for moved $type
    foreach (values(%{$prts->{$type}})) {
      delete($kids->{$_}{$type});
    }
  }

  # add new child-relations for moved $type
  foreach (@_) { $kids->{$_}{$type} = $type; }

  # adjust parent-relation for moved $type
  %{$prts->{$type}} = map { ($_ => $_) } @_;

  return $self
}

#--------------------------------------------------------------
# BUG (fixed): deleting an intermediate type orphans its descendants
sub remove ($@) {
  my $self = shift;

  @_ = # sanity check
    grep {
      $self->has_type($_) &&
	($_ ne $self->root ||
	 (carp("attempt to remove hierarchy root!") && 0))
    } @_;

  return $self unless (@_); # not really deleting anything

  delete(@{$self->{types}}{@_});

  my ($kids,$parents,$deleted);
  foreach $deleted (@_) {
    # adopt orphans
    $kids = $self->{children}{$deleted};
    $parents = $self->{parents}{$deleted};
    foreach (values(%$kids)) { # $_ is an orphaned child
      $self->{parents}{$_} = {} unless (exists($self->{parents}{$_}));
      @{$self->{parents}{$_}}{values(%$parents)} = values(%$parents);
      delete(@{$self->{parents}{$_}}{@_});
    }
    foreach (values(%$parents)) { # $_ is an adopting grandparent
      $self->{children}{$_} = {} unless (exists($self->{children}{$_}));
      @{$self->{children}{$_}}{values(%$kids)} = values(%$kids);
      delete(@{$self->{children}{$_}}{@_});
    }
  }
  # delete inheritance information for deleted types
  delete(@{$self->{parents}}{@_});
  delete(@{$self->{children}}{@_});

  return $self;
}

#--------------------------------------------------------------
# $h1->assign($h2)
sub assign ($$) {
  my ($h1,$h2) = @_;
  return $h1->SUPER::assign($h2) unless ($h2->isa($h1));
  $h1->clear();
  %{$h1->{types}} = %{$h2->{types}};
  $h1->_root($h2->{root});
  foreach (values(%{$h1->{types}})) {
    %{$h1->{parents}{$_}} = %{$h2->{parents}{$_}};
    %{$h1->{children}{$_}} = %{$h2->{children}{$_}};
  }
  # assign attributes
  %{$h1->_attributes} = %{$h2->_attributes};
  %{$h1->_hattributes} = %{$h2->_hattributes};
  delete($h1->_attributes->{$h2});
  return $h1;
}



#--------------------------------------------------------------
# $h1->merge($h2,...)
sub merge ($@) {
  my $h1 = shift;

  my ($a2);
  while ($h2 = shift) {
    unless ($h2->isa($h1)) {
      $h1->SUPER::merge($h2);
      next;
    }

    # add all types
    @{$h1->{types}}{$h2->types} = $h2->types;

    # adopt $h2->root under $h1->root if they differ
    $h1->move($h2->{root}) unless ($h1->{root} eq $h2->{root});

    # merge/override hierarchy-attributes
    %{$h1->_hattributes} = (%$h1->_hattributes, %{$h2->_hattributes});

    # merge in all parent-child relations and attributes
    foreach (values(%{$h2->{types}})) {

      # parents
      @{$h1->{parents}{$_}}{$h2->parents($_)} = $h2->parents($_);

      # children
      @{$h1->{children}{$_}}{$h2->children($_)} = $h2->children($_);

      # attributes
      if (defined($a2 = $h2->_attributes($_)) && %$a2) {
	@{$h1->{attrs}{$_}}{keys(%$a2)} = values(%$a2);
      }
    }
  }
  return $h1;
}

#--------------------------------------------------------------
# $h->clear
sub clear ($) {
  my $self = shift;
  %{$self->{types}} = ();
  %{$self->{parents}} = ();
  %{$self->{children}} = ();
  %{$self->{attributes}} = ();

  my $hattrs = $self->_hattributes; # save this reference!
  %{$self->{attrs}} = ();
  %$hattrs = ();
  $self->_hattributes($hattrs);


  # make sure we still have the root type!
  $self->_root($self->root);

  return $self;
}

# end manipulation



###############################################################
# additional sorting / comparison
###############################################################

# $h->_minimize($hashref)
sub _minimize ($$) {
  my ($self,$hash) = @_;
  my ($t1,$t2);
  my @members = values(%$hash);
 MINIMIZE_T1:
  foreach $t1 (@members) {
    next unless (exists($hash->{$t1}));
    unless ($self->has_type($t1)) {
      # sanity check
      delete($hash->{$t1});
      next;
    }
    foreach $t2 (@members) {
      next unless (exists($hash->{$t2}));
      if ($self->has_ancestor($t1,$t2)) {
	delete($hash->{$t1});
	next MINIMIZE_T1;
      }
    }
  }
  return $hash;
}

# $h->_maximize($hashref)
sub _maximize ($$) {
  my ($self,$hash) = @_;
  my ($t1,$t2);
  my @members = values(%$hash);
 MAXIMIZE_T1:
  foreach $t1 (@members) {
    next unless (exists($hash->{$t1}));
    unless ($self->has_type($t1)) {
      # sanity check
      delete($hash->{$t1});
      next;
    }
    foreach $t2 (@members) {
      next unless (exists($hash->{$t2}));
      if ($self->has_descendant($t1,$t2)) {
	delete($hash->{$t1});
	next MAXIMIZE_T1;
      }
    }
  }
  return $set;
}

# end sorting/comparison


###############################################################
# unsorted
###############################################################

###############################################################
# Type operations
###############################################################

#--------------------------------------------------------------
# lub : inherited

#--------------------------------------------------------------
# glb : inherited



###############################################################
# Accessors/manipulators
###############################################################
sub _types ($) { return $_[0]->{types}; }

sub _root ($;$) {
  my $self = shift;
  return $self->{root} unless (@_);
  my $root = shift(@_);
  $root = 'BOTTOM' unless (defined($root));
  $self->{types}{$root} = $root;
  $self->{parents}{$root} = {} unless (defined($self->{parents}{$root}));
  $self->{children}{$root} = {} unless (defined($self->{children}{$root}));
  return $self->{root} = $root;
}
*root = \&_root;

# \%prts_by_type = $h->_parents()
# \%type_prts = $h->_parents($type)
sub _parents ($;$) {
  return
    (exists($_[1])
     ? (exists($_[0]->{parents}{$_[1]})
	? $_[0]->{parents}{$_[1]}
	: undef)
     : $_[0]->{parents});
}

# \%kids_by_type = $h->_children()
# \%type_kids = $h->children($type)
sub _children ($;$) {
  return
    (exists($_[1])
     ? (exists($_[0]->{children}{$_[1]})
	? $_[0]->{children}{$_[1]}
	: undef)
     : $_[0]->{children});
}


# * C<_attributes()>, C<_attributes($type)>, C<_attributes($type, $hashref)>
sub _attributes ($;$$) {
  return
    (exists($_[1])
     ? (defined($_[1])
	? (exists($_[2])
	   ? (defined($_[2])
	      ? $_[0]->{attrs}{$_[1]} = $_[2]
	      : delete($_[0]->{attrs}{$_[1]}))
	   : $_[0]->{attrs}{$_[1]})
	: undef)
     : $_[0]->{attrs});
}


1;
__END__
