package Lab::Moose::Instrument::AdjustRange;
$Lab::Moose::Instrument::AdjustRange::VERSION = '3.682';
#ABSTRACT: Role for automatic adjustment of measurement ranges.

use 5.010;
use Moose::Role;
use MooseX::Params::Validate;
use Lab::Moose::Instrument 'setter_params';

use Carp;

requires qw/allowed_ranges set_range get_cached_range/;


sub adjust_measurement_range {
    my $self = shift;
    my ( $value, $verbose, $ranges, $safety_factor ) = validated_list(
        \@_,
        value         => { isa => 'Num' },
        verbose       => { isa => 'Bool', default => 1 },
        ranges        => { isa => 'ArrayRef[Num]', optional => 1 },
        safety_factor => { isa => 'Num', default => 1 },
    );

    $value = abs($value);

    my @ranges;
    if ( defined $ranges ) {
        @ranges = @{$ranges};
    }
    else {
        @ranges = @{ $self->allowed_ranges };
    }

    @ranges = sort @ranges;    # ascending order

    my $current_range = $self->get_cached_range();
    my $new_range;

    for my $range (@ranges) {
        if ( $value <= $safety_factor * $range ) {
            $new_range = $range;
            last;
        }
    }

    if ( not defined $new_range ) {

        # use maximum range
        $new_range = $ranges[-1];
    }

    if ( $new_range != $current_range ) {
        if ($verbose) {
            carp
                "Adjusting range from $current_range to $new_range (current value: $value)";
        }
        $self->set_range( value => $new_range );
    }
    return $current_range;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::AdjustRange - Role for automatic adjustment of measurement ranges.

=head1 VERSION

version 3.682

=head1 DESCRIPTION

This role provides the C<'adjust_measurement_range'> method,
 which selects a measurement range suitable for the current input signal.

=head1 METHODS

=head2 adjust_measurement_range

 my $value = $instrument->get_value();
 my $old_range = $instrument->adjust_measurement_range(
     value => $value,
     verbose => 1,
 );
 my $new_range = $instrument->get_range();

To limit the allowed ranges, supply an arrayref with allowed ranges:

 $instrument->adjust_measurement_range(
     value => ...,
     allowed_ranges => [0.1, 10],
 );

If C<verbose> is set, carp whenever the measurement range is changed.

By default, the range is changed, whenever the signal exceeds 100% of the measurement range, this factor can be adjusted with the C<safety_factor> attribute.

 $instrument->adjust_measurement_range(
     ...,
     ...,
     safety_factor => 0.8, # change range when signal is at 80% of current range
 );

=head1 REQUIRED METHODS

=head2 allowed_ranges

Arrayref with allowed ranges

=head2 set_range

 $instrument->set_range(value => $new_range);

Set measurement range.

=head2 get_range

 $instrument->get_cached_range();

Get current range from cache.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
