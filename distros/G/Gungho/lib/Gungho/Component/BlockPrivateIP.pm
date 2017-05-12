# $Id: /mirror/gungho/lib/Gungho/Component/BlockPrivateIP.pm 31095 2007-11-26T00:05:40.329716Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::BlockPrivateIP;
use strict;
use warnings;
use base qw(Gungho::Component);
use Regexp::Common qw(net);

sub request_is_allowed
{
    my ($c, $request) = @_;

    # Check if we are filtering private addresses
    return if $c->block_private_ip_address($request, $request->uri);
    return $c->next::method($request);
}

sub handle_dns_response
{
    my ($c, $request, $answer, $dns_response) = @_;

    # Check if we are filtering private addresses
    return if $c->block_private_ip_address($request, $answer->address);

    $c->next::method($request, $answer, $dns_response);
}

sub block_private_ip_address
{
    my ($c, $request, $address) = @_;

    if (ref $address && $address->isa('URI')) {
        if (! $address->can('host')) {
            # no host, no check
            return undef;
        }
        $address = $address->host;
    }

    if ($c->address_is_private($address)) {
        $c->log->debug('Hostname ' . $request->uri->host . ' has a private ip address: ' . $address);
        $c->handle_response($request, $c->_http_error(500, 'Access blocked for hostname with private address: ' . $request->uri->host, $request));
        return 1;
    }
    
    undef;
}

sub address_is_private
{
    my ($self, $address) = @_;

    if ($address =~ /^$RE{net}{IPv4}{-keep}$/) {
        my ($o1, $o2, $o3, $o4) = ($2, $3, $4, $5);

        if ($o1 eq '10') {
            return 1;
        } elsif ($o1 eq '127') {
            return 1;
        } elsif ($o1 eq '172') {
            return $o2 >= 16 && $o2 <= 31
        } elsif ($o1 eq '192' && $o2 eq '168') {
            return 1;
        }
    }
       
    return 0;
}

1;

__END__

=head1 NAME

Gungho::Component::BlockPrivateIP - Block Requests With Private IP Address

=head1 SYNOPSIS

  components:
    - BlockPrivateIP

=head1 DESCRIPTION

Some domain names map to private IP addresses such as 192.168.*.* purpose,
which could cause DoS in certain situations.

Loading this component will make addresses resolved via DNS lookups
to be blocked, if they resolved to a private IP address such as 192.168.1.1.
Note that 127.0.0.1 is also considered a private IP.

=head1 METHODS

=head2 request_is_allowed

Overrides Gungho::Component::Core::request_is_allowed()

=head2 handle_dns_response

Overrides Gungho::Component::Core::handle_dns_response()

=head2 block_private_ip_address

Check the given address, and if it's a private address, generates an
error HTTP Response/

=head2 address_is_private

Given an address, returns true if the address looks like a private IP

=head1 SEE ALSO

L<Regexp::Common|Regexp::Common>

=cut