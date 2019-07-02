package Lab::Moose::Sweep::Step::Voltage;
$Lab::Moose::Sweep::Step::Voltage::VERSION = '3.682';
#ABSTRACT: Voltage sweep.


use 5.010;
use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension => ( is => 'ro', isa => 'Str', default => 'Voltage=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'Lab::Moose::Instrument', required => 1 );

sub _build_setter {
    return \&_voltage_setter;
}

sub _voltage_setter {
    my $self  = shift;
    my $value = shift;
    $self->instrument->set_level( value => $value );
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Step::Voltage - Voltage sweep.

=head1 VERSION

version 3.682

=head1 DESCRIPTION

Step sweep with following properties:

=over

=item *

 Uses instruments C<set_level> method to change the output voltage.
 The default filename extension is 

=item *

Default filename extension: C<'Voltage='>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt
            2018       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
