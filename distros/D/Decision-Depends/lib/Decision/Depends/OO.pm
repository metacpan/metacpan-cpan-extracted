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

package Decision::Depends::OO;

require 5.005_62;
use strict;
use warnings;

require Exporter;

## no critic ( ProhibitAccessOfPrivateData )

our $VERSION = '0.20';

use Carp;
use Scalar::Util qw( reftype );
use Tie::IxHash;

use Decision::Depends::State;
use Decision::Depends::List;
use Decision::Depends::Target;



# regular expression for a floating point number
our $RE_Float = qr/^[+-]?(\d+[.]?\d*|[.]\d+)([dDeE][+-]?\d+)?$/;

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my $self = { Attr => { Cache => 0,
			 DumpFiles => 0,
			 Pretend => 0,
			 Verbose => 0,
			 Force => 0,
			 File => undef
		       }
	     };
  bless $self, $class;

  $self->{State} = Decision::Depends::State->new();

  $self->configure( @_ );

  $self;
}

sub Verbose
{
  $_[0]->{State}->Verbose;
}

sub Pretend
{
  $_[0]->{State}->Pretend;
}

sub configure
{
  my $self = shift;

  return unless @_;

  my @opts = @_;
  my %attr;
  my ($key, $val);

  while ( @opts )
  {
    my $opt = shift @opts;

    if ( 'HASH' eq ref $opt )
    {
      my @notok = grep { ! exists $self->{Attr}{$_} } keys %$opt;
      croak( __PACKAGE__, '->configure: unknown attribute(s): ',
	     join( ', ', @notok) ) if @notok;
      $attr{$key} = $val while( ($key, $val) = each %$opt );
    }

    elsif ( 'ARRAY' eq ref $opt )
    {
      croak( __PACKAGE__, '->configure: odd number of elements in arrayref' )
	if @$opt %2;

      unshift @opts, @$opt;
    }

    else
    {
      croak( __PACKAGE__, 
	     '->configure: odd number of elements in options list' )
	unless @opts;

      croak( __PACKAGE__, "->configure: unknown attribute: `$opt'" )
	unless exists $self->{Attr}{$opt};

      $attr{$opt} = shift @opts;
    }

  }

  $self->{Attr}{$key} = $val while( ($key, $val) = each %attr );
  $self->{State}->SetAttr( \%attr );
}

sub if_dep
{
  my $self = shift;

  my ( $args, $run ) = @_;

  print STDOUT "\nNew dependency\n" if $self->Verbose;

  my @specs = $self->_build_spec_list( undef, undef, $args );

  my ( $deplist, $targets ) = $self->_traverse_spec_list( @specs );

  my $depends = $self->_depends( $deplist, $targets );

  if ( keys %$depends )
  {
    # clean up beforehand in case of Pretend
    undef $@;
    print STDOUT "Action required.\n" if $self->Verbose;
    eval { &$run( $depends) } unless $self->Pretend;
    if ( $@ )
    {
      croak $@ unless defined wantarray;
      return 0;
    }
    else
    {
      $self->_update( $deplist, $targets );
    }
  }
  else
  {
    print STDOUT "No action required.\n" if $self->Verbose;
  }
  1;
}

sub test_dep
{
  my $self = shift;
  my ( @args ) = @_;

  print STDOUT "\nNew dependency\n" if $self->Verbose;

  my @specs = $self->_build_spec_list( undef, undef, \@args );

  my ( $deplist, $targets ) = $self->_traverse_spec_list( @specs );

  my $depends = $self->_depends( $deplist, $targets );

  wantarray ? %$depends : keys %$depends;
}


# spec format is 

# -attr1 => -attr2 => value1, ...
# where value may be of the form 
#  [ -attr3 => -attr4 => value2 ]
#  attr1 and attr2 are attached to value2
# attributes may have values, 
#   '-attr=attr_value'
# by default the value is 1
# to undefine an attribute:
#  -no_attr
# additionally, each value is given an attribute "id" representing its
# position in the list (independent of attributes) and in any sublists. 
# id = [0], [0,0], [0,1,1], etc.

sub _build_spec_list
{
  my $self = shift;
  my ( $attrs, $levels, $specs ) = @_;

  $attrs = [ Tie::IxHash->new() ] unless defined $attrs;
  $levels = [ -1 ] unless defined $levels;

  my @res;

  # process target attributes
  foreach my $spec ( @$specs )
  {
    my $ref = ref $spec;
    # if it's an attribute, process it
    if ( ! $ref && $spec !~ /$RE_Float/ && 
	 $spec =~ /^-(no_)?(\w+)(?:\s*=\s*(.*))?/ )
    {
      if ( defined $1 )
      {
	$attrs->[-1]->Push( $2 => undef);
      }
      else
      {
	$attrs->[-1]->Push( $2 => defined $3 ? $3 : 1);
      }
    }

    # maybe a nested level?
    elsif ( 'ARRAY' eq $ref )
    {
      push @$attrs, Tie::IxHash->new();
      $levels->[-1]++;
      push @$levels, -1;
      push @res, $self->_build_spec_list( $attrs, $levels, $spec );
      pop @$attrs;
      pop @$levels;

      # reset attributes
      $attrs->[-1] = Tie::IxHash->new();
    }

    # a value
    elsif ( 'SCALAR' eq $ref || 'REF' eq $ref || ! $ref )
    {
      $spec = $$spec if $ref;

      $ref = ref $spec;

      if ( $ref !~ /^(|ARRAY|HASH)$/ )
      {
        croak( __PACKAGE__, '::_build_spec_list:', 
	     "value can only be scalar or ref to scalar, hashref or arrayref!\n" );
      }


      $levels->[-1]++;
      my %attr;
      foreach my $lattr ( @$attrs )
      {
	my ( $key, $val );
	$attr{$_} = $lattr->FETCH($_) foreach $lattr->Keys;
      }
      delete @attr{ grep { ! defined $attr{$_} } keys %attr };
      push @res, { id => [ @$levels ], 
		   val => $spec , 
		   attr => \%attr };

      # reset attributes
      $attrs->[-1] = Tie::IxHash->new();
    }

    # hash; keys are values of last attribute specified
    elsif( 'HASH' eq $ref )
    {
      # find last attribute specified; may have to search upwards through
      # nested levels
      ( my $lattr ) = grep { defined $_->Keys(-1) } reverse @$attrs;
      croak( __PACKAGE__, '::_build_spec_list:', 
	     "can't find an attribute to assign values to with this hash!\n" )
	unless defined $lattr;

      my $attr = $lattr->Keys(-1);

      # create a new level
      while ( my ( $attrval, $lspec ) = each %$spec )
      {
	push @$attrs, Tie::IxHash->new($attr => $attrval);
	$levels->[-1]++;
	push @$levels, -1;
	push @res, $self->_build_spec_list( $attrs, $levels, [ $lspec ] );
	pop @$attrs;
	pop @$levels;
      }

      # reset attributes
      $attrs->[-1] = Tie::IxHash->new();

    }
  }

  @res;
}


sub _traverse_spec_list
{
  my $self = shift;
  my @list = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  # two phases; first the targets, then the dependencies.
  # the targets are identified as id 0.X

  my $deplist = Decision::Depends::List->new( $self->{State} );

  my @targets;

  eval {

    for my $spec ( @list )
    {
      if ( (grep { exists $spec->{attr}{$_} } qw( target targets sfile slink )) ||
	   (! exists $spec->{attr}{depend} && 0 == $spec->{id}[0] ) )
      {
	push @targets, Decision::Depends::Target->new( $self->{State}, $spec );
      }

      else
      {
	my @match = grep { defined $spec->{attr}{$_} } qw( sig var time ) ;

	if ( @match > 1 )
	{
	  $Carp::CarpLevel--;
	  croak( __PACKAGE__, 
		 "::traverse_spec_list: too many dependency classes for `$spec->{val}'" )
	}

	my $class = 'Decision::Depends::' .
	  ( @match ? ucfirst( $match[0]) : 'Time' );

	$deplist->add( $class->new( $self->{State}, $spec ) );
      }
    }
  };

  croak( $@ ) if $@;

  croak( __PACKAGE__, '::traverse_spec_list: no targets?' )
    unless @targets;

  # should we require dependencies?
  #  croak( __PACKAGE__, '::traverse_spec_list: no dependencies?' )
  #    unless $deplist->ndeps;

  ( $deplist, \@targets );
}

sub _depends
{
  my $self = shift;
  my ( $deplist, $targets ) = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  $deplist->depends( $targets );
}

sub _update
{
  my $self = shift;
  my ( $deplist, $targets ) = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  $deplist->update( $targets );

  $_->update foreach @$targets;
}

1;
