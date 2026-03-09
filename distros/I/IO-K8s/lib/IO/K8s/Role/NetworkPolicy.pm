package IO::K8s::Role::NetworkPolicy;
# ABSTRACT: Role for building network policies (core K8s and Cilium)
our $VERSION = '1.008';
use Moo::Role;
use IO::K8s::Types::Net qw( cidr_contains );
use Carp qw(croak);

requires '_netpol_format';

sub select_pods {
    my ($self, %labels) = @_;
    my $format = $self->_netpol_format;

    if ($format eq 'core') {
        $self->_ensure_spec;
        $self->spec->podSelector(
            IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector->new(
                matchLabels => \%labels,
            )
        );
    } elsif ($format eq 'cilium') {
        my $spec = $self->spec // {};
        $spec->{endpointSelector} = { matchLabels => \%labels };
        $self->spec($spec);
    }
    return $self;
}

sub allow_ingress_from_pods {
    my ($self, $labels, %opts) = @_;
    my $format = $self->_netpol_format;

    if ($format eq 'core') {
        $self->_add_core_ingress_rule(
            { podSelector => { matchLabels => $labels } },
            $opts{ports},
        );
    } elsif ($format eq 'cilium') {
        $self->_add_cilium_ingress_rule(
            { matchLabels => $labels },
            $opts{ports},
        );
    }
    return $self;
}

sub allow_ingress_from_cidrs {
    my ($self, $cidrs, %opts) = @_;
    _validate_cidrs($cidrs);
    my $format = $self->_netpol_format;

    if ($format eq 'core') {
        my @from = map { { ipBlock => { cidr => $_ } } } @$cidrs;
        $self->_add_core_ingress_rule_multi(\@from, $opts{ports});
    } elsif ($format eq 'cilium') {
        my $spec = $self->spec // {};
        my $ingress = $spec->{ingress} //= [];
        push @$ingress, {
            fromCIDR => $cidrs,
            $opts{ports} ? (toPorts => [{ ports => $opts{ports} }]) : (),
        };
        $self->spec($spec);
    }
    return $self;
}

sub allow_ingress_from_namespace {
    my ($self, $namespace, %opts) = @_;
    my $format = $self->_netpol_format;

    if ($format eq 'core') {
        $self->_add_core_ingress_rule(
            { namespaceSelector => { matchLabels => { 'kubernetes.io/metadata.name' => $namespace } } },
            $opts{ports},
        );
    } elsif ($format eq 'cilium') {
        my $spec = $self->spec // {};
        my $ingress = $spec->{ingress} //= [];
        push @$ingress, {
            fromEndpoints => [{ matchLabels => { 'k8s:io.kubernetes.pod.namespace' => $namespace } }],
            $opts{ports} ? (toPorts => [{ ports => $opts{ports} }]) : (),
        };
        $self->spec($spec);
    }
    return $self;
}

sub allow_egress_to_pods {
    my ($self, $labels, %opts) = @_;
    my $format = $self->_netpol_format;

    if ($format eq 'core') {
        $self->_add_core_egress_rule(
            { podSelector => { matchLabels => $labels } },
            $opts{ports},
        );
    } elsif ($format eq 'cilium') {
        my $spec = $self->spec // {};
        my $egress = $spec->{egress} //= [];
        push @$egress, {
            toEndpoints => [{ matchLabels => $labels }],
            $opts{ports} ? (toPorts => [{ ports => $opts{ports} }]) : (),
        };
        $self->spec($spec);
    }
    return $self;
}

sub allow_egress_to_cidrs {
    my ($self, $cidrs) = @_;
    _validate_cidrs($cidrs);
    my $format = $self->_netpol_format;

    if ($format eq 'core') {
        $self->_add_core_egress_rule_multi(
            [ map { { ipBlock => { cidr => $_ } } } @$cidrs ],
        );
    } elsif ($format eq 'cilium') {
        my $spec = $self->spec // {};
        my $egress = $spec->{egress} //= [];
        push @$egress, { toCIDR => $cidrs };
        $self->spec($spec);
    }
    return $self;
}

sub allow_egress_to_dns {
    my ($self) = @_;
    my $dns_ports = [
        { port => 53, protocol => 'UDP' },
        { port => 53, protocol => 'TCP' },
    ];
    my $format = $self->_netpol_format;

    if ($format eq 'core') {
        $self->_add_core_egress_rule(undef, $dns_ports);
    } elsif ($format eq 'cilium') {
        my $spec = $self->spec // {};
        my $egress = $spec->{egress} //= [];
        push @$egress, {
            toEndpoints => [{ matchLabels => { 'k8s:io.kubernetes.pod.namespace' => 'kube-system', 'k8s:k8s-app' => 'kube-dns' } }],
            toPorts => [{ ports => $dns_ports }],
        };
        $self->spec($spec);
    }
    return $self;
}

sub deny_all_ingress {
    my ($self) = @_;
    my $format = $self->_netpol_format;

    if ($format eq 'core') {
        $self->_ensure_spec;
        $self->_ensure_policy_types('Ingress');
        # Empty ingress array = deny all
        $self->spec->ingress([]);
    } elsif ($format eq 'cilium') {
        my $spec = $self->spec // {};
        $spec->{ingress} = [];
        $spec->{ingressDeny} = [{}];
        $self->spec($spec);
    }
    return $self;
}

sub deny_all_egress {
    my ($self) = @_;
    my $format = $self->_netpol_format;

    if ($format eq 'core') {
        $self->_ensure_spec;
        $self->_ensure_policy_types('Egress');
        $self->spec->egress([]);
    } elsif ($format eq 'cilium') {
        my $spec = $self->spec // {};
        $spec->{egress} = [];
        $spec->{egressDeny} = [{}];
        $self->spec($spec);
    }
    return $self;
}

# --- Private helpers ---

sub _validate_cidrs {
    my ($cidrs) = @_;
    require IO::K8s::Types::Net;
    for my $cidr (@$cidrs) {
        croak "'$cidr' is not valid CIDR notation"
            unless $cidr =~ /\// && defined Net::IP->new($cidr);
    }
}

# Core K8s helpers (work on typed spec objects)
sub _ensure_spec {
    my ($self) = @_;
    unless ($self->spec) {
        if ($self->_netpol_format eq 'core') {
            require IO::K8s::Api::Networking::V1::NetworkPolicySpec;
            $self->spec(IO::K8s::Api::Networking::V1::NetworkPolicySpec->new(
                podSelector => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector->new,
            ));
        }
    }
}

sub _ensure_policy_types {
    my ($self, $type) = @_;
    return unless $self->_netpol_format eq 'core';
    my $spec = $self->spec;
    my $types = $spec->policyTypes // [];
    unless (grep { $_ eq $type } @$types) {
        push @$types, $type;
        $spec->policyTypes($types);
    }
}

sub _core_ports {
    my ($ports) = @_;
    return () unless $ports;
    return (ports => [
        map {
            IO::K8s::Api::Networking::V1::NetworkPolicyPort->new(
                port     => $_->{port},
                protocol => $_->{protocol} // 'TCP',
            )
        } @$ports
    ]);
}

sub _add_core_ingress_rule {
    my ($self, $from, $ports) = @_;
    $self->_ensure_spec;
    $self->_ensure_policy_types('Ingress');
    my $spec = $self->spec;
    my $ingress = $spec->ingress // [];

    my %rule;
    $rule{from} = [
        IO::K8s::Api::Networking::V1::NetworkPolicyPeer->new(%$from)
    ] if $from;
    if ($ports) {
        $rule{ports} = [
            map {
                IO::K8s::Api::Networking::V1::NetworkPolicyPort->new(
                    port => $_->{port}, protocol => $_->{protocol} // 'TCP',
                )
            } @$ports
        ];
    }

    push @$ingress, IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule->new(%rule);
    $spec->ingress($ingress);
}

sub _add_core_ingress_rule_multi {
    my ($self, $from_list, $ports) = @_;
    $self->_ensure_spec;
    $self->_ensure_policy_types('Ingress');
    my $spec = $self->spec;
    my $ingress = $spec->ingress // [];

    my %rule;
    $rule{from} = [
        map { IO::K8s::Api::Networking::V1::NetworkPolicyPeer->new(%$_) } @$from_list
    ] if $from_list;
    if ($ports) {
        $rule{ports} = [
            map {
                IO::K8s::Api::Networking::V1::NetworkPolicyPort->new(
                    port => $_->{port}, protocol => $_->{protocol} // 'TCP',
                )
            } @$ports
        ];
    }

    push @$ingress, IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule->new(%rule);
    $spec->ingress($ingress);
}

sub _add_core_egress_rule {
    my ($self, $to, $ports) = @_;
    $self->_ensure_spec;
    $self->_ensure_policy_types('Egress');
    my $spec = $self->spec;
    my $egress = $spec->egress // [];

    my %rule;
    $rule{to} = [
        IO::K8s::Api::Networking::V1::NetworkPolicyPeer->new(%$to)
    ] if $to;
    if ($ports) {
        $rule{ports} = [
            map {
                IO::K8s::Api::Networking::V1::NetworkPolicyPort->new(
                    port => $_->{port}, protocol => $_->{protocol} // 'TCP',
                )
            } @$ports
        ];
    }

    push @$egress, IO::K8s::Api::Networking::V1::NetworkPolicyEgressRule->new(%rule);
    $spec->egress($egress);
}

sub _add_core_egress_rule_multi {
    my ($self, $to_list, $ports) = @_;
    $self->_ensure_spec;
    $self->_ensure_policy_types('Egress');
    my $spec = $self->spec;
    my $egress = $spec->egress // [];

    my %rule;
    $rule{to} = [
        map { IO::K8s::Api::Networking::V1::NetworkPolicyPeer->new(%$_) } @$to_list
    ] if $to_list;
    if ($ports) {
        $rule{ports} = [
            map {
                IO::K8s::Api::Networking::V1::NetworkPolicyPort->new(
                    port => $_->{port}, protocol => $_->{protocol} // 'TCP',
                )
            } @$ports
        ];
    }

    push @$egress, IO::K8s::Api::Networking::V1::NetworkPolicyEgressRule->new(%rule);
    $spec->egress($egress);
}

sub _add_cilium_ingress_rule {
    my ($self, $endpoint_selector, $ports) = @_;
    my $spec = $self->spec // {};
    my $ingress = $spec->{ingress} //= [];
    push @$ingress, {
        fromEndpoints => [$endpoint_selector],
        $ports ? (toPorts => [{ ports => $ports }]) : (),
    };
    $self->spec($spec);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::NetworkPolicy - Role for building network policies (core K8s and Cilium)

=head1 VERSION

version 1.008

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
