package Javonet::Sdk::Internal::Abstract::AbstractInstanceContext;
use strict;
use warnings FATAL => 'all';
use Moose;
use Scalar::Util qw( blessed );
use Attribute::Abstract;

sub invoke_instance_method : Abstract;

sub get_instance_field : Abstract;

sub set_instance_field : Abstract;

sub create_instance : Abstract;


no Moose;
1;