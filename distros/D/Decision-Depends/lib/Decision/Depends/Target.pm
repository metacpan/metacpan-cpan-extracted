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

package Decision::Depends::Target;

require 5.005_62;
use strict;
use warnings;

use Carp;

use IO::File;

## no critic ( ProhibitAccessOfPrivateData )

our $VERSION = '0.20';

our %attr = ( target => 1,
	      targets => 1,
	      force => 0,
	      sfile => 1,
	      slink => 1,
	    );

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my ( $state, $spec ) = @_;

  my $self = { %$spec, state => $state };

  $self->{Pretend} = $self->{state}{Attr}{Pretend};

  # ensure that no bogus attributes are set
  my @notok = grep { ! exists $attr{$_} } keys %{$self->{attr}};
  croak( __PACKAGE__,
      "->new: bad attributes for Target `$self->{val}': ",
	 join( ', ', @notok ) ) if @notok;

  bless $self, $class;
}


sub getTime
{
  my $self = shift;
  my $file = $self->{val};

  my @sb;
  my $time = 
    $self->{state}->getTime( $file )
      || ((@sb = stat( $file )) ? $sb[9] : undef);

  # cache the value
  $self->{state}->setTime( $file, $time )
    if defined $time;

  $time;
}

sub setTime
{
  my $self = shift;
  my @sb;
  my $file = $self->{val};

  my $time = $self->{Pretend} ?
                  time () : ((@sb = stat( $file )) ? $sb[9] : undef);

  croak( __PACKAGE__, 
	 "->setTime: couldn't get time for `$file'. does it exist?" )
    unless defined $time;

  $self->{state}->setTime( $file, $time );
}

sub update
{
  my ( $self ) = @_;

  my $file = $self->{val};
  my $attr = $self->{attr};

  # if it's an sfile or slink, create the file
  if ( exists $attr->{slink} )
  {
    $self->mkSFile;
    $self->{state}->attachSLink( $file, $attr->{slink} );
  }

  elsif ( exists $attr->{sfile} )
  {
    $self->mkSFile;
  }

  $self->setTime;
}

sub mkSFile
{
  my ( $self ) = @_;

  return if $self->{Pretend};

  my $file = $self->{val};

  unlink $file;
  my $fh = IO::File->new( $file, 'w' )
    or croak( __PACKAGE__, "->mkSFile: unable to create file `$file'" );
}

sub file { $_[0]{val} }

sub force { $_[0]{attr}{force} }

1;
