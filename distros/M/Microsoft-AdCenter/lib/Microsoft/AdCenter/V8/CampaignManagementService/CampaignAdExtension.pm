package Microsoft::AdCenter::V8::CampaignManagementService::CampaignAdExtension;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::CampaignAdExtension - Represents "CampaignAdExtension" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'CampaignAdExtension';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    AdExtension
    CampaignId
    EditorialStatus
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AdExtension => 'AdExtension2',
    CampaignId => 'long',
    EditorialStatus => 'CampaignAdExtensionEditorialStatus',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AdExtension => 1,
    CampaignId => 1,
    EditorialStatus => 0,
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

=head2 AdExtension

Gets/sets AdExtension (AdExtension2)

=head2 CampaignId

Gets/sets CampaignId (long)

=head2 EditorialStatus

Gets/sets EditorialStatus (CampaignAdExtensionEditorialStatus)

=cut

