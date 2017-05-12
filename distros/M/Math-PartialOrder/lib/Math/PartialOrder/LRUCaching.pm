# -*- Mode: Perl -*-

#
# Copyright (c) 2001, Bryan Jurish.  All rights reserved.
#
# This package is free software.  You may redistribute it
# and/or modify it under the same terms as Perl itself.
#

###############################################################
#
#      File: Math::PartialOrder::LRUCaching.pm
#    Author: Bryan Jurish <jurish@ling.uni-potsdam.de>
#
# Description: Math::PartialOrder class using hashrefs
#              objects to store hierarchy information,
#              caches inheritance- and operation-lookups
#              using Tie::Cache.
#
###############################################################


package Math::PartialOrder::LRUCaching;
# System modules
use Carp;
#require Exporter;
# 3rd party exstensions
use Tie::Cache;
# user extension modules
use Math::PartialOrder::Caching qw($CACHE_KEY_SEP);
@ISA       = qw(Math::PartialOrder::Caching);
@EXPORT    = qw();
@EXPORT_OK = qw();

###############################################################
# Package-Globals
###############################################################

our $VERSION = 0.01;

# $CACHE_KEY_SEP : imported from Math::PartialOrder::Caching
our $IN_CACHE_ATTRS = { MaxCount => 5000 };
our $OP_CACHE_ATTRS = { MaxCount => 5000 };


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
#       _incache   => { 'type1,type2' => $has_anc_bool, ... }
#       _opcache   => { 'op,type1,type2' => \@results }
#     }
###############################################################

#----------------------------------------------------------------------
# new( \%args )
#   + initialization routine: returns the object
#   + keys of \%args
#     + inherited:
#        root => $typ
#     + new
#        incache_attrs => \%attrs
#        opcache_attrs => \%attrs
#----------------------------------------------------------------------
sub new ($;$) {
  my ($proto,$args) = @_;
  my $self = $proto->SUPER::new($args);

  # tie up caches
  tie %{$self->{incache}}, Tie::Cache, $args{incache_attrs}||$IN_CACHE_ATTRS;
  tie %{$self->{opcache}}, Tie::Cache, $args{opcache_attrs}||$OP_CACHE_ATTRS;

  return $self;
}



###############################################################
# Hierarchy Maintainance: Type Operations
###############################################################
#--------------------------------------------------------------
# types : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# add : inherited from Math::PartialOrder::Caching

#--------------------------------------------------------------
# has_type : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# add_parents : inherited from Math::PartialOrder::Caching

#--------------------------------------------------------------
# move : inherited from Math::PartialOrder::Caching

#--------------------------------------------------------------
# remove : inherited from Math::PartialOrder::Caching

#--------------------------------------------------------------
# parents : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# children : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# has_parent : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# has_child : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# has_ancestor : inherited from Math::PartialOrder::Caching


#--------------------------------------------------------------
# has_descendant : inherited from Math::PartialOrder::Caching

#--------------------------------------------------------------
# get_attributes : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# get_attribute : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# set_attribute : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# assign : inherited from Math::PartialOrder::Caching


#--------------------------------------------------------------
# merge : inherited from Math::PartialOrder::Caching

#--------------------------------------------------------------
# clear : inherited from Math::PartialOrder::Caching

###############################################################
# Additional Hierarchy Maintainence Operations
###############################################################
#--------------------------------------------------------------
# ensure_types : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _ancestors($type) => $hashref : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _descendants($type) => $hashref : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _minimize : inherited from Math::PartialOrder:Set

#--------------------------------------------------------------
# _maximize : inherited from Math::PartialOrder:Set


###############################################################
# Hierarchy Operations
###############################################################

#--------------------------------------------------------------
# _lub : inherited from Math::PartialOrder::Caching

#--------------------------------------------------------------
# _glb : inherited from Math::PartialOrder::Caching


###############################################################
# Hierarchy operation utilities
###############################################################

###############################################################
# Accessors/manipulators
###############################################################

#--------------------------------------------------------------
# _types : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _root, root : inherited from Math::PartialOrder::Caching

#--------------------------------------------------------------
# _parents : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _children : inherited from Math::PartialOrder::Std

#--------------------------------------------------------------
# _attributes : inherited from Math::PartialOrder::Std


#--------------------------------------------------------------
# _incache : inherited from Math::PartialOrder::Caching
# _get_cached_in : inherited from Math::PartialOrder::Caching
# _set_cached_in : inherited from Math::PartialOrder::Caching


#--------------------------------------------------------------
# _opcache : inherited from Math::PartialOrder::Caching
# _get_cached_op : inherited from Math::PartialOrder::Caching
# _set_cached_op : inherited from Math::PartialOrder::Caching


#--------------------------------------------------------------
# _clear_cached, _clear_cache : inherited from Math::PartialOrder::Caching


1;
__END__

