package Lab::Moose::Sweep::Step::Power;
$Lab::Moose::Sweep::Step::Power::VERSION = '3.682';
#ABSTRACT: Power sweep.


use 5.010;
use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Power=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'Lab::Moose::Instrument', required => 1 );

sub _build_setter {
    return \&_power_setter;
}

sub _power_setter {
    my $self  = shift;
    my $value = shift;
    $self->instrument->set_power( value => $value );
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Step::Power - Power sweep.

=head1 VERSION

version 3.682

=head1 Description

Step sweep with following properties:

=over

=item *

 Uses instruments C<set_power> method to change the power.

=item *

Default filename extension: C<'Power='>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
