# Copyright (c) 2014  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Device::WebIO::Device::DigitalOutput;
$Device::WebIO::Device::DigitalOutput::VERSION = '0.020';
use v5.12;
use Moo::Role;

with 'Device::WebIO::Device';

requires 'output_pin_count';
requires 'output_pin';
requires 'set_as_output';
requires 'is_set_output';

# There may be more efficient ways to do this on your platform.  Override 
# this if there are.
sub output_port
{
    my ($self, $out) = @_;

    for (0 .. ($self->output_pin_count - 1)) {
        my $pin_out = ($out >> $_) & 1;
        $self->output_pin( $_, $pin_out );
    }

    return 1;
}


1;
__END__


=head1 NAME

  Device::WebIO::Device::DigitalOutput - Role for general-purpose digital output

=head1 REQUIRED METHODS

=head2 output_pin_count

    output_pin_count();

Return the number of output pins.

=head2 output_pin

    output_pin( $pin, $value );

Set the given value for the given pin.

=head2 set_as_output

    set_as_output( $pin );

Set the given pin as an output pin.

=head2 is_set_output

    is_set_output( $pin );

Returns true if the given pin is set as an output pin.

=head1 PROVIDED METHODS

=head2 output_port

    output_port( $bitstring );

Set all the output pins at once with a bitstring.

The default implementation sets this by iterating through using C<output_pin()>.
Many platforms have an efficient way of setting all the pins at once, so you 
may wish to override this.

=head1 LICENSE

Copyright (c) 2014  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of 
      conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of
      conditions and the following disclaimer in the documentation and/or other materials 
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
