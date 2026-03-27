package IO::K8s::Role::Routable;
# ABSTRACT: Role for building HTTP/gRPC routing rules
our $VERSION = '1.100';
use Moo::Role;

requires '_route_format';

sub add_hostname {
    my ($self, @hostnames) = @_;
    my $format = $self->_route_format;

    if ($format eq 'gateway') {
        my $spec = $self->spec // {};
        my $existing = $spec->{hostnames} // [];
        push @$existing, @hostnames;
        $spec->{hostnames} = $existing;
        $self->spec($spec);
    } elsif ($format eq 'traefik') {
        # Traefik uses match rules like Host(`example.com`)
        # We add a route with the host match
        my $spec = $self->spec // {};
        my $routes = $spec->{routes} //= [];
        my $hosts = join ', ', map { "Host(`$_`)" } @hostnames;
        push @$routes, { match => $hosts, kind => 'Rule', services => [] };
        $self->spec($spec);
    } elsif ($format eq 'ingress') {
        my $spec = $self->spec;
        unless ($spec) {
            require IO::K8s::Api::Networking::V1::IngressSpec;
            $spec = IO::K8s::Api::Networking::V1::IngressSpec->new;
            $self->spec($spec);
        }
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

    if ($format eq 'gateway') {
        my $spec = $self->spec // {};
        my $rules = $spec->{rules} //= [{}];
        my $rule = $rules->[-1];
        my $backends = $rule->{backendRefs} //= [];
        push @$backends, {
            name => $name,
            $opts{port}   ? (port   => $opts{port})   : (),
            $opts{weight} ? (weight => $opts{weight}) : (),
        };
        $self->spec($spec);
    } elsif ($format eq 'traefik') {
        my $spec = $self->spec // {};
        my $routes = $spec->{routes} //= [{}];
        my $route = $routes->[-1];
        my $services = $route->{services} //= [];
        push @$services, {
            name => $name,
            $opts{port}   ? (port   => $opts{port})   : (),
            $opts{weight} ? (weight => $opts{weight}) : (),
        };
        $self->spec($spec);
    } elsif ($format eq 'ingress') {
        # For Ingress, add to the last rule's paths
        my $spec = $self->spec;
        unless ($spec) {
            require IO::K8s::Api::Networking::V1::IngressSpec;
            $spec = IO::K8s::Api::Networking::V1::IngressSpec->new;
            $self->spec($spec);
        }
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
        my $spec = $self->spec // {};
        my $rules = $spec->{rules} //= [{}];
        my $rule = $rules->[-1];
        my $matches = $rule->{matches} //= [];
        push @$matches, {
            path => { type => $type, value => $path },
        };
        $self->spec($spec);
    } elsif ($format eq 'traefik') {
        my $spec = $self->spec // {};
        my $routes = $spec->{routes} //= [{}];
        my $route = $routes->[-1];
        if ($type eq 'Prefix') {
            $route->{match} = "PathPrefix(`$path`)";
        } elsif ($type eq 'Exact') {
            $route->{match} = "Path(`$path`)";
        } elsif ($type eq 'Regex') {
            $route->{match} = "PathRegexp(`$path`)";
        }
        $self->spec($spec);
    } elsif ($format eq 'ingress') {
        my $spec = $self->spec;
        unless ($spec) {
            require IO::K8s::Api::Networking::V1::IngressSpec;
            $spec = IO::K8s::Api::Networking::V1::IngressSpec->new;
            $self->spec($spec);
        }
        my $rules = $spec->rules // [];
        # Add path to the last rule, or create new one
        my $rule = @$rules ? $rules->[-1] : IO::K8s::Api::Networking::V1::IngressRule->new;
        push @$rules, $rule unless @$rules;
        my $http = $rule->http;
        unless ($http) {
            $http = IO::K8s::Api::Networking::V1::HTTPIngressRuleValue->new(paths => []);
            $rule->http($http);
        }
        my $paths = $http->paths // [];
        push @$paths, IO::K8s::Api::Networking::V1::HTTPIngressPath->new(
            path     => $path,
            pathType => $type,
        );
        $http->paths($paths);
        $spec->rules($rules);
    }
    return $self;
}

sub add_header_match {
    my ($self, $header, $value) = @_;
    my $format = $self->_route_format;

    if ($format eq 'gateway') {
        my $spec = $self->spec // {};
        my $rules = $spec->{rules} //= [{}];
        my $rule = $rules->[-1];
        my $matches = $rule->{matches} //= [{}];
        my $match = $matches->[-1];
        my $headers = $match->{headers} //= [];
        push @$headers, { name => $header, value => $value };
        $self->spec($spec);
    } elsif ($format eq 'traefik') {
        my $spec = $self->spec // {};
        my $routes = $spec->{routes} //= [{}];
        my $route = $routes->[-1];
        my $existing = $route->{match} // '';
        my $header_match = "Header(`$header`, `$value`)";
        $route->{match} = $existing ? "$existing && $header_match" : $header_match;
        $self->spec($spec);
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

version 1.100

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
