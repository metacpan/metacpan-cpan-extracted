# Copyright (c) 2015  Timm Murray
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
package Device::GPS::Connection::Serial;
$Device::GPS::Connection::Serial::VERSION = '0.714874475569562';
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;
use Device::GPS::Connection;
use Device::SerialPort;

with 'Device::GPS::Connection';

has '_dev' => (
    is  => 'ro',
    isa => 'Device::SerialPort',
);


sub BUILDARGS
{
    my ($class, $args) = @_;
    my $port = delete $args->{port};
    my $baud = delete $args->{baud} // 9600;

    my $dev = Device::SerialPort->new( $port );
    $dev->baudrate( $baud );
    $args->{'_dev'}    = $dev;

    return $args;
}


sub read_nmea_sentence
{
    my ($self) = @_;
    my $dev = $self->_dev;
    my $line = $dev->READLINE;
    return '' if ! defined $line;
    chomp $line;
    return $line;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

