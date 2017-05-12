# -*- Mode: Perl -*-

#
# Copyright (c) 2001, Bryan Jurish.  All rights reserved.
#
# This package is free software.  You may redistribute it
# and/or modify it under the same terms as Perl itself.
#

###############################################################
#
#      File: Math::PartialOrder::Caching.pm
#    Author: Bryan Jurish <jurish@ling.uni-potsdam.de>
#
# Description: PartialOrder class using hashrefs
#              to store hierarchy information which
#              caches inheritance- and operation-lookups
#
###############################################################


package Math::PartialOrder::Caching;
# System modules
use Carp;
use Exporter;
# 3rd party exstensions
use Tie::Cache;
# user extension modules
use Math::PartialOrder::Std;
@ISA       = qw(Math::PartialOrder::Std);
@EXPORT    = qw();
@EXPORT_OK = qw($CACHE_KEY_SEP);


###############################################################
# Package-Globals
###############################################################

our $VERSION = 0.01;

our $CACHE_KEY_SEP = ',';


###############################################################
# Initialization
#   + object structure:
#     {
#       # --- INHERITED ---
#       types      => Set::Hashed
#       root       => scalar
#       parents    => { type1 => {p1a=>p1a,...}, ... }
#       children   => { type1 => {c1a=>c1a,...}, ... }
#       attributes => { type1 => { attr1.1 => val1.1, ... }, ... }
#       # --- NEW ---
#       incache    => { 'type1,type2' => $has_anc_bool, ... }
#       opcache    => { 'op,type1,type2' => \@result }
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
		    attrs => {},
		    # --- NEW ---
		    incache => {},
		    opcache => {},
		   }, $class;
  # root node
  $self->_root($args->{root}||'BOTTOM');

  return $self;
}



###############################################################
# Hierarchy Maintainance: Type Operations
###############################################################
#--------------------------------------------------------------
# types : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
sub add ($$@) {
  my $self = shift;
  $self->_clear_cached();
  return $self->SUPER::add(@_);
}

#--------------------------------------------------------------
# has_type : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
sub add_parents ($$@) {
    my $self = shift;
    $self->_clear_cached();
    return $self->SUPER::add_parents(@_);
}

#--------------------------------------------------------------
sub move ($$@) {
  my $self = shift;
  $self->_clear_cached();
  return $self->SUPER::move(@_);
}

#--------------------------------------------------------------
sub remove ($@) {
  my $self = shift;
  return $self unless (@_); # not really deleting anything
  $self->_clear_cached();
  return $self->SUPER::remove(@_);
}

#--------------------------------------------------------------
# parents : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# children : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# has_parent : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# has_child : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
sub has_ancestor ($$$) {
  my ($cached);
  return (defined($_[1]) && defined($_[2]) &&
	  $_[0]->has_types($_[1],$_[2])
	  &&
	  defined($cached = $_[0]->_get_cached_in($_[1],$_[2]))
	  ? $cached
	  : $_[0]->_set_cached_in($_[1], $_[2],
				  $_[0]->SUPER::has_ancestor($_[1],$_[2])));
}


#--------------------------------------------------------------
sub has_descendant ($$$) { return $_[0]->has_ancestor(@_[2,1]); }

#--------------------------------------------------------------
# get_attributes : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# get_attribute : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# set_attribute : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
sub assign ($$) {
  my ($h1,$h2) = @_;
  $h1->_clear_cache();
  return $h1->SUPER::assign($h2);
}



#--------------------------------------------------------------
sub merge ($@) {
  my $h1 = shift;
  $h1->_clear_cache();
  return $h1->SUPER::merge(@_);
}

#--------------------------------------------------------------
sub clear ($) {
  my $self = shift;
  $self->_clear_cache();
  return $self->SUPER::clear();
}

###############################################################
# Additional Hierarchy Maintainence Operations
###############################################################
#--------------------------------------------------------------
# ensure_types : inherited from Math::PartialOrder

#--------------------------------------------------------------
# _ancestors($type) => $hashref : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _descendants($type) => $hashref : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _minimize : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _maximize : inherited from Math::PartialOrder::Std


###############################################################
# Hierarchy Operations
###############################################################

#--------------------------------------------------------------
# lub
sub _lub ($$$) {
  my ($cached);
  return
    (defined($cached = $_[0]->_get_cached_op('lub',$_[1],$_[2]))
     ? (@$cached)
     : (@{$_[0]->_set_cached_op('lub', $_[1], $_[2],
				[$_[0]->SUPER::_lub($_[1],$_[2])])}));
}


#--------------------------------------------------------------
# glb
sub _glb ($$$) {
  my ($cached);
  return
    (defined($cached = $_[0]->_get_cached_op('glb',$_[1],$_[2]))
     ? (@$cached)
     : (@{$_[0]->_set_cached_op('glb', $_[1], $_[2],
				[$_[0]->SUPER::_glb($_[1],$_[2])])}));
}


###############################################################
# Hierarchy operation utilities
###############################################################

###############################################################
# Accessors/manipulators
###############################################################

#--------------------------------------------------------------
# _types : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
sub _root ($;$) {
  my $self = shift;
  return $self->{root} unless (@_);
  $self->_clear_cache();
  return $self->SUPER::_root(@_);
}
*root = \&_root;

#--------------------------------------------------------------
# _parents : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _children : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _attributes : inherited from Math::PartialOrder::Std


#--------------------------------------------------------------
sub _incache ($) { return $_[0]->{incache}; }
sub _get_cached_in ($$$) {
  return
    exists($_[0]->{incache}{$_[1].$CACHE_KEY_SEP.$_[2]})
      ? $_[0]->{incache}{$_[1].$CACHE_KEY_SEP.$_[2]}
      : undef;
}
sub _set_cached_in ($$$$) {
  return
    $_[0]->{incache}{$_[1].$CACHE_KEY_SEP.$_[2]} = $_[3];
}



#--------------------------------------------------------------
sub _opcache ($) { return $_[0]->{opcache}; }
sub _get_cached_op ($$$$) {
  return
    exists($_[0]->{opcache}{$_[1].$CACHE_KEY_SEP.$_[2].$CACHE_KEY_SEP.$_[3]})
      ? $_[0]->{opcache}{$_[1].$CACHE_KEY_SEP.$_[2].$CACHE_KEY_SEP.$_[3]}
      : undef;
}
sub _set_cached_op ($$$$$) {
  return
    $_[0]->{opcache}{$_[1].$CACHE_KEY_SEP.$_[2].$CACHE_KEY_SEP.$_[3]} = $_[4];
}




#--------------------------------------------------------------
*_clear_cached = \&_clear_cache;
sub _clear_cache ($) {
  %{$_[0]->{incache}} = ();
  %{$_[0]->{opcache}} = ();
}




1;
__END__

