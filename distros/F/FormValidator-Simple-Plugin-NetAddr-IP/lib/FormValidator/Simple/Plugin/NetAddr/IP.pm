package FormValidator::Simple::Plugin::NetAddr::IP;

use strict;
use NetAddr::IP;
use FormValidator::Simple::Constants;

our $VERSION = '0.01';
our @CARP_NOT = qw(NetAddr::IP);

=head1 NAME

FormValidator::Simple::Plugin::NetAddr::IP - IP Address validation

=head1 SYNOPSIS

  use FormValidator::Simple qw/NetAddr::IP/;

  my $result = FormValidator::Simple->check( $req => [
      ip       => [ 'NOT_BLANK', 'NETADDR_IPV4HOST' ],
  ] );

=head1 DESCRIPTION

This module adds IP Address validation commands to FormValidator::Simple.
It uses NetAddr::IP to do the validation. There are other modules that may
do IP Address validation with less overhead, but NetAddr::IP was already
being used in the project that this was written for.

=head1 VALIDATION COMMANDS

=over 4

=item NETADDR_IP4HOST

Checks for a single IPv4 address. Address supplied must be in dotted
quad or CIDR format. Does not accept DNS names.

=cut

sub NETADDR_IP4HOST {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];

    my $ip = $self->_getaddr($data);

	return FALSE unless ( ref($ip) eq 'NetAddr::IP' );
    return ( $ip->version == 4 && $ip->masklen == 32 )  ? TRUE : FALSE;
}

=item NETADDR_IP4NET

Checks for a IPv4 network block. Address supplied must be in dotted
quad or CIDR format. Does not accept DNS names. A /32 is accepted
as a network.

=cut

sub NETADDR_IP4NET {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];

    my $ip = $self->_getaddr($data);

	return FALSE unless ( ref($ip) eq 'NetAddr::IP' );
    return ( $ip->version == 4 && $ip->masklen <= 32 )  ? TRUE : FALSE;
}

sub _getaddr {
    my ($self, $data) = @_;

	# Do not allow DNS resolution or partial addresses
	# even though NetAddr would do it.
	# Speeds things up quite a bit.
    return FALSE if $data =~ qr([\\a-zA-Z]);
    return FALSE unless $data =~ qr(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3});

    my $ip = NetAddr::IP->new($data);

	return ($ip);
}

1;
#__END__
# Below is stub documentation for your module. You'd better edit it!

=back

=head1 SEE ALSO

L<FormValidator::Simple>

L<NetAddr::IP>

L<Agent::TCLI::Package::Net> for which this module was needed.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

None known at this time.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut