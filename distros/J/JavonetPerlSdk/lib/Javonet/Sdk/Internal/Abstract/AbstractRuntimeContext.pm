package Javonet::Sdk::Internal::Abstract::AbstractRuntimeContext;
use strict;
use warnings FATAL => 'all';
use Moose;
use Scalar::Util qw( blessed );
use Attribute::Abstract;

sub load_library : Abstract;
sub get_type : Abstract;
sub cast : Abstract;
sub get_enum_item : Abstract;
sub as_out: Abstract;
sub as_ref: Abstract;
sub invoke_global_function: Abstract;

no Moose;
1;