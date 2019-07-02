package Lab::Moose::Sweep::Step::Frequency;
$Lab::Moose::Sweep::Step::Frequency::VERSION = '3.682';
#ABSTRACT: Frequency sweep.


use 5.010;
use Moose;

extends 'Lab::Moose::Sweep::Step';

has filename_extension =>
    ( is => 'ro', isa => 'Str', default => 'Frequency=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );

has instrument =>
    ( is => 'ro', isa => 'Lab::Moose::Instrument', required => 1 );

sub _build_setter {
    return \&_frq_setter;
}

sub _frq_setter {
    my $self  = shift;
    my $value = shift;
    $self->instrument->set_frq( value => $value );
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Step::Frequency - Frequency sweep.

=head1 VERSION

version 3.682

=head1 Description

Step sweep with following properties:

=over

=item *

 Uses instruments C<set_frq> method to change the frequency.

=item *

Default filename extension: C<'Frequency='>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
