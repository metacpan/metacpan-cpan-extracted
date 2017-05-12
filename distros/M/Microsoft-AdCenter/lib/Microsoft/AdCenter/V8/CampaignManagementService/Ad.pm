package Microsoft::AdCenter::V8::CampaignManagementService::Ad;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::Ad - Represents "Ad" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'Ad';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    EditorialStatus
    Id
    Status
    Type
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    EditorialStatus => 'AdEditorialStatus',
    Id => 'long',
    Status => 'AdStatus',
    Type => 'AdType',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    EditorialStatus => 0,
    Id => 0,
    Status => 0,
    Type => 0,
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

=head2 EditorialStatus

Gets/sets EditorialStatus (AdEditorialStatus)

=head2 Id

Gets/sets Id (long)

=head2 Status

Gets/sets Status (AdStatus)

=head2 Type

Gets/sets Type (AdType)

=cut

