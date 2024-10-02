package Javonet::Sdk::Internal::Abstract::AbstractMethodInvocationContext;
use strict;
use warnings FATAL => 'all';
use Moose;
use Scalar::Util qw( blessed );
use Attribute::Abstract;


sub invoke_static_method : Abstract;

sub set_generic_type : Abstract;

sub get_static_field : Abstract;

sub set_static_field : Abstract;

no Moose;
1;