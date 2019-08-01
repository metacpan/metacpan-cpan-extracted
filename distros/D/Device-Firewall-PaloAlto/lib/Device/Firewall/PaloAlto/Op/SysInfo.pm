package Device::Firewall::PaloAlto::Op::SysInfo;
$Device::Firewall::PaloAlto::Op::SysInfo::VERSION = '0.1.9';
use strict;
use warnings;
use 5.010;

# VERSION
# PODNAME
# ABSTRACT: Palo Alto firewall system information

use parent qw(Device::Firewall::PaloAlto::JSON);


sub _new {
    my $class = shift;
    my ($api_return) = @_;
    my %system_info = %{$api_return->{result}{system}};
    

    return bless \%system_info, $class;
}




sub hostname { return $_[0]->{hostname} }
sub mgmt_ip { return $_[0]->{'ip-address'} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::SysInfo - Palo Alto firewall system information

=head1 VERSION

version 0.1.9

=head1 SYNOPSIS

=head1 DESCRIPTION

This object represents the system information of the Palo Alto firewall.

=head1 METHODS

=head2 hostname

Returns the hostname of the device.

=head2 mgmt_ip

Returns the IPv4 address of the management interface.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
