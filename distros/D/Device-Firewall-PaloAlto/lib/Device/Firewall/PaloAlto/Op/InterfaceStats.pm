package Device::Firewall::PaloAlto::Op::InterfaceStats;
$Device::Firewall::PaloAlto::Op::InterfaceStats::VERSION = '0.1.9';
use strict;
use warnings;
use 5.010;

# VERSION
# PODNAME
# ABSTRACT: Palo Alto firewall interface statistics.

use parent qw(Device::Firewall::PaloAlto::JSON);


sub _new {
    my $class = shift;
    my ($api_return) = @_;

    # Return the Class::Error object
    return $api_return if !$api_return;

    return bless $api_return, $class;
}



sub bytes {
    my $self = shift;

    my $ifcounters = $self->{result}{ifnet}{counters}{ifnet}{entry}[0];

    return unless ref $ifcounters eq 'HASH';

    return @{$ifcounters}{qw(ibytes obytes)};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::InterfaceStats - Palo Alto firewall interface statistics.

=head1 VERSION

version 0.1.9

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ERRORS 

=head1 METHODS

=head2 hw_bytes

    my ($bytes_in, $bytes_out) = $fw->op->interface_stats('ethernet1/1')->hw_bytes;

Returns the number of bytes received and sent on the interface.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
