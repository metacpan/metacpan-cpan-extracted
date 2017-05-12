package DesignPattern::Factory::ConcreteProduct;
$VERSION = '0.01';
use strict;
use Carp; # nice errors
use vars qw( $VERSION @ISA );
use DesignPattern::Factory::Product;
@ISA = qw ( DesignPattern::Factory::Product );

# nothing much here - add more methods to superclass, and override here

1;
=head1 NAME

DesignPattern::Factory::ConcreteProduct - a participant in the Perl implementation of the Factory Method.

=head1 DESCRIPTION

Implements the DesignPattern::Factory::Product interface.

=head1 AUTHOR 

Nigel Wetters (nwetters@cpan.org) 

=head1 COPYRIGHT 

Copyright (c) 2001, Nigel Wetters. All Rights Reserved. This module is free software. 
It may be used, redistributed and/or modified under the same terms as Perl itself.

=cut
