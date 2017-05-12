package Device::ParallelPort::drv::dummy_bit;
use strict;
use Carp;

=head1 NAME

Device::ParallelPort::drv::dummy_bit - Dummy driver. Pretend to work.

=head1 DESCRIPTION

This is a dummy driver. Purely built to test the primary driver.

=head1 CAPABILITIES

None what so ever. Basically just store bits in an array !

=head1 COPYRIGHT

Copyright (c) 2002,2004 Scott Penrose. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Scott Penrose L<scottp@dd.com.au>, L<http://linux.dd.com.au/>

=head1 SEE ALSO

L<Device::ParallelPort>

=cut

use base qw/Device::ParallelPort::drv/;

sub init {
        my ($this, @params) = @_;
        $this->{BITS} = [];
}

sub INFO {
        return {
                'os' => 'any',
                'type' => 'bit',
        };
}

sub set_bit {
        my ($this, $bit, $val) = @_;
        $this->{BITS}[$bit] = $val ? 1 : 0;
}

sub get_bit {
        my ($this, $bit) = @_;
        return $this->{BITS}[$bit] ? 1 : 0;
}

1;

