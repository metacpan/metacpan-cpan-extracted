#!/usr/bin/env perl
# k187 (k185 follow-up): Cilium's toPorts.ports item is
# {endPort: integer, port: string, protocol: string} -- port is a plain
# type: string. The shipped Cilium PortRule/PortDenyRule used to reuse
# Networking::V1::NetworkPolicyPort, whose port is IntOrStr, so a Cilium
# port "80" went out as the JSON number 80, which the Cilium CRD (port:
# string) rejects. That reuse only ever matched via the too-broad
# string->is_int_or_string rule k185 removed; the k187 re-render points
# ports at a dedicated Str-port class (Cilium::V2::PortProtocol).
#
# Claims:
#   * PortRule and PortDenyRule type their ports as PortProtocol, not
#     NetworkPolicyPort, and PortProtocol's port is a Str;
#   * a Cilium port "80" round-trips as the JSON string "80", not 80,
#     through a plain PortRule and through a full CiliumNetworkPolicy.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;

use IO::K8s;
use IO::K8s::Cilium::V2::PortRule;
use IO::K8s::Cilium::V2::PortDenyRule;
use IO::K8s::Cilium::V2::PortProtocol;

subtest 'ports is a Str-port PortProtocol, not the IntOrStr NetworkPolicyPort' => sub {
    for my $rule (qw( PortRule PortDenyRule )) {
        my $class = "IO::K8s::Cilium::V2::$rule";
        is($class->_k8s_attr_info->{ports}{class}, 'IO::K8s::Cilium::V2::PortProtocol',
            "$rule.ports is PortProtocol");
    }
    ok(IO::K8s::Cilium::V2::PortProtocol->_k8s_attr_info->{port}{is_str},
        'PortProtocol.port is a Str');
};

subtest 'a Cilium port "80" stays the JSON string "80"' => sub {
    my $pr = IO::K8s::Cilium::V2::PortRule->new(ports => [{ port => '80', protocol => 'TCP' }]);
    is($pr->to_json, '{"ports":[{"port":"80","protocol":"TCP"}]}',
        'PortRule: port "80" serializes as the string "80", not the number 80');

    my $pdr = IO::K8s::Cilium::V2::PortDenyRule->new(ports => [{ port => '80', protocol => 'TCP' }]);
    is($pdr->to_json, '{"ports":[{"port":"80","protocol":"TCP"}]}',
        'PortDenyRule: port "80" serializes as the string "80"');
};

subtest 'the string port survives a full CiliumNetworkPolicy round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);
    my $doc = '{"apiVersion":"cilium.io/v2","kind":"CiliumNetworkPolicy",'
        . '"metadata":{"name":"p"},"spec":{"endpointSelector":{},'
        . '"egress":[{"toPorts":[{"ports":[{"port":"80","protocol":"TCP"}]}]}]}}';
    my $obj = $k8s->inflate($doc);
    my $json = $obj->to_json;
    like($json, qr/"port":"80"/, 'toPorts port round-trips as the string "80"');
    unlike($json, qr/"port":80\b/, 'and never as the bare number 80');
};

done_testing;
