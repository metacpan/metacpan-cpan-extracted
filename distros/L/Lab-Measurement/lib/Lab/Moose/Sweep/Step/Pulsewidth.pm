package Lab::Moose::Sweep::Step::Pulsewidth;
$Lab::Moose::Sweep::Step::Pulsewidth::VERSION = '3.881';
#ABSTRACT: Pulsewidth sweep.

use v5.20;


use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Pulsewidth=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'ArrayRefOfInstruments', coerce => 1, required => 1 );

has constant_delay => ( is => 'ro', isa => 'Bool', default => 0 );

sub _build_setter {
    return \&_pulsewidth_setter;
}

sub _pulsewidth_setter {
    my $self  = shift;
    my $value = shift;
    foreach (@{$self->instrument}) {
        $_->set_pulsewidth(
          value => $value,
          constant_width => $self->constant_delay
        );
    }
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Step::Pulsewidth - Pulsewidth sweep.

=head1 VERSION

version 3.881

=head1 Description

Step sweep with following properties:

=over

=item *

Uses instruments C<set_pulsewidth> method to change the pulsewidth. On initialization
an optional boolean parameter C<constant_delay> can be passed to keep a constant
delay time over a pulse period.

=item *

Default filename extension: C<'Pulsewidth='>

=back

See pulsewidth-sweep.pl in the examples::Sweeps folder for a simple pulsewidth
sweep example.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2021       Fabian Weinelt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
