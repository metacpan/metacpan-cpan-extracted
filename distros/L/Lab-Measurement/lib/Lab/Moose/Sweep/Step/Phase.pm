package Lab::Moose::Sweep::Step::Phase;
$Lab::Moose::Sweep::Step::Phase::VERSION = '3.904';
#ABSTRACT: Phase sweep.

use v5.20;


use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Phase=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'ArrayRefOfInstruments', coerce => 1, required => 1 );

sub _build_setter {
    return \&_phase_setter;
}

sub _phase_setter {
    my $self  = shift;
    my $value = shift;
    foreach (@{$self->instrument}) {
        $_->set_phase( value => $value );
    }
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Step::Phase - Phase sweep.

=head1 VERSION

version 3.904

=head1 Description

Step sweep with following properties:

=over

=item *

Uses instruments C<set_phase> method to change the phase.

=item *

Default filename extension: C<'Phase='>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by the Lab::Measurement team; in detail:

  Copyright 2021       Fabian Weinelt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
