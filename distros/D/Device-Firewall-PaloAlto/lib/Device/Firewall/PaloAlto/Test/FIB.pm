package Device::Firewall::PaloAlto::Test::FIB;
$Device::Firewall::PaloAlto::Test::FIB::VERSION = '0.1.9';
use strict;
use warnings;
use 5.010;

# VERSION
# PODNAME
# ABSTRACT: Representation of a Palo Alto FIB object.

use parent qw(Device::Firewall::PaloAlto::JSON);


sub _new {
    my $class = shift;
    my ($api_response) = @_;
    my %obj;

    # Return the error
    return $api_response unless $api_response;

    # Is there an entry?
    $obj{fib_entry} = defined $api_response->{result}{nh};

    # Are there ECMP routes?
    $obj{ecmp} = 0;
    my @ecmp_fib_entries;
    if ($api_response->{result}{mpath}) {
        $obj{ecmp} = 1;
        # Extract out the entries we want into hashrefs
        @ecmp_fib_entries = 
            map { { %{ $_ }{qw(ip nh interface metric)} } }
            @{ $api_response->{result}{mpath}{entry} };
    }

    # Concatenate the ECMP entries together
    $obj{entries} = [
        { %{ $api_response->{result} }{qw(ip nh interface metric)} },
        @ecmp_fib_entries
    ];

    return bless \%obj, $class;
}


sub interfaces {
    my $self = shift;

    return () unless $self->{fib_entry};

    return map { $_->{interface} } @{ $self->{entries} };
}


sub next_hops {
    my $self = shift;

    return () unless $self->{fib_entry};

    return map { $_->{ip} } @{ $self->{entries} };
}


sub is_ecmp { return !!$_[0]->{ecmp} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Test::FIB - Representation of a Palo Alto FIB object.

=head1 VERSION

version 0.1.9

=head1 DESCRIPTION

This object represents the result of a forwarding information base (FIB) lookup on the firewall.

=head1 ERRORS 

=head1 METHODS

=head2 interfaces

    my @egress_interfaces = $fw->test->fib_lookup(ip => '192.0.2.1')->interfaces;

Returns a list of the egress interfaces for the FIB entry. In most cases this will be a single entry,
howeber it can be multiple of the FIB entry is an equal cost multipath (ECMP) entry.

If the FIB lookup did not return an entry this will return an empty list.

=head2 next_hops

    my @nh_ips = $fw->test->fib_lookup(ip => '192.0.2.1')->next_hops;

Returns a list of the next-hop IPs for the FIB entry. In most cases this will be a single entry,
howeber it can be multiple of the FIB entry is an equal cost multipath (ECMP) entry.

If the FIB lookup did not return an entry this will return an empty list.

=head2 is_ecmp

    my $is_ecmp = $fw->test->fib_lookup(ip => '192.0.2.1')->ecmp

Returns true if the FIB entry is an ECMP route, otherwise returns false.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
