package Lab::Moose::Sweep::Step::Power;
$Lab::Moose::Sweep::Step::Power::VERSION = '3.800';
#ABSTRACT: Power sweep.

use v5.20;


use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Power=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'ArrayRefOfInstruments', coerce => 1, required => 1 );

sub _build_setter {
    return \&_power_setter;
}

sub _power_setter {
    my $self  = shift;
    my $value = shift;
    foreach (@{$self->instrument}) {
        $_->set_power( value => $value );
    }
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Step::Power - Power sweep.

=head1 VERSION

version 3.800

=head1 Description

Step sweep with following properties:

=over

=item *

Uses instruments C<set_power> method to change the power.

=item *

Default filename extension: C<'Power='>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel
            2020       Andreas K. Huettel
            2021       Fabian Weinelt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
