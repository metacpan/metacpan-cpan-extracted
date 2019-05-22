package Device::Firewall::PaloAlto::Op::ARPEntry;
$Device::Firewall::PaloAlto::Op::ARPEntry::VERSION = '0.1.8';
use strict;
use warnings;
use 5.010;

# VERSION
# PODNAME
# ABSTRACT: Palo Alto firewall ARP entry

use parent qw(Device::Firewall::PaloAlto::JSON);


sub _new {
    my $class = shift;
    my ($api_return) = @_;

    # Clean up the status field and transform into meaningful strings instead of single characters
    my %status_map = ( s => 'static', c => 'complete', e => 'expiring', i => 'incomplete' );
    my ($cleaned_status) = $api_return->{status} =~ m{\s+(\w)\s+}ms;
    $api_return->{status} = $status_map{$cleaned_status};

    return bless $api_return, $class;
}


sub mac { return lc $_[0]->{mac} }


sub status { return $_[0]->{status} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::ARPEntry - Palo Alto firewall ARP entry

=head1 VERSION

version 0.1.8

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ERRORS 

=head1 METHODS

=head2 mac

Returns the MAC address of the ARP entriy. Alphabetic hex digits are always in lower case.

=head2 status

Returns the status of the ARP entry. Can either be 'static', 'complete', 'expiring' or 'incomplete'

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
