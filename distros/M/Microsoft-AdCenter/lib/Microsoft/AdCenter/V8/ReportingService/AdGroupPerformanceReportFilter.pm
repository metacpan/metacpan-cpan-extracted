package Microsoft::AdCenter::V8::ReportingService::AdGroupPerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::ReportingService::AdGroupPerformanceReportFilter - Represents "AdGroupPerformanceReportFilter" in Microsoft AdCenter Reporting Service.

=cut

sub _type_name {
    return 'AdGroupPerformanceReportFilter';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    AdDistribution
    DeviceType
    LanguageAndRegion
    LanguageCode
    Status
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AdDistribution => 'AdDistributionReportFilter',
    DeviceType => 'DeviceTypeReportFilter',
    LanguageAndRegion => 'LanguageAndRegionReportFilter',
    LanguageCode => 'ArrayOfstring',
    Status => 'AdGroupStatusReportFilter',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AdDistribution => 0,
    DeviceType => 0,
    LanguageAndRegion => 0,
    LanguageCode => 0,
    Status => 0,
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

=head2 AdDistribution

Gets/sets AdDistribution (AdDistributionReportFilter)

=head2 DeviceType

Gets/sets DeviceType (DeviceTypeReportFilter)

=head2 LanguageAndRegion

Gets/sets LanguageAndRegion (LanguageAndRegionReportFilter)

=head2 LanguageCode

Gets/sets LanguageCode (ArrayOfstring)

=head2 Status

Gets/sets Status (AdGroupStatusReportFilter)

=cut

