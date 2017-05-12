package DesignPattern::Factory::Product;
$VERSION = '0.01';
use strict;
use Carp; # nice errors
use vars qw( $VERSION );

# constructor
sub new
{
    my $class = shift;
    return bless {}, $class;
}

1;
=head1 NAME

DesignPattern::Factory::Product - a participant in the Perl implementation of the Factory Method.

=head1 DESCRIPTION

DesignPattern::Factory::Product is the superclass of DesignPattern::Factory::ConcreteProduct. That is, ConcreteProduct inherits all methods from Product, but can override these methods by implementing its own methods.

DesignPattern::Factory::Product defines the interface of objects the factory method creates.

=head2 new()

Constructor for this class. Usage:

  my $object = DesignPattern::Factory::Product->new();

=head1 AUTHOR 

Nigel Wetters (nwetters@cpan.org) 

=head1 COPYRIGHT 

Copyright (c) 2001, Nigel Wetters. All Rights Reserved. This module is free software. 
It may be used, redistributed and/or modified under the same terms as Perl itself.

=cut
