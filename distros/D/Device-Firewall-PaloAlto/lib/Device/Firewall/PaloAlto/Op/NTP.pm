package Device::Firewall::PaloAlto::Op::NTP;
$Device::Firewall::PaloAlto::Op::NTP::VERSION = '0.1.9';
use strict;
use warnings;
use 5.010;

use parent qw(Device::Firewall::PaloAlto::JSON);

use Device::Firewall::PaloAlto::Errors qw(ERROR);

# VERSION
# PODNAME
# ABSTRACT: NTP synchronisation status of a Palo Alto firewall


sub _new {
    my $class = shift;
    my ($api_response) = @_;
    my %api_result = %{$api_response->{result}};
    my %ntp;

    # Check to see if NTP is responsive. If not return the error string passed.
    # This is yet another horrible API response from the PA
    if ($api_result{member} and !ref $api_result{member}) {
        return ERROR("NTP error: $api_result{member}");
    }

    $ntp{synched} = delete $api_result{synched} eq 'LOCAL' ? "" : 1;
    $ntp{servers} = [ $api_result{'ntp-server-1'}, $api_result{'ntp-server-2'} ];

    return bless \%ntp, $class;
}



sub synched { return $_[0]->{synched} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::NTP - NTP synchronisation status of a Palo Alto firewall

=head1 VERSION

version 0.1.9

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 synched

Returns true if the firewall is synchronised with an NTP server, false otherwise.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
