#!/usr/bin/env perl

use strict;
use warnings;
use Kubernetes::REST;
use IO::K8s::Api::Core::V1::Namespace;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;

my $k = Kubernetes::REST->new(
   credentials => { token => '' },
   server  => {
     endpoint => 'https://192.168.99.100:8443',
     ssl_verify_server => 1,
     ssl_cert_file => "$ENV{HOME}/.minikube/client.crt",
     ssl_key_file => "$ENV{HOME}/.minikube/client.key",
     ssl_ca_file => "$ENV{HOME}/.minikube/ca.crt",
   },
);

my $r = $k->Core->ListNamespace;
use Data::Dumper;
print Dumper($r);

foreach my $i (1..100) {
  $k->Core->CreateNamespace(
    body => IO::K8s->object_to_struct(
      IO::K8s->struct_to_object(
        'IO::K8s::Api::Core::V1::Namespace', {
          apiVersion => 'v1',
          kind => 'Namespace',
          metadata => {
            name => "ns2-$i",
          },
        }
      )
    )
  );
}
