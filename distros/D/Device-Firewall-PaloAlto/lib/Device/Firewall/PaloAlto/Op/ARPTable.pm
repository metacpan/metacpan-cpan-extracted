package Device::Firewall::PaloAlto::Op::ARPTable;
$Device::Firewall::PaloAlto::Op::ARPTable::VERSION = '0.1.2';
use strict;
use warnings;
use 5.010;

use parent qw(Device::Firewall::PaloAlto::JSON);

use Device::Firewall::PaloAlto::Op::ARPEntry;

# VERSION
# PODNAME
# ABSTRACT: Palo Alto firewall ARP table


sub _new {
    my $class = shift;
    my ($api_return) = @_;
    my %arp_table;

    # Copy across the maximum and total enties in the table
    @arp_table{qw(max_entries total_entries)} = @{$api_return->{result}}{qw(max total)};

    my @entries = @{$api_return->{result}{entries}{entry}};

    # The ARP table is keyed on the IP address.
    $arp_table{entries} = { map { $_->{ip} => Device::Firewall::PaloAlto::Op::ARPEntry->_new($_) } @entries };

    return bless \%arp_table, $class;
}

sub current_entries { return $_[0]->{total_entries} + 0 }


sub max_entries { return $_[0]->{max_entries} + 0 }


sub to_array {
    my $self = shift;

    return values %{ $self->{entries} };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::ARPTable - Palo Alto firewall ARP table

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ERRORS 

=head1 METHODS

=head2 current_entries

    say "Current ARP entries: ". $fw->op->arp_table->current_entries;

Returns the current number of entries in the ARP table. 

=head2 max_entries 

    say "Current ARP entries: ". $fw->op->arp_table->max_entries;

Returns the maximum number of entries supported on the firewall.

=head2 to_array

Returns an array of L<Device::Firewall::PaloAlto::Op::ARPEntry> objects that represent the entries in the ARP table.

Returns undef if there are no entries in the table.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
