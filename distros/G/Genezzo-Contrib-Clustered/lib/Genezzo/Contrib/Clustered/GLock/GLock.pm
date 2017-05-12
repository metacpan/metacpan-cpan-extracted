#!/usr/bin/perl
#
# copyright (c) 2005, Eric Rollins, all rights reserved, worldwide
#
#
#

package Genezzo::Contrib::Clustered::GLock::GLock;

use Carp;
use strict;
use warnings;

use Genezzo::Util;

our $LOCKER =   1;    # IPC::Locker
our $DLM =      2;    # opendlm
our $NONE =     3;    # no locking (still error check)
our $UR =       4;    # UNIX fcntl record locking
our $IMPL = $NONE;      # this should be $NONE in distribution

if($IMPL == $LOCKER){
  require IPC::Locker;
}elsif($IMPL == $DLM){
  require Genezzo::Contrib::Clustered::GLock::GLockDLM;
}elsif($IMPL == $UR){
  require Genezzo::Contrib::Clustered::GLock::GLockUR;
}

# options lock:  lockName
#         block: 1 for blocking (default)
sub new {
  @_ >= 1 or croak 'usage:  GLock->new({options})';
  my $proto = shift;
  my $tmp = { @_,};
  my $lockName = $tmp->{lock};
  $lockName = "lock" if !defined($lockName);
  my $block = $tmp->{block};
  $block = 1 if !defined($block);
  my $class = ref($proto) || $proto;
  my $self = {};
  $self->{block} = $block;
  $self->{lock} = $lockName;

  if($IMPL == $LOCKER){
    my $l = IPC::Locker->new(lock => $lockName, block => $block,
    	timeout => 0);
    $self->{impl} = $l;
  }elsif($IMPL == $DLM){
  }

  bless $self, $class;
  return $self;
}

# options:  shared:     1 for shared lock 
# 			0 for exclusive (default)
# returns undef for failure
sub lock{
  my $self = shift;

  my $tmp = { @_,};
  my $shared = $tmp->{shared};
  $shared = 0 if !defined($shared);

  if(defined($self->{"shared"})){
    croak "GLock::lock():  lock $self->{lock} already locked in mode $self->{shared}";
  }

  whisper "GLock::lock($self->{lock} shared=$shared block=$self->{block})\n";

  if($IMPL == $LOCKER){
    my $l = $self->{impl}; 
    $self->{shared} = $shared;
    return $l->lock();
  }elsif($IMPL == $DLM){
    my $l = Genezzo::Contrib::Clustered::GLock::GLockDLM::dlm_lock(
        $self->{lock},$shared,$self->{block});

    if($l == 0){
      $l = undef;
    }

    $self->{impl} = $l;
    $self->{shared} = $shared;
    return $l;
  }elsif($IMPL == $UR){
    my $l = Genezzo::Contrib::Clustered::GLock::GLockUR::ur_lock(
        $self->{lock},$shared,$self->{block});

    if($l == 0){
      $l = undef;
    }

    $self->{impl} = $l;
    $self->{shared} = $shared;
    return $l;
  }else{
    $self->{shared} = $shared;
    return 1;
  }

  return undef;
}

sub unlock {
  my $self = shift;

  if(!defined($self->{shared})){
    croak "GLock::unlock():  lock $self->{lock} not locked";
  }

  whisper "GLock::unlock($self->{lock})\n";

  $self->{shared} = undef;

  if($IMPL == $LOCKER){
    my $l = $self->{impl};
    $l->unlock();
  }elsif($IMPL == $DLM){
    my $r = Genezzo::Contrib::Clustered::GLock::GLockDLM::dlm_unlock(
        $self->{impl});
  }elsif($IMPL == $UR){
    my $r = Genezzo::Contrib::Clustered::GLock::GLockUR::ur_unlock(
        $self->{impl});
  }else{
  }

  return 1;
}

# promote shared to exclusive
# returns undef for failure
sub promote {
  my $self = shift;
  my $tmp = { @_,};

  if(!defined($self->{shared}) || ($self->{shared} != 1)){
    croak "GLock::promote():  lock $self->{lock} not locked in shared mode";
  }

  whisper "GLock::promote($self->{lock} block=$self->{block})\n";

  if($IMPL == $LOCKER){
    my $l = $self->{impl};
    $self->{"shared"} = 0;
    # nothing to do
    return $l;
  }elsif ($IMPL == $DLM){
    my $l = Genezzo::Contrib::Clustered::GLock::GLockDLM::dlm_promote(
        $self->{lock},$self->{impl},$self->{block});
    if($l == 0){ 
      $l = undef;
    }

    $self->{"shared"} = 0;
    return $l;
  }elsif ($IMPL == $UR){
    my $l = Genezzo::Contrib::Clustered::GLock::GLockUR::ur_promote(
        $self->{lock},$self->{impl},$self->{block});
    if($l == 0){ 
      $l = undef;
    }

    $self->{"shared"} = 0;
    return $l;
  }else{
    $self->{"shared"} = 0;
    return 1;
  }

  return undef;
}

# demote exclusive to shared
# returns undef for failure
sub demote {
  my $self = shift;
  my $tmp = { @_,};

  if(!defined($self->{shared}) || ($self->{shared} != 0)){
    croak "GLock::demote():  lock $self->{lock} not locked in exclusive mode";
  }

  whisper "GLock::demote($self->{lock} block=$self->{block})\n";

  if($IMPL == $LOCKER){
    my $l = $self->{impl};
    # nothing to do
    $self->{"shared"} = 1;
    return $l;
  }elsif ($IMPL == $DLM){
    my $l = Genezzo::Contrib::Clustered::GLock::GLockDLM::dlm_demote(
        $self->{lock},$self->{impl},$self->{block});
    if($l == 0){ 
      $l = undef;
    }

    $self->{"shared"} = 1;
    return $l;
  }elsif ($IMPL == $UR){
    my $l = Genezzo::Contrib::Clustered::GLock::GLockUR::ur_demote(
        $self->{lock},$self->{impl},$self->{block});
    if($l == 0){ 
      $l = undef;
    }

    $self->{"shared"} = 1;
    return $l;
  }else{
    $self->{"shared"} = 1;
    return 1;
  }

  return undef;
}

sub isShared {
  my $self = shift;
  return $self->{shared};
}

sub ast_poll {
  if($IMPL == $LOCKER){
    return 0;
  }elsif ($IMPL == $DLM){
    return Genezzo::Contrib::Clustered::GLock::GLockDLM::dlm_ast_poll();
  }elsif ($IMPL == $UR){
    return 1;  # assume notification only sent when restart is needed
  }else{
    return 0;
  }
}

sub set_notify {
  if($IMPL == $LOCKER){
    return 0;
  }elsif ($IMPL == $DLM){
    return Genezzo::Contrib::Clustered::GLock::GLockDLM::dlm_set_notify();
  }else{
    return 0;
  }
}

1;

__DATA__

=head1 NAME

Genezzo::Contrib::Clustered::GLock::GLock - Generic locking for Genezzo

=head1 SYNOPSIS

    $curLock = new GLock(lock => $lockName, block => 1);
    $curLock->lock(shared => 0);
    $curLock->promote();
    $curLock->unlock();

=head1 DESCRIPTION

Basic locking for Genezzo.  Available implementations include None (default), Unix Record fcntl, and OpenDLM.  None is acceptable when only a single process accesses the database.  Unix Record should be used when multiple proccesses on a single machine access the database.  DLM is required when processes on multiple machines access the database.

=head1 FUNCTIONS

=over 4

=item new (lock => NAME, block => BLOCKING)

Creates new lock with name NAME.  Blocking if BLOCKING=1 (default).
Depending on implementation, new or following lock() may be blocking.

=item lock (shared => SHARED)

Locks lock.  Shared if SHARED=1, otherwise Exclusive (default).
Returns undef for failure.

=item promote

Promotes lock from Shared to Exclusive.  Returns undef for failure.

=item demote

Demotes lock from Exclusive to Shared.  Returns undef for failure.

=item unlock

Unlocks lock. 

=back

=item ast_poll

Returns 1 if recent asyncronous request for lock held by process.  0 otherwise.

=head1 LIMITATIONS

Edit $IMPL to choose implementation.  This will eventually be configured
from somewhere else.

IPC::Locker implementation is not currently being maintained or tested.

=head1 AUTHOR

Eric Rollins, rollins@acm.org

Copyright (c) 2005 Eric Rollins.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to rollins@acm.org

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut

