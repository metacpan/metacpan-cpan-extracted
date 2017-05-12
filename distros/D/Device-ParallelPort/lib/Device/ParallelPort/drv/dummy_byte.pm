package Device::ParallelPort::drv::dummy_byte;
use strict;
use Carp;

=head1 NAME

Device::ParallelPort::drv::dummy_byte - Dummy driver. Pretend to work.

=head1 DESCRIPTION

This is purely used for testing the system and not really useful.

=head1 CAPABILITIES

None what so ever. Basically just store bytes in an array !

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
        $this->{BYTES} = [];
}

sub INFO {
        return {
                'os' => 'any',
                'type' => 'byte',
        };
}

sub set_byte {
        my ($this, $byte, $val) = @_;
        $this->{BYTES}[$byte] = $val;
}

sub get_byte {
        my ($this, $byte) = @_;
	if (!defined($this->{BYTES}[$byte])) {
		$this->{BYTES}[$byte] = chr(0);
	}
        return $this->{BYTES}[$byte];
}

1;

