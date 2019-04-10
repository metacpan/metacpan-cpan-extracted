package Device::Firewall::PaloAlto::Op::Tunnels;
$Device::Firewall::PaloAlto::Op::Tunnels::VERSION = '0.1.5';
use strict;
use warnings;
use 5.010;

use Device::Firewall::PaloAlto::Op::Tunnel;

use parent qw(Device::Firewall::PaloAlto::JSON);

# VERSION
# PODNAME
# ABSTRACT: Palo Alto IPSEC security associations


sub _new {
    my $class = shift;
    my ($ike_sas, $ipsec_sas) = @_;
    my %tunnels;

    # Iterate through the phase 1 and key them by the name of the gateway.
    $tunnels{$_->{name}}{phase_1} = $_ foreach @{$ike_sas->{result}{entry}};
    $tunnels{$_->{gateway}}{phase_2} = $_ foreach @{$ipsec_sas->{result}{entries}{entry}};

    # API CRUFT: there whitespace following the remote IP.
    $_->{phase_2}{remote} =~ s{\s+$}{} foreach values %tunnels;
    

    # Map the values to tunnel objects, still keyed on the IKE gateway name.
    %tunnels = map { $_ => Device::Firewall::PaloAlto::Op::Tunnel->_new($tunnels{$_}) } keys %tunnels;

    return bless \%tunnels, $class;
}



sub gw {
    my $self = shift;
    my ($gw) = @_;
    return $self->{$gw}
};




sub to_array { return values %{$_[0]} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::Tunnels - Palo Alto IPSEC security associations

=head1 VERSION

version 0.1.5

=head1 SYNOPSIS

=head1 DESCRIPTION

This object represents IPSEC tunnels on the firewall.

=head2 gw

Returns a L<Device::Firewall::PaloAlto::Op::Tunnel> object that is assoicated with the name of the IKE gateway.

    my $p2p = $fw->op->tunnels->gw('remote_site');

=head2 to_array

Returns an array of L<Device::Firewall::PaloAlto::Op::Tunnel> objects, one for each IPSEC tunnel.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
