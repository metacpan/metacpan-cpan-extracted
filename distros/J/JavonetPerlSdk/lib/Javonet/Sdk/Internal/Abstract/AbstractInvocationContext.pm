package Javonet::Sdk::Internal::Abstract::AbstractInvocationContext;
use strict;
use warnings FATAL => 'all';
use Moose;
use Scalar::Util qw( blessed );
use Attribute::Abstract;

sub execute : Abstract;

sub get_value : Abstract;

no Moose;
1;