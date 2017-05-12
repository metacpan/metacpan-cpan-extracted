package Microsoft::AdCenter::Test::DummyService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::Service/;

sub _service_name {
    return 'DummyService';
}

sub _class_name {
    return 'DummyService';
}

sub _namespace_uri {
    return 'https://default.namespace.uri/default';
}

sub _default_location {
    return 'https://some.where.that/doesnt/exists';
}

sub _wsdl {
    return 'https://some.where.that/doesnt/exists?wsdl';
}

our $_request_headers = [
    { name => 'RequestHeader1', type => 'string', namespace => 'https://default.namespace.uri/default' },
    { name => 'RequestHeader2', type => 'string', namespace => 'https://default.namespace.uri/default' },
    { name => 'RequestHeader3', type => 'RequestHeader', namespace => 'https://default.namespace.uri/default' }
];

our $_request_headers_expanded = {
    RequestHeader1 => 'string',
    RequestHeader2 => 'string'
};

sub _request_headers {
    return $_request_headers;
}

sub _request_headers_expanded {
    return $_request_headers_expanded;
}

our $_response_headers = [
    { name => 'ResponseHeader1', type => 'string', namespace => 'https://default.namespace.uri/default' },
    { name => 'ResponseHeader2', type => 'string', namespace => 'https://default.namespace.uri/default' },
    { name => 'ResponseHeader3', type => 'ResponseHeader', namespace => 'https://default.namespace.uri/default' }
];

our $_response_headers_expanded = {
    ResponseHeader1 => 'string',
    ResponseHeader2 => 'string'
};

sub _response_headers {
    return $_response_headers;
}

sub _response_headers_expanded {
    return $_response_headers_expanded;
}

sub Operation1 {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'Operation1',
        request => {
            name => 'Operation1Request',
            parameters => [
            ]
        },
        response => {
            name => 'Operation1Response'
        },
        parameters => \%args
    );
}

sub Operation2 {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'Operation2',
        request => {
            name => 'Operation2Request',
            parameters => [
            ]
        },
        response => {
            name => 'Operation2Response'
        },
        parameters => \%args
    );
}

our %_simple_types = (
    SimpleType1 => 'https://default.namespace.uri/default',
    SimpleType2 => 'https://a.namespace.uri'
);

sub _simple_types {
    return %_simple_types;
}

our @_complex_types = (qw/
    ComplexType1
    ComplexType2
    Operation1Response
    Operation2Response
    RequestHeader
    ResponseHeader
/);

sub _complex_types {
    return @_complex_types;
}

our %_array_types = (
    ArrayOfComplexType1 => {
        namespace_uri => 'https://a.namespace.uri',
        element_name => 'ComplexType1',
        element_type => 'ComplexType1'
    },
);

sub _array_types {
    return %_array_types;
}

__PACKAGE__->mk_accessors(qw/
    EndPoint
    RequestHeader1
    RequestHeader2
    RequestHeaderA
    Attribute1
    Attribute2
    ResponseHeader1
    ResponseHeader2
    ResponseHeaderA
    ResponseHeaderB
/);

1;
