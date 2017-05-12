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

package Decision::Depends::Sig;

require 5.005_62;
use strict;
use warnings;

use Carp;
use Digest::MD5;
use IO::File;

## no critic ( ProhibitAccessOfPrivateData )

our $VERSION = '0.20';

our %attr = ( depend => 1,
	      depends => 1,
	      force => 1,
	      sig => 1 );

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my ( $state, $spec ) = @_;

  my $self = { %$spec, state => $state };

  # only accept string values
  croak( __PACKAGE__, 
      "->new: bad type for Signature dependency `$self->{val}': must be scalar" )
    unless '' eq ref $self->{val};

  # ensure that no bogus attributes are set
  my @notok = grep { ! exists $attr{$_} } keys %{$self->{attr}};
  croak( __PACKAGE__, 
      "->new: bad attributes for Signature dependency `$self->{val}': ",
	 join( ', ', @notok ) ) if @notok;


  bless $self, $class;
}

sub depends
{
  my ( $self, $target, $time ) = @_;

  my $state = $self->{state};

  croak( __PACKAGE__, 
	 "->depends: non-existant signature file `$self->{val}'" )
    unless -f $self->{val};

  my @deps = ();

  my $prev_val = $state->getSig( $target, $self->{val} );

  if ( defined $prev_val )
  {
    my $is_not_equal = 
      ( exists $self->{attr}{force} ?  
	$self->{attr}{force} : $state->Force ) ||
	cmpSig( $prev_val, mkSig( $self->{val} ) );

    if ( $is_not_equal )
    {
      print STDOUT "    signature file `", $self->{val}, "' has changed\n"
	if $state->Verbose;
      push @deps, $self->{val};
    }
    else
    {
      print STDOUT "    signature file `", $self->{val}, "' is unchanged\n"
	if $state->Verbose;
    }

  }
  else
  {
    print STDOUT "    No signature on file for `", $self->{val}, "'\n"
	if $state->Verbose;
      push @deps, $self->{val};
  }

  sig => \@deps;

}

sub cmpSig
{
  $_[0] ne $_[1];
}

sub mkSig
{
  my ( $file ) = @_;

  my $fh = IO::File->new( $file, 'r' )
    or croak( __PACKAGE__, "->mkSig: non-existant signature file `$file'" );

  Digest::MD5->new->addfile($fh)->hexdigest;
}

sub update
{
  my ( $self, $target ) = @_;

  $self->{state}->setSig( $target, $self->{val}, mkSig( $self->{val} ) );
}

sub pprint
{
  my $self = shift;

  $self->{val};
}

1;
