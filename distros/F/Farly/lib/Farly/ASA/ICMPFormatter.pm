package Farly::ASA::ICMPFormatter;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.26';

our $String_To_Int = {
    "echo-reply"           => 0,
    "unreachable"          => 3,
    "source-quench"        => 4,
    "redirect"             => 5,
    "alternate-address"    => 6,
    "echo"                 => 8,
    "router-advertisement" => 9,
    "router-solicitation"  => 10,
    "time-exceeded"        => 11,
    "parameter-problem"    => 12,
    "timestamp-request"    => 13,
    "timestamp-reply"      => 14,
    "information-request"  => 15,
    "information-reply"    => 16,
    "mask-request"         => 17,
    "mask-reply"           => 18,
    "traceroute"           => 30,
    "conversion-error"     => 31,
    "mobile-redirect"      => 32,
};

our $Int_To_String = { reverse %$String_To_Int };

sub new {
    return bless {}, $_[0];
}

sub as_string {
    return $Int_To_String->{ $_[1] };
}

sub as_integer {
    return $String_To_Int->{ $_[1] };
}

1;
__END__

=head1 NAME

Farly::ASA::ICMPFormatter - Map ICMP type string ID's and integers

=head1 DESCRIPTION

Farly::ASA::ICMPFormatter is like an enum class, but not. It associates ICMP type
strings with ICMP type integers and vice versa. ICMPFormatter is device specific.

=head1 METHODS

=head2 as_string( <ICMP type number> )

Returns a name for the given ICMP type.

=head2 as_integer( <ICMP type name> )

Returns the ICMP type number for the given ICMP type name.

=head1 COPYRIGHT AND LICENCE

Farly::ASA::ICMPFormatter
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
