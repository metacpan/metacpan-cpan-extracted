# 
# This file is part of Games-RailRoad
# 
# This software is copyright (c) 2008 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
use 5.010;
use strict;
use warnings;

package Games::RailRoad::Train;
BEGIN {
  $Games::RailRoad::Train::VERSION = '1.101330';
}
# ABSTRACT: a train object

use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Games::RailRoad::Types qw{ Num_0_1 };


# -- attributes


has from => ( rw, isa=>'Games::RailRoad::Vector' );
has to   => ( rw, isa=>'Games::RailRoad::Vector' );
has frac => ( rw, isa=>Num_0_1 );


# -- constructor & initializers


# provided by moose


# -- public methods


sub draw {
    my ($self, $canvas, $tilelen) = @_;
    my $from = $self->from;
    my $to   = $self->to;
    my $frac = $self->frac;

    my $diag = 2;
    my $colf = $from->posx; my $rowf = $from->posy;
    my $colt =   $to->posx; my $rowt =   $to->posy;
    $canvas->delete("$self");
    my $x = ( $colf + ($colt-$colf) * $frac ) * $tilelen;
    my $y = ( $rowf + ($rowt-$rowf) * $frac ) * $tilelen;
    $canvas->createOval(
        $x - $diag, $y - $diag,
        $x + $diag, $y + $diag,
        -fill => 'blue',
        -tags => [ "$self" ],
    );
}


# -- private methods


1;


=pod

=head1 NAME

Games::RailRoad::Train - a train object

=head1 VERSION

version 1.101330

=head1 DESCRIPTION

This class models a train object that moves on the rails.

=head1 ATTRIBUTES

=head2 from

The node from where the train is coming (a L<Games::RailRoad::Vector> object).

=head2 to

The node where the train is headed (a L<Games::RailRoad::Vector> object).

=head2 frac

A number between 0 and 1 indicating where exactly the train is between
its from and to nodes.

=head1 METHODS

=head2 my $train = Games::RailRoad::Train->new( \%opts );

Create and return a new train object. One can pass a hash reference with
the available attributes.

=head2 $train->draw( $canvas, $tilelen );

Request C<$train> to draw itself on C<$canvas>, assuming that each square
has a length of C<$tilelen>.

=head1 AUTHOR

  Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


