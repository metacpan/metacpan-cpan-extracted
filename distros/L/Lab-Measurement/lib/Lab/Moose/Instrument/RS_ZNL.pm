package Lab::Moose::Instrument::RS_ZNL;
$Lab::Moose::Instrument::RS_ZNL::VERSION = '3.791';
#ABSTRACT: Rohde & Schwarz ZNL Vector Network Analyzer

use v5.20;
use Carp 'croak';
use Moose;

extends 'Lab::Moose::Instrument::RS_ZVA';

# does not support USBTMC



# The ZNL only supports SWAP byte order. It does not have a FORMAT:BORDER command.
sub format_border_query() {
    return 'SWAP';
}

sub format_border {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    if ( $value ne 'SWAP' ) {
        croak 'The R&S ZNL only suppots SWAP byte order.';
    }
    return $self->cached_format_border($value);
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::RS_ZNL - Rohde & Schwarz ZNL Vector Network Analyzer

=head1 VERSION

version 3.791

=head1 SYNOPSIS

 my $data = $znl->sparam_sweep(timeout => 10);

=head1 METHODS

See L<Lab::Moose::Instrument::VNASweep> for the high-level C<sparam_sweep> and
C<sparam_catalog> methods.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2020       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
