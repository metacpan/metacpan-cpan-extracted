package Device::Firewall::PaloAlto::Op::IPUserMap;
$Device::Firewall::PaloAlto::Op::IPUserMap::VERSION = '0.1.8';
use strict;
use warnings;
use 5.010;

# VERSION
# PODNAME
# ABSTRACT: Palo Alto IP to user mapping entry.

use parent qw(Device::Firewall::PaloAlto::JSON);


sub _new {
    my $class = shift;
    my ($api_response) = @_;
    my %userid_entry = %{$api_response};

    return bless \%userid_entry, $class;
}


sub ip { return $_[0]->{ip} }
sub user { return $_[0]->{user} }
sub type { return $_[0]->{type} }
sub vsys { return $_[0]->{vsys} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::IPUserMap - Palo Alto IP to user mapping entry.

=head1 VERSION

version 0.1.8

=head1 SYNOPSIS

    my $mappings = $fw->op->ip_user_mapping;
    say $_->name foreach $mappings->to_array; 

=head1 DESCRIPTION

This object represents a single IP to user mapping.

=head1 METHODS

=head2 ip

Returns the IP address of the IP to user mapping.

=head2 user

Returns the user of the IP to user mapping.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
