package Lab::Moose::Instrument::OI_IPS::Strunk_3He;
$Lab::Moose::Instrument::OI_IPS::Strunk_3He::VERSION = '3.682';
#ABSTRACT: Example subclass with predefined field limits of a Oxford Instruments IPS

use 5.010;
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Countdown 'countdown';
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument::OI_IPS';

has +max_fields => (
    is      => 'ro', isa => 'ArrayRef[Lab::Moose::PosNum]',
    default => sub { [ 7, 9, 12 ] }
);
has +max_field_rates => (
    is      => 'ro', isa => 'ArrayRef[Lab::Moose::PosNum]',
    default => sub { [ 0.22, 0.1, 0.06 ] }
);

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::OI_IPS::Strunk_3He - Example subclass with predefined field limits of a Oxford Instruments IPS

=head1 VERSION

version 3.682

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2019       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
