package DesignPattern::Factory::Creator;
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

sub FactoryMethod
{
    die ('FactoryMethod not implemented');
}

sub AnOperation
{
    my $self = shift;
    $self->{product} = $self->FactoryMethod();
}

1;
=head1 NAME

DesignPattern::Factory::Creator - a participant in the Perl implementation of the Factory Method.

=head1 DESCRIPTION

DesignPattern::Factory::Creator is the superclass of DesignPattern::Factory::ConcreteCreator. That is, ConcreteCreator inherits all methods from Creator, but can override these methods by implementing its own methods.

From GOF, the DesignPattern::Factory::Creator class:

- declares the factory method, which returns an object of type DesignPattern::Factory::Product. DesignPattern::Factory::Creator may also define a default implementation of the factory method that returns a default DesignPattern::Factory::ConcreteProduct object.

- may call the factory method to create a Product object.

=head2 new()

Constructor for this class. Usage:

  my $object = DesignPattern::Factory::Pattern->new();

=head2 FactoryMethod()

The default FactoryMethod just dies with an error, thus ensuring that all subclasses implement a working version of this method.

=head2 AnOperation()

Calls FactoryMethod() and stores the result.

=head1 AUTHOR 

Nigel Wetters (nwetters@cpan.org) 

=head1 COPYRIGHT 

Copyright (c) 2001, Nigel Wetters. All Rights Reserved. This module is free software. 
It may be used, redistributed and/or modified under the same terms as Perl itself.

=cut
