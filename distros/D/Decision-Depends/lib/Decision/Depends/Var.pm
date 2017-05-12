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

package Decision::Depends::Var;
use Data::Compare ();

require 5.005_62;
use strict;
use warnings;

use Carp;
use Clone qw( clone );

our $VERSION = '0.20';

# regular expression for a floating point number
our $RE_Float = qr/^[+-]?(\d+[.]?\d*|[.]\d+)([dDeE][+-]?\d+)?$/;

our %attr = ( depend => 1,
	      depends => 1,
	      force => 1,
	      var => 1,
	      case => 1,
	      numcmp => undef,
	      strcmp => undef,
	      no_case => 1,
	    );

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my ( $state, $spec ) = @_;

  my $self = { %$spec, state => $state };

  # ensure that no bogus attributes are set
  my @notok = grep { ! exists $attr{$_} } keys %{$self->{attr}};

  # use the value of the var attribute if it's set (i.e. not 1)
  if ( '1' ne $self->{attr}{var} )
  {
    croak( __PACKAGE__, '->new: too many variable names(s): ',
	   join(', ', $self->{attr}{var}, @notok ) ) if @notok;
  }

  # old style: the variable name is an attribute.
  else
  {
    croak( __PACKAGE__, '->new: too many variable names(s): ',
	   join(', ', @notok ) ) if @notok > 1;

    croak( __PACKAGE__, 
	   ": must specify a variable name for `$self->{val}'" )
      unless @notok == 1;
    $self->{attr}{var} = $notok[0];
  }

  croak( __PACKAGE__,
	 ": specify only one of the attributes `-numcmp' or `-strcmp'" )
    if exists $self->{attr}{numcmp} && exists $self->{attr}{strcmp};

  # comparison attributes for arrays and hashes are not allowed
  croak( __PACKAGE__,
	 ": comparison attributes on variable dependencies on hash or arrays are not allowed" )
    if ref($self->{val}) =~ m/^(HASH|ARRAY)$/
           && grep { exists $self->{attr}{$_}} qw( case numcmp strcmp no_case );

  $self->{val} = clone( $self->{val} ) if ref $self->{val};

  bless $self, $class;
}

sub depends
{
  my ( $self, $target ) = @_;

  my $var = $self->{attr}{var};

  my $state = $self->{state};

  my $prev_val = $state->getVar( $target, $var );

  my @deps = ();

  if ( defined $prev_val )
  {
    my $is_not_equal = 
      ( exists $self->{attr}{force} ? 
	$self->{attr}{force} : $state->Force ) ||
	cmpVar( exists $self->{attr}{case},
		$self->{attr}{numcmp},
		$self->{attr}{strcmp},
		$prev_val, $self->{val} );

    if ( $is_not_equal )
    {
        my $curval = 
          ref $self->{val} ? YAML::Dump( $self->{val} )
                           : '(' . $self->{val} . ')';
        my $preval = 
          ref $prev_val ? YAML::Dump( $prev_val )
                        : '(' . $prev_val . ')';
      print STDOUT 
	"    variable `", $var, "' is now $curval, was $preval\n"
	  if $state->Verbose;

      push @deps, $var;
    }
    else
    {
      print STDOUT "    variable `", $var, "' is unchanged\n"
	if $state->Verbose;
    }
  }
  else
  {
    print STDOUT "    No value on file for variable `", $var, "'\n"
	if $state->Verbose;
      push @deps, $var;
  }

  var => \@deps;
}

sub cmp_strVar
{
  my ( $case, $var1, $var2 ) = @_;
  
  ( $case ? uc($var1) ne uc($var2) : $var1 ne $var2 );
}

sub cmp_numVar
{
  my ( $var1, $var2 ) = @_;
  
  $var1 != $var2;
}

sub cmpVar
{
  my ( $case, $num, $str, $var1, $var2 ) = @_;

  # references that aren't the same
  if ( ref $var1 ne ref $var2 )
  {
      return 1;
  }

  # references
  elsif ( ref $var1 )
  {
      ! Data::Compare::Compare( $var1, $var2 );
  }

  elsif ( defined $num && $num )
  {
    cmp_numVar( $var1, $var2 );
  }

  elsif ( defined $str && $str )
  {
    cmp_strVar( $case, $var1, $var2 );
  }

  elsif ( $var1 =~ /$RE_Float/o && $var2 =~ /$RE_Float/o) 
  {
    cmp_numVar( $var1, $var2 );
  }

  else
  {
    cmp_strVar( $case, $var1, $var2 );
  }
}

sub update
{
  my ( $self, $target ) = @_;

  $self->{state}->setVar( $target, $self->{attr}{var}, $self->{val} );
}

sub pprint
{
  my $self = shift;

  "$self->{attr}{var} = $self->{val}";
}

1;
