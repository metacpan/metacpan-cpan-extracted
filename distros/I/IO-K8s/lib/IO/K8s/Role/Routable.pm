package IO::K8s::Role::Routable;
# ABSTRACT: Role for building HTTP/gRPC routing rules
our $VERSION = '1.108';
use Carp qw( croak );
use Scalar::Util qw( looks_like_number );
# Imports above `use Moo::Role` on purpose: Role::Tiny treats subs already in
# the package as not-methods, so their names stay off every consumer. A `use`
# below that line composes its exports onto all shipped classes (k118).
use Moo::Role;

requires '_route_format';

# The fluent setters below build the spec through IO::K8s::Role::SpecBuilder
# rather than by hand, so that role is a hard dependency of this one (k103).
# IO::K8s::Role::APIObject composes SpecBuilder for every top-level Kind, so
# these are satisfied for anything built with IO::K8s::APIObject; a class
# that composes this role without them now fails at composition time,
# naming the missing method, instead of at the first setter call.
requires qw( spec_get spec_push spec_set );

# The 'ingress' branch builds core networking.k8s.io/v1 objects by name, and
# a role cannot `use` them at the top: composing this role would then drag
# the whole Ingress class family into every Gateway API and Traefik consumer
# that never touches that branch. Load them only on the branch that needs
# them, the way IO::K8s::Role::APIObject loads ObjectMeta/OwnerReference and
# IO::K8s::Role::NetworkPolicy loads its own spec class.
sub _load_ingress_classes {
    my ($self) = @_;
    require IO::K8s::Api::Networking::V1::IngressSpec;
    require IO::K8s::Api::Networking::V1::IngressRule;
    require IO::K8s::Api::Networking::V1::HTTPIngressRuleValue;
    require IO::K8s::Api::Networking::V1::HTTPIngressPath;
    require IO::K8s::Api::Networking::V1::IngressBackend;
    require IO::K8s::Api::Networking::V1::IngressServiceBackend;
    require IO::K8s::Api::Networking::V1::ServiceBackendPort;
}

# The single place the ingress spec is vivified; before k117 the same lines
# sat inlined in three method bodies.
sub _ensure_ingress_spec {
    my ($self) = @_;
    $self->_load_ingress_classes;

    my $spec = $self->spec;
    return $spec if $spec;
    $spec = IO::K8s::Api::Networking::V1::IngressSpec->new;
    $self->spec($spec);
    return $spec;
}

sub _build_ingress_path_backend {
    my ($self, $service, $port) = @_;
    return IO::K8s::Api::Networking::V1::IngressBackend->new(
        service => IO::K8s::Api::Networking::V1::IngressServiceBackend->new(
            name => $service,
            port => IO::K8s::Api::Networking::V1::ServiceBackendPort->new(
                looks_like_number($port) ? ( number => $port ) : ( name => $port )
            )
        )
    );
}


sub add_hostname {
    my ($self, @hostnames) = @_;
    my $format = $self->_route_format;
    if ($format eq 'gateway') {
        $self->spec_push('hostnames', @hostnames);
    } elsif ($format eq 'traefik') {
        # Traefik uses match rules like Host(`example.com`)
        # We add a route with the host match
        my $hosts = join ', ', map { "Host(`$_`)" } @hostnames;
        $self->spec_push('routes', { match => $hosts, kind => 'Rule', services => [] });
    } elsif ($format eq 'ingress') {
        my $spec = $self->_ensure_ingress_spec;
        my $rules = $spec->rules // [];
        for my $hostname (@hostnames) {
            push @$rules, IO::K8s::Api::Networking::V1::IngressRule->new(
                host => $hostname,
            );
        }
        $spec->rules($rules);
    }
    return $self;
}


sub add_backend {
    my ($self, $name, %opts) = @_;
    my $format = $self->_route_format;
    my %backend = (
        name => $name,
        $opts{port}   ? (port   => $opts{port})   : (),
        $opts{weight} ? (weight => $opts{weight}) : (),
    );
    if ($format eq 'gateway') {
        $self->spec_push('rules.-1.backendRefs', \%backend);
    } elsif ($format eq 'traefik') {
        $self->spec_push('routes.-1.services', \%backend);
    } elsif ($format eq 'ingress') {
        my $spec = $self->_ensure_ingress_spec;
        $spec->defaultBackend(IO::K8s::Api::Networking::V1::IngressBackend->new(
            service => IO::K8s::Api::Networking::V1::IngressServiceBackend->new(
                name => $name,
                port => IO::K8s::Api::Networking::V1::ServiceBackendPort->new(
                    number => $opts{port},
                ),
            ),
        ));
    }
    return $self;
}


sub add_path_match {
    my ($self, $path, %opts) = @_;
    my $type = $opts{type} // 'Prefix';
    my $format = $self->_route_format;
    if ($format eq 'gateway') {
        # This role's own vocabulary (Prefix/Exact/Regex, documented above)
        # is not the Gateway API HTTPPathMatch.type enum (Exact/PathPrefix/
        # RegularExpression, k95/D5) -- translate it the same way the
        # 'traefik' branch below translates it into Traefik's match syntax.
        my $gw_type = $type eq 'Prefix' ? 'PathPrefix'
                    : $type eq 'Regex'  ? 'RegularExpression'
                    : $type;    # 'Exact' is spelled the same in both vocabularies
        $self->spec_push('rules.-1.matches', { path => { type => $gw_type, value => $path } });
    } elsif ($format eq 'traefik') {
        my $match = $type eq 'Prefix' ? "PathPrefix(`$path`)"
                  : $type eq 'Exact'  ? "Path(`$path`)"
                  : $type eq 'Regex'  ? "PathRegexp(`$path`)"
                  : undef;
        $self->spec_set('routes.-1.match', $match) if defined $match;
    } elsif ($format eq 'ingress') {
        croak __PACKAGE__.'->add_path_match service is required'
            unless defined $opts{service};
        croak __PACKAGE__.'->add_path_match port is required'
            unless defined $opts{port};
        croak __PACKAGE__.'->add_path_match does not support Ingress path type '
            . $type
            unless $type eq 'Prefix'
                || $type eq 'Exact'
                || $type eq 'ImplementationSpecific';
        if ($type eq 'ImplementationSpecific') {
            croak __PACKAGE__.'->add_path_match path is required and must start with /'
                if defined $path && length $path && $path !~ m{\A/};
        } else {
            croak __PACKAGE__.'->add_path_match path is required and must start with /'
                unless defined $path && $path =~ m{\A/};
        }

        $self->_load_ingress_classes;
        my $backend = $self->_build_ingress_path_backend($opts{service}, $opts{port});
        my $path_rule = IO::K8s::Api::Networking::V1::HTTPIngressPath->new(
            backend  => $backend,
            path     => $path,
            pathType => $type
        );

        my $spec = $self->_ensure_ingress_spec;
        my $rules = $spec->rules // [];
        my $rule = $rules->[-1];
        if ($rule) {
            my $http = $rule->http;
            if ($http) {
                my $paths = $http->paths // [];
                push @$paths, $path_rule;
                $http->paths($paths);
            } else {
                $rule->http(IO::K8s::Api::Networking::V1::HTTPIngressRuleValue->new(
                    paths => [$path_rule]
                ));
            }
        } else {
            push @$rules, IO::K8s::Api::Networking::V1::IngressRule->new(
                http => IO::K8s::Api::Networking::V1::HTTPIngressRuleValue->new(
                    paths => [$path_rule]
                )
            );
            $spec->rules($rules);
        }
    }
    return $self;
}


sub add_header_match {
    my ($self, $header, $value) = @_;
    my $format = $self->_route_format;
    if ($format eq 'gateway') {
        $self->spec_push('rules.-1.matches.-1.headers', { name => $header, value => $value });
    } elsif ($format eq 'traefik') {
        my $existing = $self->spec_get('routes.-1.match') // '';
        my $header_match = "Header(`$header`, `$value`)";
        $self->spec_set('routes.-1.match', $existing ? "$existing && $header_match" : $header_match);
    }
    # Ingress doesn't support header matching natively
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::Routable - Role for building HTTP/gRPC routing rules

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    package My::Route;
    use IO::K8s::APIObject api_version => 'gateway.networking.k8s.io/v1';
    k8s spec => { Str => 1 };
    with 'IO::K8s::Role::Routable';

    sub _route_format { 'gateway' }   # or 'traefik', 'ingress'

    package main;
    my $r = My::Route->new;
    $r->add_hostname('example.com')
      ->add_backend('api-v1', port => 8080, weight => 90)
      ->add_path_match('/api', type => 'Prefix')
      ->add_header_match('X-Env', 'production');

    # An ingress-formatted route gives every path its own backend.
    use IO::K8s::Api::Networking::V1::Ingress;
    my $ingress = IO::K8s::Api::Networking::V1::Ingress->new(
        metadata => { name => 'web', namespace => 'prod' },
    );
    $ingress->add_path_match(
        '/api', type => 'Prefix', service => 'api', port => 8080,
    );

=head1 DESCRIPTION

This role provides fluent HTTP routing builders. A consuming class must
declare a C<spec> attribute as well as implement C<_route_format>; the
C<spec> declaration in the synopsis permits
L<IO::K8s::Role::SpecBuilder> to create the route structure. The role
dispatches on C<_route_format>, which must return C<'gateway'>,
C<'traefik'>, or C<'ingress'>.

Gateway API HTTPRoute and Traefik IngressRoute support the generic routing
chain in the synopsis. Core Kubernetes Ingress has distinct backend slots:
C<add_backend> writes C<spec.defaultBackend> for unmatched requests, while
C<add_path_match> requires C<service> and C<port> and writes that path's own
backend. Thus an Ingress path must not rely on a preceding C<add_backend>
call for its backend.

The three formats produce different wire shapes:

=over

=item * C<'gateway'> writes through L<IO::K8s::Role::SpecBuilder>'s
C<spec_*> methods into a C<spec> that mirrors the HTTPRoute wire schema
(C<hostnames>, C<rules[].matches[].path>, C<rules[].backendRefs>) --
either a plain hash or a typed struct.

=item * C<'traefik'> writes the same way into a C<spec> that mirrors the
IngressRoute wire schema (C<routes[].match> as a Traefik expression,
C<routes[].services[]>).

=item * C<'ingress'> builds typed L<IO::K8s::Api::Networking::V1::IngressSpec>
/ C<IngressRule> / C<HTTPIngressRuleValue> / C<HTTPIngressPath> /
C<IngressBackend> / C<IngressServiceBackend> / C<ServiceBackendPort> objects.
C<add_path_match> adds a typed path-specific backend, and C<add_backend>
continues to set only C<spec.defaultBackend>. The nested Ingress classes are
loaded when the ingress branch first runs, not at composition time, so
composing this role onto a Gateway API or Traefik Kind pulls none of them in.

=back

C<add_path_match> operates on the last rule in C<spec.rules> for Gateway and
Ingress, or the last route in C<spec.routes> for Traefik. C<add_hostname>
creates an Ingress rule for each hostname; chain calls in declaration order
therefore retain their natural top-to-bottom manifest order.

=head2 add_hostname

    $route->add_hostname('example.com', 'api.example.com');

Adds hostnames the route should match. The role dispatches on
C<_route_format>:

=over

=item * C<'gateway'> -- Gateway API HTTPRoute. Appends to
C<spec.hostnames>. Each hostname becomes its own entry on the
C<hostnames> list.

=item * C<'traefik'> -- Traefik IngressRoute. Adds a new C<routes> entry
whose C<match> string combines each hostname with C<Host(`...`)>, e.g.
C<< match =E<gt> 'Host(`example.com`), Host(`api.example.com`)' >>.

=item * C<'ingress'> -- core Kubernetes Ingress. Appends an
L<IO::K8s::Api::Networking::V1::IngressRule> per hostname with
C<host =E<gt> $hostname>.

=back

Returns C<$self> for chaining.

    $route->add_hostname('example.com');

=head2 add_backend

    $route->add_backend('api-v1', port => 8080, weight => 90);

Adds a backend the route should dispatch traffic to. C<name> is required;
C<port> and C<weight> are optional. Dispatch is per format:

=over

=item * C<'gateway'> -- appends to the last rule's C<backendRefs> as
C<< { name, port, weight } >>.

=item * C<'traefik'> -- appends to the last route's C<services> as
C<< { name, port, weight } >>.

=item * C<'ingress'> -- replaces C<spec.defaultBackend> with a typed
IngressBackend / IngressServiceBackend / ServiceBackendPort chain, using
the last C<name> and C<port>.

=back

Returns C<$self> for chaining.

    $route->add_backend('api-v1', port => 8080, weight => 90);

=head2 add_path_match

    # Gateway API or Traefik
    $route->add_path_match('/api', type => 'Prefix');

    # core Kubernetes Ingress
    $ingress->add_path_match(
        '/api', type => 'Prefix', service => 'api', port => 8080,
    );

Adds a path match to the most recently added routing rule. C<type> defaults
to C<'Prefix'>. For Gateway API and Traefik, the shared vocabulary selects
one of:

=over

=item * C<'Prefix'> -- Gateway API C<< { path: { type: 'PathPrefix', value } } >>,
Traefik C<PathPrefix(`...`)>.

=item * C<'Exact'> -- Gateway API C<< { path: { type: 'Exact', value } } >>,
Traefik C<Path(`...`)>.

=item * C<'Regex'> -- Gateway API C<< { path: { type: 'RegularExpression', value } } >>,
Traefik C<PathRegexp(`...`)>.

=back

For C<'ingress'>, this creates a typed
L<IO::K8s::Api::Networking::V1::HTTPIngressPath> with its own typed backend.
C<service> and C<port> are required; C<port> may be a numeric or named
Service port. A numeric port is written as C<service.port.number>, and a
named port as C<service.port.name>. Ingress accepts C<'Prefix'>, C<'Exact'>,
and C<'ImplementationSpecific'>. C<'Prefix'> and C<'Exact'> require a
defined path starting with C</>. C<'ImplementationSpecific'> permits an
undefined or empty path, but a nonempty path must also start with C</>.

An Ingress call with a missing C<service> or C<port>, an unsupported path
type, or an invalid C<'Prefix'>, C<'Exact'>, or nonempty
C<'ImplementationSpecific'> path croaks before it mutates the object. C<add_backend> remains independent: it writes
C<spec.defaultBackend>, the fallback for unmatched requests, and is never
reused as a path backend.

Returns C<$self> for chaining.

=head2 add_header_match

    $route->add_header_match('X-Env', 'production');

Adds a header-based match to the most recently added routing rule.
Gateway API appends to the last match's C<headers> array as
C<< { name =E<gt> $header, value =E<gt> $value } >>; Traefik extends the
route's C<match> string with C<< && Header(`<name>`, `<value>`) >>.
Core Ingress does not support header matching natively and the call is a
no-op in that mode. Returns C<$self> for chaining.

=head1 REQUIRED METHODS

=head2 _route_format

Must return C<'gateway'>, C<'traefik'>, or C<'ingress'>. The role
dispatches all method bodies on this answer; a missing or unknown value
is treated as a no-op.

=head1 SEE ALSO

L<IO::K8s::GatewayAPI>, L<IO::K8s::Traefik>,
L<IO::K8s::Api::Networking::V1::IngressSpec>, L<IO::K8s::APIObject>

=cut

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
