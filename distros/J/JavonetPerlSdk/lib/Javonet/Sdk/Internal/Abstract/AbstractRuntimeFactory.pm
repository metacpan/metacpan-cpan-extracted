package Javonet::Sdk::Internal::Abstract::AbstractRuntimeFactory;
use strict;
use warnings FATAL => 'all';
use Moose;
use Scalar::Util qw( blessed );
use Attribute::Abstract;

sub clr : Abstract;

sub jvm : Abstract;

sub netcore : Abstract;

sub perl : Abstract;

sub ruby : Abstract;

sub nodejs : Abstract;

sub python : Abstract;


no Moose;
1;