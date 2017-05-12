package Microsoft::AdCenter::V7::ReportingService::SegmentationReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V7::ReportingService::SegmentationReportFilter - Represents "SegmentationReportFilter" in Microsoft AdCenter Reporting Service.

=cut

sub _type_name {
    return 'SegmentationReportFilter';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v7';
}

our @_attributes = (qw/
    AgeGroup
    Country
    Gender
    GoalIds
    Keywords
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AgeGroup => 'AgeGroupReportFilter',
    Country => 'CountryReportFilter',
    Gender => 'GenderReportFilter',
    GoalIds => 'ArrayOflong',
    Keywords => 'ArrayOfstring',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AgeGroup => 0,
    Country => 0,
    Gender => 0,
    GoalIds => 0,
    Keywords => 0,
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

=head2 AgeGroup

Gets/sets AgeGroup (AgeGroupReportFilter)

=head2 Country

Gets/sets Country (CountryReportFilter)

=head2 Gender

Gets/sets Gender (GenderReportFilter)

=head2 GoalIds

Gets/sets GoalIds (ArrayOflong)

=head2 Keywords

Gets/sets Keywords (ArrayOfstring)

=cut

