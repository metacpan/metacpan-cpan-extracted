# --8<--8<--8<--8<--
#
# Copyright (C) 2008 Smithsonian Astrophysical Observatory
#
# This file is part of Decision::Depends
#
# Decision-Depends is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Decision::Depends::List;

require 5.005_62;
use strict;
use warnings;

use Carp;

our $VERSION = '0.20';

use Decision::Depends::Time;
use Decision::Depends::Var;
use Decision::Depends::Sig;

## no critic ( ProhibitAccessOfPrivateData )

# Preloaded methods go here.

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my $self = bless {}, $class;

  $self->{state} = shift;

  $self->{list} = [];

  $self;
}

sub Verbose
{
  $_[0]->{state}->Verbose;
}

sub add
{
  my ( $self, $obj ) = @_;

  push @{$self->{list}}, $obj;
}

sub ndeps
{
  @{shift->{list}};
}

sub depends
{
  my ( $self, $targets ) = @_;

  my %depends;
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  for my $target ( @$targets )
  {
    print STDOUT "  Target ", $target->file, "\n"
      if $self->Verbose;

    # keep track of changed dependencies
    my %deps = ( time => [],
		 var => [],
		 sig => [] );


    my $time = $target->getTime;

    unless( defined $time )
    {
      print STDOUT "    target `", $target->file,
      "' doesn't exist\n" if $self->Verbose;

      $depends{$target->file} = \%deps;
    }
    else
    {
      for my $dep ( @{$self->{list}} )
      {
	my ( $type, $deps ) = $dep->depends( $target->file, $time );
	push @{$deps{$type}}, @$deps;
      }

      my $ndeps = 0;
      map { $ndeps += @{$deps{$_}} } qw( var time sig );

      # return list of dependencies.  if there are none, return
      # the empty hash if force is one
      $depends{$target->file} = \%deps
	if $ndeps or $target->force || $self->{state}->Force;
    }
  }

  \%depends;
}



sub update
{
  my ( $self, $targets ) = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  for my $target ( @$targets )
  {
    print STDOUT ("Updating target ", $target->file, "\n" )
      if $self->Verbose;

    $_->update( $target->file ) foreach @{$self->{list}};
  }
}

1;
