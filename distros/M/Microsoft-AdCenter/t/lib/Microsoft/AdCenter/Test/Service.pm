package Microsoft::AdCenter::Test::Service;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::Test::DummyService;
use Microsoft::AdCenter::Test::DummyService::ComplexType1;
use Microsoft::AdCenter::Test::DummyService::RequestHeader;

sub test_service_get_namespace_prefix : Test(5) {
    my $dummy_service = Microsoft::AdCenter::Test::DummyService->new;
    my $check = sub {
        my ($uri, $prefix) = @_;
        is($dummy_service->_get_namespace_prefix($uri), $prefix, "can get prefix for '$uri'");
    };
    $check->("https://default.namespace.uri/default", "default");
    $check->("https://a.namespace.uri", "ns1");
    $check->("https://another.namespace.uri", "ns2");
    $check->("https://a.namespace.uri", "ns1");
    $check->("https://another.namespace.uri", "ns2");
}

sub test_service_type_category : Test(5) {
    my $dummy_service = Microsoft::AdCenter::Test::DummyService->new;
    my $check = sub {
        my ($type, $category) = @_;
        is($dummy_service->_type_category($type), $category, "can get category for type '$type'");
    };
    $check->("ComplexType1", "COMPLEX");
    $check->("ComplexType2", "COMPLEX");
    $check->("ArrayOfComplexType1", "ARRAY");
    $check->("SimpleType1", "SIMPLE");
    $check->("string", "PRIMITIVE");
}

sub test_service_type_namespace : Test(5) {
    my $dummy_service = Microsoft::AdCenter::Test::DummyService->new;
    my $check = sub {
        my ($type, $namespace) = @_;
        is($dummy_service->_type_namespace($type), $namespace, "can get namespace for type '$type'");
    };
    $check->("ComplexType1", "https://default.namespace.uri/default");
    $check->("ComplexType2", "https://a.namespace.uri");
    $check->("ArrayOfComplexType1", "https://a.namespace.uri");
    $check->("SimpleType1", "https://default.namespace.uri/default");
    $check->("SimpleType2", "https://a.namespace.uri");
}

sub test_service_type_full_name : Test(6) {
    my $dummy_service = Microsoft::AdCenter::Test::DummyService->new;
    my $check = sub {
        my ($type, $full_name) = @_;
        is($dummy_service->_type_full_name($type), $full_name, "can get full name for type '$type'");
    };
    $check->("ComplexType1", "default:ComplexType1");
    $check->("ComplexType2", "ns1:ComplexType2");
    $check->("ArrayOfComplexType1", "ns1:ArrayOfComplexType1");
    $check->("SimpleType1", "default:SimpleType1");
    $check->("SimpleType2", "ns1:SimpleType2");
    $check->("string", "string");
}

sub test_service_create_complex_type : Test(2) {
    my $dummy_service = Microsoft::AdCenter::Test::DummyService->new;
    my $check = sub {
        my ($type) = @_;
        is($dummy_service->_create_complex_type($type)->_type_name, $type, "can create type '$type'");
    };
    $check->("ComplexType1");
    $check->("ComplexType2");
}

sub test_service_populate_complex_type : Test(3) {
    my $dummy_service = Microsoft::AdCenter::Test::DummyService->new
        ->RequestHeaderA('request header a')
        ->Attribute1('attribute 1')
        ->Attribute2('attribute 2');

    my $result = $dummy_service->_populate_complex_type("RequestHeader");

    is($result->RequestHeaderA, 'request header a', "can populate RequestHeaderA");
    is($result->RequestHeaderB->Attribute1, 'attribute 1', "can populate RequestHeaderB->Attribute1");
    is($result->RequestHeaderB->Attribute2, 'attribute 2', "can populate RequestHeaderB->Attribute2");
}

sub test_service_expand_complex_type : Test(3) {
    my $dummy_service = Microsoft::AdCenter::Test::DummyService->new;

    my $object = Microsoft::AdCenter::Test::DummyService::RequestHeader->new
        ->RequestHeaderA('request header a')
        ->RequestHeaderB(
            Microsoft::AdCenter::Test::DummyService::ComplexType1->new
                ->Attribute1('attribute 1')
                ->Attribute2('attribute 2')
        );

    my $result = {};
    $dummy_service->_expand_complex_type($object, $result);
    is($result->{RequestHeaderA}, 'request header a', "can expand RequestHeaderA");
    is($result->{Attribute1}, 'attribute 1', "can expand RequestHeaderB->Attribute1");
    is($result->{Attribute2}, 'attribute 2', "can expand RequestHeaderB->Attribute2");
}

1;
