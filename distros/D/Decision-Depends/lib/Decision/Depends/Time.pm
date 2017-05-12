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

package Decision::Depends::Time;

require 5.005_62;
use strict;
use warnings;

use Carp;

## no critic ( ProhibitAccessOfPrivateData )

our $VERSION = '0.20';

our %attr = ( depend => 1,
	      depends => 1,
	      force => 1,
	      time => 1,
	      orig => 1 );

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my ( $state, $spec ) = @_;

  my $self = { %$spec, state => $state };


  # only accept string values
  croak( __PACKAGE__, 
      "->new: bad type for Time dependency `$self->{val}': must be scalar" )
    unless '' eq ref $self->{val};

  # ensure that no bogus attributes are set
  my @notok = grep { ! exists $attr{$_} } keys %{$self->{attr}};
  croak( __PACKAGE__, 
	 "->new: bad attributes for Time dependency `$self->{val}': ",
	 join( ', ', @notok ) ) if @notok;

  # ensure that the dependency exists
#  croak( __PACKAGE__, "->new: non-existant dependency: $self->{val}" )
#      unless -f $self->{val};

  bless $self, $class;
}

sub depends
{
  my ( $self, $target, $time )  = @_;

  my $state = $self->{state};

  my $depfile = $self->{val};
  my $depfiles =
     exists $self->{attr}{orig} ?
       [ $depfile ] : $state->getSLinks( $depfile );

  my $links = $depfile ne $depfiles->[0];

  my @deps = ();

  # loop through dependencies, check if any is younger than the target
  for my $dep ( @$depfiles )
  {
    my $deptag = $dep;
    $deptag .= " (slinked to `$depfile')" if $links;

    my @sb;
    my $dtime = 
      $state->getTime( $dep ) ||
	((@sb = stat( $dep )) ? $sb[9] : undef);

    croak( __PACKAGE__, "->cmp: non-existant dependency: $dep" )
      unless defined $dtime;

    $state->setTime( $dep, $dtime );

    my $is_not_equal = 
      ( exists $self->{attr}{force} ? 
	$self->{attr}{force} : $state->Force )
	|| $dtime > $time;

    # if time of dependency is greater than of target, it's younger
    if ( $is_not_equal )
    {
      print STDOUT "    file `$deptag' is younger\n" if $state->Verbose;
      push @deps, $dep;
    }
    else
    {
      print STDOUT "    file `$deptag' is older\n" if $state->Verbose;
    }
  }

  time => \@deps;
}

sub update
{
  # do nothing; keep DepXXX class API clean
}

sub pprint
{
  my $self = shift;

  $self->{val};
}

1;
