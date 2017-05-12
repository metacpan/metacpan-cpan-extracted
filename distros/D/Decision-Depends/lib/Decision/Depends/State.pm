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

package Decision::Depends::State;

require 5.005_62;
use strict;
use warnings;

## no critic ( ProhibitAccessOfPrivateData )

use YAML qw();
use IO::File;
use Carp;

our $VERSION = '0.20';

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
	      Attr => { Cache => 0,
			DumpFiles => 0,
			Pretend => 0,
			Verbose => 0,
			Force => 0,
			File => undef
		      },
	      SLink => {},
	      Files => {},
	      Sig   => {},
	      Var   => {},
	     };

  bless $self, $class;

  my $attr = 'HASH' eq ref $_[-1] ? pop @_ : {} ;

  my ( $file ) = @_;

  $self->SetAttr( $attr );
  $self->LoadState( );

  $self;
}

sub SetAttr
{
  my ( $self, $attr ) = @_;

  return unless defined $attr;

  croak( __PACKAGE__, '->SetAttr: attribute not a hash ref')
	 unless 'HASH' eq ref $attr;

    my @notok = grep { ! exists $self->{Attr}{$_} } keys %$attr;
  croak( __PACKAGE__, '->SetAttr: unknown attribute(s): ',
	 join( ', ', @notok) ) if @notok;

  my ($key, $val);
  $self->{Attr}{$key} = $val while( ($key, $val) = each %$attr );
  $self->{Attr}{Cache} = 1 if $self->{Attr}{Pretend};

  $self->LoadState() if exists $attr->{File};
}

sub LoadState
{
  my ( $self ) = @_;

  my $file = $self->{Attr}{File};

  my $state = defined $file && -f $file
    ? YAML::LoadFile($file)
    : { map { $_ => {} } qw( Sig Var Files ) };

  $self->{SLink} = {};
  $self->{Sig} = $state->{Sig};
  $self->{Var} = $state->{Var};
  $self->{Files} = $state->{Files};
}

sub SaveState
{
  my $self = shift;

  return if $self->{Attr}{Pretend} || !defined $self->{Attr}{File};

  YAML::DumpFile( $self->{Attr}{File},
		   { 
		    Sig => $self->{Sig}, 
		    Var => $self->{Var}, 
		    Files => 
		      ( $self->{Attr}{DumpFiles} ? $self->{Files} : {} ) 
		   } )
    or croak( __PACKAGE__, 
	      "->SaveState: error writing state to $self->{Attr}{File}" );
}

sub EraseState
{
  my $self = shift;

  $self->{$_} = {} foreach qw( SLink Files Sig Var );

}

sub DumpAll
{
  my $self = shift;

  print STDOUT YAML::Store($self);
}

sub Verbose
{
  $_[0]->{Attr}{Verbose};
}

sub Force
{
  $_[0]->{Attr}{Force};
}

sub Pretend
{
  $_[0]->{Attr}{Pretend};
}

######################################################################
#  Status Files,


sub attachSLink
{
  my ( $self, $file, $slink ) = @_;

  $self->{SLink}{$slink} = []
    unless exists  $self->{SLink}{$slink};

  push @{$self->{SLink}{$slink}}, $file;
}

sub getSLinks
{
  my ( $self, $file ) = @_;

  return exists $self->{SLink}{$file} ? $self->{SLink}{$file} : [$file];
}


######################################################################
# File/Time routines

sub getTime
{
  my ( $self, $file ) = @_;

  exists $self->{Files}{$file} ?  $self->{Files}{$file}{time} : undef;
}

sub setTime
{
  my ( $self, $file, $time ) = @_;

  return unless $self->{Attr}{Cache};

  $self->{Files}{$file}{time} = $time;
}


######################################################################
# Signature routines

sub getSig
{
  my ( $self, $target, $file ) = @_;

  ( exists $self->{Sig}{$target} && exists $self->{Sig}{$target}{$file} )
     ? $self->{Sig}{$target}{$file} : undef;
}

sub setSig
{
  my ( $self, $target, $file, $sig ) = @_;

  $self->{Sig}{$target}{$file} = $sig;
  $self->SaveState;
}


######################################################################
# Variable routines

sub getVar
{
  my ( $self, $target, $var ) = @_;

  # return undef if we have no record of this variable
  exists $self->{Var}{$target} && exists $self->{Var}{$target}{$var} ? $self->{Var}{$target}{$var} : undef;
}


sub setVar
{
  my ( $self, $target, $var, $val ) = @_;

  $self->{Var}{$target}{$var} = $val;
  $self->SaveState;
}

1;
