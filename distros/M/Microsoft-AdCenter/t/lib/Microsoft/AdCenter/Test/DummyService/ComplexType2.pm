package Microsoft::AdCenter::Test::DummyService::ComplexType2;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::Test::DummyService::ComplexType1/;

sub _type_name {
    return 'ComplexType2';
}

sub _namespace_uri {
    return 'https://a.namespace.uri';
}

our @_attributes = (qw/
    Attribute3
    Attribute4
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Attribute3 => 'string',
    Attribute4 => 'string'
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

__PACKAGE__->mk_accessors(__PACKAGE__->_attributes);

1;
