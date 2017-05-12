package Microsoft::AdCenter::V7::CampaignManagementService::SegmentTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V7::CampaignManagementService::SegmentTargetBid - Represents "SegmentTargetBid" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'SegmentTargetBid';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v7';
}

our @_attributes = (qw/
    CashBackInfo
    IncrementalBid
    Param1
    Param2
    Param3
    SegmentId
    SegmentParam1
    SegmentParam2
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    CashBackInfo => 'CashBackInfo',
    IncrementalBid => 'IncrementalBidPercentage',
    Param1 => 'string',
    Param2 => 'string',
    Param3 => 'string',
    SegmentId => 'long',
    SegmentParam1 => 'string',
    SegmentParam2 => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    CashBackInfo => 0,
    IncrementalBid => 1,
    Param1 => 0,
    Param2 => 0,
    Param3 => 0,
    SegmentId => 1,
    SegmentParam1 => 0,
    SegmentParam2 => 0,
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

=head2 CashBackInfo

Gets/sets CashBackInfo (CashBackInfo)

=head2 IncrementalBid

Gets/sets IncrementalBid (IncrementalBidPercentage)

=head2 Param1

Gets/sets Param1 (string)

=head2 Param2

Gets/sets Param2 (string)

=head2 Param3

Gets/sets Param3 (string)

=head2 SegmentId

Gets/sets SegmentId (long)

=head2 SegmentParam1

Gets/sets SegmentParam1 (string)

=head2 SegmentParam2

Gets/sets SegmentParam2 (string)

=cut

