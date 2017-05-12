package Microsoft::AdCenter::V8::CampaignManagementService::Goal;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::Goal - Represents "Goal" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'Goal';
}

sub _namespace_uri {
    return 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts';
}

our @_attributes = (qw/
    CostModel
    DaysApplicableForConversion
    Id
    Name
    RevenueModel
    Steps
    YEventId
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    CostModel => 'CostModel',
    DaysApplicableForConversion => 'DaysApplicableForConversion',
    Id => 'long',
    Name => 'string',
    RevenueModel => 'RevenueModel',
    Steps => 'ArrayOfStep',
    YEventId => 'int',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    CostModel => 0,
    DaysApplicableForConversion => 0,
    Id => 0,
    Name => 0,
    RevenueModel => 0,
    Steps => 0,
    YEventId => 0,
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

=head2 CostModel

Gets/sets CostModel (CostModel)

=head2 DaysApplicableForConversion

Gets/sets DaysApplicableForConversion (DaysApplicableForConversion)

=head2 Id

Gets/sets Id (long)

=head2 Name

Gets/sets Name (string)

=head2 RevenueModel

Gets/sets RevenueModel (RevenueModel)

=head2 Steps

Gets/sets Steps (ArrayOfStep)

=head2 YEventId

Gets/sets YEventId (int)

=cut

