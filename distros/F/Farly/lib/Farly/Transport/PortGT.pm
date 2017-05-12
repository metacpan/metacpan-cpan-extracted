package Farly::Transport::PortGT;

use 5.008008;
use strict;
use warnings;
use Carp;
use Farly::Transport::Port;

our @ISA     = qw(Farly::Transport::Port);
our $VERSION = '0.26';

sub last {
    return 65535;
}

1;
__END__

=head1 NAME

Farly::Transport::PortGT - TCP/UDP port 'greater than' class

=head1 DESCRIPTION

This class represents TCP or UDP port numbers greater than the 
given port number.

Inherits from Farly::Transport::Port.

=head1 METHODS

=head2 last()

Returns the port number, 65535

  $8_bit_int = $port->last();

=head1 COPYRIGHT AND LICENSE

Farly::Transport::PortGT
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
