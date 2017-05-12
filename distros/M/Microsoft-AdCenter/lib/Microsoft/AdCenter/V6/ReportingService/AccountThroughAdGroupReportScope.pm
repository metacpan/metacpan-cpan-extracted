package Microsoft::AdCenter::V6::ReportingService::AccountThroughAdGroupReportScope;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V6::ReportingService::AccountThroughAdGroupReportScope - Represents "AccountThroughAdGroupReportScope" in Microsoft AdCenter Reporting Service.

=cut

sub _type_name {
    return 'AccountThroughAdGroupReportScope';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v6';
}

our @_attributes = (qw/
    AccountIds
    AdGroups
    Campaigns
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AccountIds => 'ArrayOfint',
    AdGroups => 'ArrayOfAdGroupReportScope',
    Campaigns => 'ArrayOfCampaignReportScope',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AccountIds => 0,
    AdGroups => 0,
    Campaigns => 0,
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

=head2 AccountIds

Gets/sets AccountIds (ArrayOfint)

=head2 AdGroups

Gets/sets AdGroups (ArrayOfAdGroupReportScope)

=head2 Campaigns

Gets/sets Campaigns (ArrayOfCampaignReportScope)

=cut

