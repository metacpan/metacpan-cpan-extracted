#!/usr/bin/env perl
# k127: defaults represented as Bool in the registry must reach a CRD's wire
# JSON as true/false, while Int defaults retain their numeric representation.
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use IO::K8s::CRD;
use IO::K8s::Cilium::V2::CiliumBGPPeer;
use IO::K8s::Cilium::V2::CiliumBGPPeerConfigSpec;
use IO::K8s::ExternalSecrets::V1::BeyondtrustServer;
use IO::K8s::ExternalSecrets::V1alpha1::Password;

my $json = JSON::MaybeXS->new(utf8 => 0, canonical => 1);

sub spec_schema {
  my ($class) = @_;
  return $class->to_crd->TO_JSON
    ->{spec}{versions}[0]{schema}{openAPIV3Schema}{properties}{spec};
}

subtest 'Boolean defaults are JSON booleans; numeric zero and one stay numeric' => sub {
  my %wire = (
    false => spec_schema('IO::K8s::ExternalSecrets::V1alpha1::Password')
      ->{properties}{allowRepeat},
    true => IO::K8s::CRD::_schema_for_class('IO::K8s::ExternalSecrets::V1::BeyondtrustServer')
      ->{properties}{decrypt},
    zero => IO::K8s::CRD::_schema_for_class('IO::K8s::Cilium::V2::CiliumBGPPeer')
      ->{properties}{peerASN},
    one => IO::K8s::CRD::_schema_for_class('IO::K8s::Cilium::V2::CiliumBGPPeerConfigSpec')
      ->{properties}{ebgpMultihop},
  );

  is($json->encode($wire{false}), '{"default":false,"type":"boolean"}',
    'a concrete false Bool default arrives on the CRD wire as JSON false, not numeric zero');
  is($json->encode($wire{true}), '{"default":true,"type":"boolean"}',
    'a concrete true Bool default arrives on the CRD wire as JSON true, not numeric one');
  is($json->encode($wire{zero}), '{"default":0,"maximum":4294967295,"minimum":0,"type":"integer"}',
    'a numeric zero default remains JSON number zero');
  is($json->encode($wire{one}), '{"default":1,"maximum":255,"minimum":1,"type":"integer"}',
    'a numeric one default remains JSON number one');
};

done_testing;
