package Microsoft::AdCenter::V7::CampaignManagementService::GoalError;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V7::CampaignManagementService::GoalError - Represents "GoalError" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'GoalError';
}

sub _namespace_uri {
    return 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts';
}

our @_attributes = (qw/
    BatchErrors
    Index
    StepErrors
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    BatchErrors => 'ArrayOfBatchError',
    Index => 'int',
    StepErrors => 'ArrayOfBatchError',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    BatchErrors => 0,
    Index => 0,
    StepErrors => 0,
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

=head2 BatchErrors

Gets/sets BatchErrors (ArrayOfBatchError)

=head2 Index

Gets/sets Index (int)

=head2 StepErrors

Gets/sets StepErrors (ArrayOfBatchError)

=cut

