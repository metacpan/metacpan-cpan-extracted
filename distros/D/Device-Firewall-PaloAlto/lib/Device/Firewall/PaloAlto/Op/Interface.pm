package Device::Firewall::PaloAlto::Op::Interface;
$Device::Firewall::PaloAlto::Op::Interface::VERSION = '0.1.3';
use strict;
use warnings;
use 5.010;

# VERSION
# PODNAME
# ABSTRACT: Palo Alto firewall interface

use parent qw(Device::Firewall::PaloAlto::JSON);


sub _new {
    my $class = shift;
    my ($api_return) = @_;

    return bless $api_return, $class;
}



sub name { return $_[0]->{name} }
sub state { return $_[0]->{state} }
sub ip { return $_[0]->{ip} }
sub vsys { return $_[0]->{vsys} }
sub zone { return $_[0]->{zone} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::Interface - Palo Alto firewall interface

=head1 VERSION

version 0.1.3

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ERRORS 

=head1 METHODS

=head2 name

Returns the name of the interface.

=head2 state

State of the interface. Returns the either 'up' or 'down' depending on the interface state.

=head2 ip

Returns the IPv4 address and CIDR of the interface (e.g '192.0.2.0/24') or the empty string if there is no IPv4 address assigned to the interfaces.

=head2 vsys

Returns the vsys ID (1, 2, etc) of the vsys the interface is a member of.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
