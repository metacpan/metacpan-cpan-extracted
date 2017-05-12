package Microsoft::AdCenter::V8::CampaignManagementService::RadiusTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::RadiusTargetBid - Represents "RadiusTargetBid" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'RadiusTargetBid';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    Id
    IncrementalBid
    LatitudeDegrees
    LongitudeDegrees
    Name
    Radius
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Id => 'long',
    IncrementalBid => 'IncrementalBidPercentage',
    LatitudeDegrees => 'double',
    LongitudeDegrees => 'double',
    Name => 'string',
    Radius => 'int',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Id => 0,
    IncrementalBid => 1,
    LatitudeDegrees => 1,
    LongitudeDegrees => 1,
    Name => 0,
    Radius => 1,
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

=head2 Id

Gets/sets Id (long)

=head2 IncrementalBid

Gets/sets IncrementalBid (IncrementalBidPercentage)

=head2 LatitudeDegrees

Gets/sets LatitudeDegrees (double)

=head2 LongitudeDegrees

Gets/sets LongitudeDegrees (double)

=head2 Name

Gets/sets Name (string)

=head2 Radius

Gets/sets Radius (int)

=cut

