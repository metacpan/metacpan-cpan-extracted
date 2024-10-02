package Javonet::Sdk::Internal::Abstract::AbstractTypeContext;
use strict;
use warnings FATAL => 'all';
use Moose;
use Scalar::Util qw( blessed );
use Attribute::Abstract;

sub get_type : Abstract;

sub cast: Abstract;

sub get_enum_item : Abstract;

no Moose;
1;