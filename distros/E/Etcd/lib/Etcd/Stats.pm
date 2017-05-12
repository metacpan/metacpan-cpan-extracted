package Etcd::Stats;
$Etcd::Stats::VERSION = '0.004';
use namespace::autoclean;

use JSON qw(decode_json);
use Carp qw(croak);

use Moo::Role;
use Types::Standard qw(Str);

requires qw(version_prefix api_exec);

has _stats_endpoint => ( is => 'lazy', isa => Str );
sub _build__stats_endpoint {
    shift->version_prefix . '/stats';
}

# XXX should return real objects
sub stats {
    my ($self, $type, %args) = @_;
    croak 'usage: $etcd->type("leader|store|self", [%args])' if !defined $type || $type !~ m/^(?:leader|store|self)$/;
    decode_json($self->api_exec($self->_stats_endpoint."/$type", 'GET', %args)->{content});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Etcd::Stats - etcd stats API

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Etcd;
    my $etcd = Etcd->new;
    
    my $leader_stats = $etcd->stats("leader");
    
    my $store_stats = $etcd->stats("store");
    
    my $self_stats = $etcd->stats("self");

=head1 DESCRIPTION

This module provides access to etcd's stats API.

=head1 METHODS

=over 4

=item *

C<stats>

    my $leader_stats = $etcd->stats("leader");

    my $store_stats = $etcd->stats("store");

    my $self_stats = $etcd->stats("self");

Returns a hashref of values for the requested statistics type. The contents of
the hash is described in the API documentation. See L<Etcd/SEE ALSO> for
further reading.

On error, C<$@> will contain either a reference to a L<Etcd::Error> object (for
API-level errors) or a regular string (for network, transport or other errors).

=back

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
