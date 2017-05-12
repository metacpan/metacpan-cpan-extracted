package Microsoft::AdCenter::V8::CampaignManagementService::MobileAd;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::V8::CampaignManagementService::Ad/;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::MobileAd - Represents "MobileAd" in Microsoft AdCenter Campaign Management Service.

=head1 INHERITANCE

Microsoft::AdCenter::V8::CampaignManagementService::Ad

=cut

sub _type_name {
    return 'MobileAd';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    BusinessName
    DestinationUrl
    DisplayUrl
    PhoneNumber
    Text
    Title
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    BusinessName => 'string',
    DestinationUrl => 'string',
    DisplayUrl => 'string',
    PhoneNumber => 'string',
    Text => 'string',
    Title => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    BusinessName => 0,
    DestinationUrl => 0,
    DisplayUrl => 0,
    PhoneNumber => 0,
    Text => 0,
    Title => 1,
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

Remark: Inherited methods are not listed.

=head2 new

Creates a new instance

=head2 BusinessName

Gets/sets BusinessName (string)

=head2 DestinationUrl

Gets/sets DestinationUrl (string)

=head2 DisplayUrl

Gets/sets DisplayUrl (string)

=head2 PhoneNumber

Gets/sets PhoneNumber (string)

=head2 Text

Gets/sets Text (string)

=head2 Title

Gets/sets Title (string)

=cut

