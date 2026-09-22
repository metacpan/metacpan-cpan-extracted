package IO::K8s::Role::MiddlewareTCPBuilder;
# ABSTRACT: Role for building Traefik TCP middleware configuration
our $VERSION = '1.108';
use Moo::Role;

# The fluent setters below build the spec through IO::K8s::Role::SpecBuilder
# rather than by hand, so that role is a hard dependency of this one (k103).
# IO::K8s::Role::APIObject composes SpecBuilder for every top-level Kind, so
# these are satisfied for anything built with IO::K8s::APIObject; a class
# that composes this role without them now fails at composition time,
# naming the missing method, instead of at the first setter call.
requires qw( spec_set );


sub in_flight_conn {
    my ($self, $amount) = @_;
    $self->spec_set('inFlightConn', {
        defined $amount ? (amount => $amount) : (),
    });
    return $self;
}


sub ip_allow_list {
    my ($self, @ranges) = @_;
    $self->spec_set('ipAllowList', { sourceRange => \@ranges });
    return $self;
}


sub ip_white_list {
    my ($self, @ranges) = @_;
    $self->spec_set('ipWhiteList', { sourceRange => \@ranges });
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::MiddlewareTCPBuilder - Role for building Traefik TCP middleware configuration

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    package My::TraefikMiddlewareTCP;
    use IO::K8s::APIObject
        api_version     => 'traefik.io/v1alpha1',
        resource_plural => 'middlewaretcps';
    with 'IO::K8s::Role::MiddlewareTCPBuilder';

    package main;
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $mw = $k8s->new_object('MiddlewareTCP',
        metadata => { name => 'db-guard', namespace => 'default' },
    );
    $mw->in_flight_conn(10)
       ->ip_allow_list('10.0.0.0/8');

=head1 DESCRIPTION

This role provides the fluent builders for Traefik's B<TCP> middleware.
Each method writes the corresponding block under the C<spec> key Traefik's
C<MiddlewareTCP> CRD expects, so the chain mirrors what a user would
compose in YAML.

A TCP middleware is a much smaller surface than an HTTP one: Traefik's
C<MiddlewareTCPSpec> carries only C<inFlightConn>, C<ipAllowList> and the
deprecated C<ipWhiteList>, and none of the HTTP middlewares (rate limiting,
basic auth, prefix stripping, scheme redirection, header injection) are
honoured on a TCP router. That is why this role is separate from
L<IO::K8s::Role::MiddlewareBuilder> instead of extending it -- calling an
HTTP builder on a C<MiddlewareTCP> fails as an unknown method rather than
silently producing a manifest Traefik ignores.

Each setter replaces its target block each time it is called; there is no
accumulating setter in this role.

Apply this role to any class whose C<spec> field is the Traefik
MiddlewareTCP wire schema. The bundled Traefik CRD
L<IO::K8s::Traefik::V1alpha1::MiddlewareTCP> is the obvious target, but the
role composes on custom CRD classes too.

=head2 in_flight_conn

    $mw->in_flight_conn($amount);

Configures the Traefik inFlightConn middleware, which caps how many
simultaneous TCP connections the middleware lets through -- once C<$amount>
connections are open the next one is closed rather than queued. Writes the
C<< spec.inFlightConn = { amount =E<gt> $amount } >> block, replacing any
prior one. Passing no amount writes an empty C<< {} >> rather than a
populated block. Returns C<$self> for chaining.

    $mw->in_flight_conn(10);

=head2 ip_allow_list

    $mw->ip_allow_list(@ranges);

Configures the Traefik ipAllowList middleware to accept connections only
from the given client IPs, each written either as a plain address or in
CIDR notation. The ranges are written as a single
C<< { sourceRange =E<gt> [...] } >> block, replacing any prior ipAllowList
block. Pass an empty list to emit an empty C<ipAllowList.sourceRange>
array. Returns C<$self> for chaining.

    $mw->ip_allow_list('10.0.0.0/8', '192.168.1.7');

=head2 ip_white_list

    $mw->ip_white_list(@ranges);

Same shape as C<ip_allow_list>, but writing the C<ipWhiteList> block.
Upstream Traefik deprecated C<ipWhiteList> in favour of C<ipAllowList>;
this method exists so a manifest that still carries the old field can be
built and round-tripped, not as the way to express new configuration --
use C<ip_allow_list> for that. Returns C<$self> for chaining.

=head1 SEE ALSO

L<IO::K8s::Traefik>, L<IO::K8s::Role::MiddlewareBuilder>,
L<IO::K8s::Role::SpecBuilder>, L<IO::K8s::APIObject>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
