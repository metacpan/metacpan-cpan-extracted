#!/usr/bin/perl
#
# copyright (c) 2005, Eric Rollins, all rights reserved, worldwide
#
#
#

# GTXLock.pm
# retains hash of all locks held by transaction
# hashes lock names

package Genezzo::Contrib::Clustered::GLock::GTXLock;

use Carp;
use strict;
use warnings;
use Genezzo::Contrib::Clustered::GLock::GLock;
use Genezzo::Util;

sub new {
  @_ >= 1 or croak 'usage:  GTXLock->new()';
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  $self->{locks} = {};
  bless $self, $class;
  whisper "Genezzo::Contrib::Clustered::GLock::GTXLock::new()";
  return $self;
}

our $LOCK_HASH_SIZE = 10000;

# options:  lock:  lockname (currently block number)
#           shared:  1 for shared lock
#                    0 for exclusive (default)
sub lock {
  my $self = shift;
  my $tmp = { @_,};
  my $lock = $tmp->{lock};
  my $shared = $tmp->{shared};
  $shared = 0 if !defined($shared);

  whisper "Genezzo::Contrib::Clustered::GLock::GTXLock::lock(lock => $lock, shared => $shared)";

  my $hashKey = $lock % $LOCK_HASH_SIZE;
  my $curLock = $self->{locks}->{$hashKey};

  if(defined($curLock)){
    if($shared == 1){
      return 1;  # current mode is at least SHARED
    }

    my $curShared = $curLock->isShared();

    if($curShared == 0){
      return 1;   # already EX
    }

    # $shared == 0 and $curShared == 1 => need to promote
    whisper "Genezzo::Contrib::Clustered::GLock::GTXLock::lock promote $lock (hashKey = $hashKey)";
    $curLock->promote() or croak "GTXLock::lock($lock) failed promote";
  }else{
    my $lockName = "GBL$hashKey";
    whisper "Genezzo::Contrib::Clustered::GLock::GTXLock::lock new $lock (hashKey = $hashKey)";
    $curLock = new Genezzo::Contrib::Clustered::GLock::GLock(lock => $lockName, block => 1);

    defined($curLock) or croak "GTXLock::lock($lock) failed new";

    $curLock->lock(shared => $shared) or croak "GTXLock::lock($lock) failed lock";
    $self->{locks}->{$hashKey} = $curLock;
  }

  return 1;
}

sub unlockAll{
  my $self = shift;
  my $locks = $self->{locks};

  whisper "Genezzo::Contrib::Clustered::GTXLock::unlockAll()";

  my $key;
  my $value;

  while(($key,$value) = each(%$locks)){
    $value->unlock() or croak "GTXLock::unlock() failed unlock($key)";
  }

  $self->{locks} = {};

  return 1;
}

sub demoteAll{
  my $self = shift;
  my $locks = $self->{locks};

  whisper "Genezzo::Contrib::Clustered::GTXLock::demoteAll()";

  my $key;
  my $value;

  while(($key,$value) = each(%$locks)){
    if(!$value->isShared()){
      $value->demote() or croak "GTXLock::demoteAll() failed demote($key)";
    }
  }

  return 1;
}

1;

__DATA__

=head1 NAME

Genezzo::Contrib::Clustered::GLock::GTXLock - Transaction locking for Genezzo

=head1 SYNOPSIS

   my $gtxLock = GTXLock->new();
   $gtxLock->lock(lock => $bnum, shared => 1);
   $gtxLock->unlockAll();

=head1 DESCRIPTION

Retains hash of all locks held by transaction.

=head1 FUNCTIONS

=over 4

=item new

Creates GTXLock

=item lock (lock => NAME, shared => SHARED)

Locks lock with name NAME.  Shared if SHARED=1, otherwise Exclusive (default).
Uses a blocking lock call.  If lock is currently held Shared promotes to 
Exclusive.  Adds lock to hash of all locks held by object.

=item unlockAll

Unlocks all locks held by object.

=item demoteAll

Demotes all locks held by object to shared mode.

=back

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

