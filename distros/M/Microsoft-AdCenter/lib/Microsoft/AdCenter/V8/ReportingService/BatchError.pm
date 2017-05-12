package Microsoft::AdCenter::V8::ReportingService::BatchError;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::ReportingService::BatchError - Represents "BatchError" in Microsoft AdCenter Reporting Service.

=cut

sub _type_name {
    return 'BatchError';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    Code
    Details
    ErrorCode
    Index
    Message
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Code => 'int',
    Details => 'string',
    ErrorCode => 'string',
    Index => 'int',
    Message => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Code => 0,
    Details => 0,
    ErrorCode => 0,
    Index => 0,
    Message => 0,
);

sub _attribute_min_occurs {
    my ($self, $attribute) = @_;
    if (exists $_attribute_min_occurs{$attribute}) {
        return $_attribute_min_occurs{$attribute};
    }
    return $self->SUPER::_attribute_min_occurs($attribute);
}

__PACKAGE__->mk_accessors(@_attributes);

1;

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=cut

=head1 METHODS

=head2 new

Creates a new instance

=head2 Code

Gets/sets Code (int)

=head2 Details

Gets/sets Details (string)

=head2 ErrorCode

Gets/sets ErrorCode (string)

=head2 Index

Gets/sets Index (int)

=head2 Message

Gets/sets Message (string)

=cut

