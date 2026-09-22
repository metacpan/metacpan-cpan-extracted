package IO::K8s::Role::NetworkPolicy;
# ABSTRACT: Role for building network policies (core K8s and Cilium)
our $VERSION = '1.108';
use IO::K8s::Types::Net qw( cidr_contains );
use Carp qw(croak);
# Imports above `use Moo::Role` on purpose: Role::Tiny treats subs already in
# the package as not-methods, so their names stay off every consumer. A `use`
# below that line composes its exports onto all shipped classes (k118).
use Moo::Role;

requires '_netpol_format';

# The fluent setters below build the spec through IO::K8s::Role::SpecBuilder
# rather than by hand, so that role is a hard dependency of this one (k103).
# IO::K8s::Role::APIObject composes SpecBuilder for every top-level Kind, so
# these are satisfied for anything built with IO::K8s::APIObject; a class
# that composes this role without them now fails at composition time,
# naming the missing method, instead of at the first setter call.
requires qw( spec_push spec_set );

# ---------------------------------------------------------------------------
# Facts both formats need, written once.
#
# The two branches spell a selector in different vocabularies -- core
# Kubernetes selects a namespace by the kubernetes.io/metadata.name label the
# API server sets on every namespace, Cilium by its own k8s: label prefixes --
# but they address the same namespaces and the same pods. Keeping the facts
# here and the spelling in the branches is what stops the two from drifting:
# before k117 the CoreDNS target below existed only in the cilium branch, and
# the core branch quietly emitted a ports-only rule that allowed DNS to any
# destination, which is looser than what its own documentation promised.
# ---------------------------------------------------------------------------

my $CORE_NAMESPACE_LABEL   = 'kubernetes.io/metadata.name';
my $CILIUM_NAMESPACE_LABEL = 'k8s:io.kubernetes.pod.namespace';

# The cluster's DNS: the CoreDNS pods in kube-system, which carry
# k8s-app=kube-dns (the label CoreDNS inherited from kube-dns and every
# distribution still sets).
my %DNS_TARGET = (
    namespace  => 'kube-system',
    pod_labels => { 'k8s-app' => 'kube-dns' },
);


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
        $self->spec_set('endpointSelector', { matchLabels => \%labels });
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
        $self->spec_push('ingress', {
            fromCIDR => $cidrs,
            $opts{ports} ? (toPorts => [ { ports => $opts{ports} } ]) : (),
        });
    }
    return $self;
}


sub allow_ingress_from_namespace {
    my ($self, $namespace, %opts) = @_;
    my $format = $self->_netpol_format;

    if ($format eq 'core') {
        $self->_add_core_ingress_rule(
            { namespaceSelector => { matchLabels => { $CORE_NAMESPACE_LABEL => $namespace } } },
            $opts{ports},
        );
    } elsif ($format eq 'cilium') {
        $self->spec_push('ingress', {
            fromEndpoints => [ { matchLabels => { $CILIUM_NAMESPACE_LABEL => $namespace } } ],
            $opts{ports} ? (toPorts => [ { ports => $opts{ports} } ]) : (),
        });
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
        $self->spec_push('egress', {
            toEndpoints => [ { matchLabels => $labels } ],
            $opts{ports} ? (toPorts => [ { ports => $opts{ports} } ]) : (),
        });
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
        $self->spec_push('egress', { toCIDR => $cidrs });
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
        # Both selectors in ONE peer: within a single `to` element
        # namespaceSelector and podSelector intersect, while two elements
        # would union and reach every pod in kube-system plus every
        # k8s-app=kube-dns pod anywhere.
        $self->_add_core_egress_rule({
            namespaceSelector => { matchLabels => { $CORE_NAMESPACE_LABEL => $DNS_TARGET{namespace} } },
            podSelector       => { matchLabels => { %{ $DNS_TARGET{pod_labels} } } },
        }, $dns_ports);
    } elsif ($format eq 'cilium') {
        # Cilium matches a single endpoint set, so the same two facts are
        # one matchLabels hash in its k8s: vocabulary.
        $self->spec_push('egress', {
            toEndpoints => [ { matchLabels => {
                $CILIUM_NAMESPACE_LABEL => $DNS_TARGET{namespace},
                map { ('k8s:'.$_ => $DNS_TARGET{pod_labels}{$_}) }
                    keys %{ $DNS_TARGET{pod_labels} },
            } } ],
            toPorts     => [ { ports => $dns_ports } ],
        });
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
        $self->spec_set('ingress',     []);
        $self->spec_set('ingressDeny', [ {} ]);
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
        $self->spec_set('egress',     []);
        $self->spec_set('egressDeny', [ {} ]);
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
#
# Every core-format path reaches this first -- select_pods, deny_all_ingress,
# deny_all_egress call it directly, and so does each of the four
# _add_core_*_rule helpers -- which makes it the one place to load the core
# networking.k8s.io/v1 classes the branch names below. A role cannot `use`
# them at the top: composing this role would then drag the whole core
# NetworkPolicy family into IO::K8s::Cilium::V2::CiliumNetworkPolicy, which
# never runs this branch. Loaded when the branch first runs instead, the way
# IO::K8s::Role::APIObject loads ObjectMeta and OwnerReference.
#
# Until k117 only NetworkPolicySpec was required, and only inside the
# vivify block -- so select_pods on a freshly loaded
# IO::K8s::Api::Networking::V1::NetworkPolicy died with 'Can't locate object
# method "new" via package ...Meta::V1::LabelSelector', and every rule
# builder died the same way on NetworkPolicyPeer. It only ever worked in a
# process that had loaded those classes for some other reason.
sub _ensure_spec {
    my ($self) = @_;
    return unless $self->_netpol_format eq 'core';

    require IO::K8s::Api::Networking::V1::NetworkPolicySpec;
    require IO::K8s::Api::Networking::V1::NetworkPolicyEgressRule;
    require IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule;
    require IO::K8s::Api::Networking::V1::NetworkPolicyPeer;
    require IO::K8s::Api::Networking::V1::NetworkPolicyPort;
    require IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector;

    return if $self->spec;
    $self->spec(IO::K8s::Api::Networking::V1::NetworkPolicySpec->new(
        podSelector => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector->new,
    ));
    return;
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
    $self->spec_push('ingress', {
        fromEndpoints => [ $endpoint_selector ],
        $ports ? (toPorts => [ { ports => $ports } ]) : (),
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::NetworkPolicy - Role for building network policies (core K8s and Cilium)

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    package My::NetPol;
    use IO::K8s::APIObject api_version => 'networking.k8s.io/v1';
    with 'IO::K8s::Role::NetworkPolicy';

    sub _netpol_format { 'core' }   # or 'cilium'

    package main;
    my $p = My::NetPol->new;
    $p->select_pods(app => 'web')
      ->allow_ingress_from_pods({ app => 'nginx' }, ports => [{ port => 8080 }])
      ->allow_egress_to_dns
      ->deny_all_egress;

=head1 DESCRIPTION

This role provides the fluent network-policy builders documented in the
README's "Network policies" section. The same chain works against both
core Kubernetes C<NetworkPolicy> and Cilium C<CiliumNetworkPolicy> CRDs;
the role dispatches on a C<_netpol_format> method the consumer must
implement, returning either C<'core'> or C<'cilium'>.

Core K8s operations build typed L<IO::K8s::Api::Networking::V1::NetworkPolicySpec>
objects (with the canonical C<from>/C<to>/C<ports> shape and the
C<policyTypes> field maintained automatically); Cilium operations write
their rules (C<fromEndpoints>/C<toEndpoints>/C<fromCIDR>/C<toCIDR>) through
L<IO::K8s::Role::SpecBuilder>, so a plain-hash Cilium C<spec> gets plain
hashrefs and a modeled one gets its declared rule class either way. The two
paths live in the same role because most consumers either commit fully to
core K8s or fully to Cilium and do not switch mid-flow.

CIDR-accepting methods (C<allow_ingress_from_cidrs>, C<allow_egress_to_cidrs>)
validate each input through L<IO::K8s::Types::Net/IPAddress> semantics and
croak on a malformed value rather than letting the cluster reject the
manifest after the fact.

=head2 select_pods

    $netpol->select_pods(app => 'web', tier => 'frontend');

Sets the policy's podSelector to match pods carrying the given labels. For
core Kubernetes C<NetworkPolicy> this writes C<spec.podSelector.matchLabels>;
for Cilium C<CiliumNetworkPolicy> it writes the
C<spec.endpointSelector.matchLabels> shape. The two formats produce the
same selector semantics; the role picks the right shape based on the
consuming class's C<_netpol_format>. Returns C<$self> for chaining.

=head2 allow_ingress_from_pods

    $netpol->allow_ingress_from_pods({ app => 'nginx' }, ports => [{ port => 8080 }]);

Adds an ingress rule allowing traffic from pods matching the given labels.
C<$labels> is a hashref (the C<matchLabels> payload); C<ports> is an
optional arrayref of C<< { port =E<gt> $n, protocol =E<gt> 'TCP' } >>
entries. Core K8s writes C<spec.ingress[].from[].podSelector>; Cilium
writes C<spec.ingress[].fromEndpoints[].matchLabels>. Returns C<$self> for
chaining.

=head2 allow_ingress_from_cidrs

    $netpol->allow_ingress_from_cidrs(['10.0.0.0/8', '192.168.0.0/16'], ports => [...]);

Adds an ingress rule allowing traffic from the given CIDR ranges. Each CIDR
is validated as having a C</> and being parseable by L<Net::IP>; croaks
otherwise. C<ports> is an optional arrayref of C<< { port =E<gt> $n,
protocol =E<gt> 'TCP' } >> entries. Core K8s writes
C<spec.ingress[].from[].ipBlock.cidr>; Cilium writes
C<spec.ingress[].fromCIDR>. Returns C<$self> for chaining.

=head2 allow_ingress_from_namespace

    $netpol->allow_ingress_from_namespace('kube-system', ports => [...]);

Adds an ingress rule allowing traffic from any pod in the named namespace.
Internally selects on the well-known
C<kubernetes.io/metadata.name =E<gt> $namespace> label (or its Cilium
equivalent C<k8s:io.kubernetes.pod.namespace>). C<ports> is optional.
Returns C<$self> for chaining.

=head2 allow_egress_to_pods

    $netpol->allow_egress_to_pods({ app => 'redis' }, ports => [{ port => 6379 }]);

Adds an egress rule allowing traffic to pods matching the given labels.
C<$labels> is a hashref of C<matchLabels>; C<ports> is an optional
arrayref of port spec entries. Core K8s writes C<spec.egress[].to[]>; Cilium
writes C<spec.egress[].toEndpoints[]>. Returns C<$self> for chaining.

=head2 allow_egress_to_cidrs

    $netpol->allow_egress_to_cidrs(['0.0.0.0/0']);

Adds an egress rule allowing traffic to the given CIDR ranges (most often
C<['0.0.0.0/0']> for "all external traffic"). Each CIDR is validated as
having a C</> and being parseable by L<Net::IP>; croaks otherwise. Core
K8s writes C<spec.egress[].to[].ipBlock.cidr>; Cilium writes
C<spec.egress[].toCIDR>. Returns C<$self> for chaining.

=head2 allow_egress_to_dns

    $netpol->allow_egress_to_dns;

Adds an egress rule that allows DNS lookups: TCP and UDP port 53 to the
cluster's CoreDNS pods -- the ones in C<kube-system> carrying
C<k8s-app: kube-dns>. This is the common "let pods resolve names"
companion to a restrictive egress policy. Returns C<$self> for chaining.

Core Kubernetes writes both selectors into a single C<to> peer, so they
intersect rather than union -- the rule reaches pods that are in
C<kube-system> B<and> carry the label, not either:

    egress:
    - to:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kube-system
        podSelector:
          matchLabels:
            k8s-app: kube-dns
      ports:
      - { port: 53, protocol: UDP }
      - { port: 53, protocol: TCP }

Cilium writes the same two facts as one C<toEndpoints> match in its own
label vocabulary (C<k8s:io.kubernetes.pod.namespace>, C<k8s:k8s-app>).

B<Changed in 1.108> (k117): the core branch used to emit the ports without
any C<to> peer, which allows port 53 to B<every> destination -- a policy
looser than this documentation described, and one that silently opened
egress on port 53 to anything a pod could reach. Manifests regenerated
with this version carry the narrower rule. A cluster that relied on the
old, wider rule for something other than DNS needs that traffic allowed
explicitly.

=head2 deny_all_ingress

    $netpol->deny_all_ingress;

Replaces the policy's ingress rules with an empty list, the canonical
"deny all ingress" shape. Core K8s sets C<spec.ingress = []>; Cilium sets
C<spec.ingress = []> and additionally writes a wildcard
C<spec.ingressDeny = [{}]> for consistency with Cilium's deny-first
semantics. Returns C<$self> for chaining.

=head2 deny_all_egress

    $netpol->deny_all_egress;

Replaces the policy's egress rules with an empty list, the canonical
"deny all egress" shape. Core K8s sets C<spec.egress = []>; Cilium sets
C<spec.egress = []> and additionally writes a wildcard
C<spec.egressDeny = [{}]>. Returns C<$self> for chaining.

=head1 REQUIRED METHODS

=head2 _netpol_format

Must return C<'core'> or C<'cilium'>. The role dispatches all method bodies
on this answer; a missing or unknown value is treated as a no-op.

=head1 SEE ALSO

L<IO::K8s::Cilium>, L<IO::K8s::Types::Net>,
L<IO::K8s::Api::Networking::V1::NetworkPolicySpec>, L<IO::K8s::APIObject>

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
