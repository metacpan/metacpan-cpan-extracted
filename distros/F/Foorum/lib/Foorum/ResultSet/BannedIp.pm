package Foorum::ResultSet::BannedIp;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

use Net::IP::Match::Regexp qw( create_iprange_regexp match_ip );

sub get {
    my ($self) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key  = 'global|banned_ip';
    my $cache_data = $cache->get($cache_key);
    return wantarray ? @{$cache_data} : $cache_data
        if ( $cache_data and ref($cache_data) eq 'ARRAY' );
    $cache_data = [];

    my $rs = $schema->resultset('BannedIp')->search();
    while ( my $rec = $rs->next ) {
        push @{$cache_data}, $rec->cidr_ip;
    }
    $cache->set( $cache_key, $cache_data );
    return wantarray ? @{$cache_data} : $cache_data;
}

sub is_ip_banned {
    my ( $self, $ip ) = @_;

    my @cidr_ips = $self->get();
    if ( scalar @cidr_ips ) {
        my $regexp = create_iprange_regexp(@cidr_ips);
        if ( match_ip( $ip, $regexp ) ) {
            return 1;
        }
    }

    return 0;
}

1;
