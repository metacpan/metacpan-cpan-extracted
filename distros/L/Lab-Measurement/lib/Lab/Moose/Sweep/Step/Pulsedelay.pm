package Lab::Moose::Sweep::Step::Pulsedelay;
$Lab::Moose::Sweep::Step::Pulsedelay::VERSION = '3.802';
#ABSTRACT: Pulsedelay sweep.

use v5.20;


use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Pulsedelay=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'ArrayRefOfInstruments', coerce => 1, required => 1 );

has constant_width => ( is => 'ro', isa => 'Bool', default => 0 );

sub _build_setter {
    return \&_pulsedelay_setter;
}

sub _pulsedelay_setter {
    my $self  = shift;
    my $value = shift;
    foreach (@{$self->instrument}) {
        $_->set_pulsedelay(
          value => $value,
          constant_width => $self->constant_width
        );
    }
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Step::Pulsedelay - Pulsedelay sweep.

=head1 VERSION

version 3.802

=head1 Description

Step sweep with following properties:

=over

=item *

Uses instruments C<set_pulsedelay> method to change the pulsewidth. On initialization
an optional boolean parameter C<constant_width> can be passed to keep a constant
pulse width over a period.

=item *

Default filename extension: C<'Pulsedelay='>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2021       Fabian Weinelt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
