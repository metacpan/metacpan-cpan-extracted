# $Id: Chain.pm,v 1.1.1.1 2000/12/05 00:55:01 schwern Exp $

# Somebody's going to want to graft this thing onto another database.
# May as well plan for it.
package Geo::Walkabout::Chain;
@ISA = qw(Geo::Walkabout::Chain::PostgreSQL);


package Geo::Walkabout::Chain::PostgreSQL;

use strict;
use AnyLoader;
use Carp::Assert;

use vars qw($VERSION);

$VERSION = '0.02';


=pod

=head1 NAME

Geo::Walkabout::Chain - An open path representing the shape of a line feature.

=head1 SYNOPSIS

  require Geo::Walkabout::Chain;

  my $chain = Geo::Walkabout::Chain->new([1,1],[5,10.2],[12,13]);
  my $chain = Geo::Walkabout::Chain->new_from_pgpath('[(1,1),(5,10.2),(12,13)]');

  my $begin = $chain->begin;
  my $end   = $chain->end;
  my @shape = $chain->shape;
  my @raw_chain = $chain->chain;
  my $pg_path = $chain->as_pgpath;

  $chain->append_shape(@points);


=head1 DESCRIPTION

This is a representation of a complete chain.  Typically, it should
not be used directly, instead Geo::Walkabout::Line encapsulates a
single Geo::Walkabout::Chain.

A single point in a chain is represented as a two element array
representing a single point of latitude and longitutde.  (OO dogma
says these should be objects, too, but if I wanted to be that silly
I'd be using Java.)

=head1 Public Methods

=head2 Constructors

=over 4

=item B<new>

  my $chain = Geo::Walkabout::Chain->new([$lat1, $long1], 
                                         [$lat2, $long2], 
                                         ...
                                        );

Creates a new Geo::Walkabout::Chain object from a list of points (two
element array references).  The first point is the start of the chain,
the last is the end (or vice-versa depending on which way you look.)
The rest are "shape" coordinates.


=cut

#'#
sub new {
    my($class, @chain) = @_;

    unless( @chain >= 2 ) {
        Carp::carp("A chain must have at least a start and an end.");
        return;
    }
    
    my($self) = [@chain];
    return bless $self, $class;
}

=pod

=item B<new_from_pgpath>

  my $chain = Geo::Walkabout::Chain->new_from_pgpath($postgres_path);

An alternative constructor, it takes a PostgreSQL style open PATH of the
form:

  [ ( lat1, long1 ), ... , (latn, longn) ]

So something like '[(1,1), (-1,2.2), (-2,3)]'.  This is very helpful when
reading in chains from a PostgreSQL database.

=cut

sub new_from_pgpath {
    my($class, $chain) = @_;

    my($self) = $class->new( $class->_split_pg_path($chain) );
    return $self;
}

=pod

=back


=head2 Accessors

=over 4

=item B<begin>

  my $beginning_point = $chain->begin;

Returns the beginning point of this chain as a two element array reference.

=item B<end>

  my $end_point = $chain->end;

Returns the end point of this chain as a two element array reference.

=cut

sub begin {
    return $_[0]->[0];
}

sub end {
    return $_[0]->[-1];
}

=pod

=item B<shape>

  my @shape = $chain->shape;

Returns the shaping points of this chain, ie. those points between the
start and the end which determine the shape of the chain (without
them, its just a line segment).

=cut

sub shape {
    my $self = shift;
    return @{$self}[1..$#{$self} - 1];
}

=pod

=item B<chain>

  my @raw_chain = $chain->chain;

Dumps the chain this object represents as a series of points.  This is
equivalent to:

    my @raw_chain = ($chain->begin, $chain->shape, $chain->end);

=cut

sub chain {
    return @{$_[0]};
}

=pod

=item B<as_pgpath>

  my $pg_path = $chain->as_pgpath;

Returns a representation of the chain as a PostgreSQL open path
suitable for insertion into the database.

=cut

sub as_pgpath {
    my($self) = shift;

    return '['. join(', ', map { "(". join(',', @$_) .")" } @$self) .']';
}

=pod

=item B<to_pgpoint>

  my $pg_point = $chain->to_pgpoint(\@point);

Translates a two element array reference into a PostgreSQL point.

=cut

sub to_pgpoint {
    my($self, $point) = @_;

    assert(@$point == 2);

    return '('. join(', ', @$point) .')';
}

=pod

=back


=head2 Modifiers

=over 4

=item B<append_shape>

  $chain->append_shape(@points);

Adds new shaping points to the chain.  They are appended to the end of
the shape.

=cut

sub append_shape {
    my($self, @points) = @_;

    splice @$self, -1, 0, @points;
}

=pod

=head2 Private Methods

B<PRIVATE!> I document them here because I'm forgetful.  Use of these
may result in I<DIRE CONSEQUENCES!> (consequences may contain one or
more of the following: pain, death, dismemberment, yellow dye #5)


=over 4

=item B<_split_pg_path>

  my @path = Geo::Walkabout::Chain->_split_pg_path($pg_path);

Converts a PostgreSQL open PATH into an array of points.

=cut

#'#
sub _split_pg_path {
    my($self, $path) = @_;
    
    # A bit of sanity checking.
    unless( $path =~ /^\s*\[.*\]\s*$/ ) {
        Carp::carp('This doesn\'t look like a PostgreSQL open PATH');
        return;
    }

    my @points = ();
    # ( 4.4 , -6.9 )
    while( $path =~ / \( \s* ([-\d\.]+) \s* , 
                         \s* ([-\d\.]+) \s* \) 
                    /gx ) 
    {
        push @points, [$1,$2];
    }

    return @points;
}

=pod

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>


=head1 SEE ALSO

B<Geo::Walkabout>, B<Geo::Walkabout::Line>, B<Geo::TigerLine>

=cut

1;
