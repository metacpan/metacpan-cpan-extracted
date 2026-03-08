#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

# Test _build_path functionality
{
    my $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://example.com'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'FakeToken'),
        resource_map_from_cluster => 0,  # Use IO::K8s defaults for testing
    );

    # Test expand_class with short names
    is($api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod', 'Pod expands correctly');
    is($api->expand_class('Deployment'), 'IO::K8s::Api::Apps::V1::Deployment', 'Deployment expands correctly');
    is($api->expand_class('Node'), 'IO::K8s::Api::Core::V1::Node', 'Node expands correctly');

    # Test with relative path
    is($api->expand_class('Api::Core::V1::Pod'), 'IO::K8s::Api::Core::V1::Pod', 'Relative path expands');

    # Test extension API via resource_map
    is($api->expand_class('CustomResourceDefinition'),
       'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
       'CustomResourceDefinition expands to full path');
}

# Test resource_map customization
{
    my $custom_map = {
        Pod => 'Api::Core::V1::Pod',
        MyCustomResource => 'Api::Custom::V1::MyCustomResource',
    };

    my $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://example.com'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'FakeToken'),
        resource_map => $custom_map,
    );

    is($api->expand_class('MyCustomResource'), 'IO::K8s::Api::Custom::V1::MyCustomResource', 'Custom resource map works');
}

# Test _build_path pluralization rules
{
    my $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://example.com'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'FakeToken'),
        resource_map_from_cluster => 0,
    );

    # Simple +s: pod -> pods
    my $path = $api->_build_path('IO::K8s::Api::Core::V1::Pod');
    like($path, qr{/pods$}, 'Pod -> pods (simple +s)');

    # Simple +s: node -> nodes
    $path = $api->_build_path('IO::K8s::Api::Core::V1::Node');
    like($path, qr{/nodes$}, 'Node -> nodes (simple +s)');

    # Already ends in s (Namespace -> namespaces... but Namespace ends in 'e', +s)
    $path = $api->_build_path('IO::K8s::Api::Core::V1::Namespace');
    like($path, qr{/namespaces$}, 'Namespace -> namespaces (ends in e, +s)');

    # ss/sh/ch/x/z -> +es: Ingress -> ingresses
    $path = $api->_build_path('IO::K8s::Api::Networking::V1::Ingress');
    like($path, qr{/ingresses$}, 'Ingress -> ingresses (ss ending -> +es)');

    # consonant+y -> ies: NetworkPolicy -> networkpolicies
    $path = $api->_build_path('IO::K8s::Api::Networking::V1::NetworkPolicy');
    like($path, qr{/networkpolicies$}, 'NetworkPolicy -> networkpolicies (consonant+y -> ies)');

    # ConfigMap -> configmaps (simple +s)
    $path = $api->_build_path('IO::K8s::Api::Core::V1::ConfigMap');
    like($path, qr{/configmaps$}, 'ConfigMap -> configmaps (simple +s)');
}

done_testing;
