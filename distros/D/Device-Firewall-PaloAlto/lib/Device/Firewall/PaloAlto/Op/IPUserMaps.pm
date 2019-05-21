package Device::Firewall::PaloAlto::Op::IPUserMaps;
$Device::Firewall::PaloAlto::Op::IPUserMaps::VERSION = '0.1.6';
use strict;
use warnings;
use 5.010;

use parent qw(Device::Firewall::PaloAlto::JSON);

use Device::Firewall::PaloAlto::Op::IPUserMap;
use Device::Firewall::PaloAlto::Errors qw(ERROR);


# VERSION
# PODNAME
# ABSTRACT: Palo Alto IP to user mapping table.


sub _new {
    my $class = shift;
    my ($api_response) = @_;

    # Create a copy of the entries if defined, otherwise an empty list
    my @userid_entries = defined $api_response->{result}{entry} ? @{$api_response->{result}{entry}} : ();

    # Create the objects
    my @userid_obj = map { Device::Firewall::PaloAlto::Op::IPUserMap->_new($_) } @userid_entries;

    # Map to the IP
    my %ip_map = map { $_->ip => $_ } @userid_obj;

    return bless \%ip_map, $class;
}


sub ip {
    my $self = shift;
    my ($ip) = @_;
    
    return ($self->{$ip} or ERROR("No IP mapping for IP $ip"));
}


sub to_array { return values %{$_[0]} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::IPUserMaps - Palo Alto IP to user mapping table.

=head1 VERSION

version 0.1.6

=head1 SYNOPSIS

    my $mappings = $fw->op->ip_user_mapping;
    my $mapping = $mappings->ip('192.0.2.1');
    say "User: ". $mapping->user;

=head1 DESCRIPTION

This object represents the entries in the IP to user mapping table. It contains a number of L<Device::Firewall::PaloAlto::Op::IPUserMap> objects.

=head1 METHODS

=head2 ip

Returns a L<Device::Firewall::PaloAlto::Op::IPUserMap> object with details about the IP to user mapping for a user.

If there is no mapping for the IP, returns a L<Class::Error> object.

=head2 to_array

Returns an array of L<Device::Firewall::PaloAlto::Op::IPUserMap> objects representing the current IP to user mappings.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
