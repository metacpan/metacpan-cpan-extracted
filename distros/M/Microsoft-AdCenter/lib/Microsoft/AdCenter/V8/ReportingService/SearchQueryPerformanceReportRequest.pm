package Microsoft::AdCenter::V8::ReportingService::SearchQueryPerformanceReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::V8::ReportingService::ReportRequest/;

=head1 NAME

Microsoft::AdCenter::V8::ReportingService::SearchQueryPerformanceReportRequest - Represents "SearchQueryPerformanceReportRequest" in Microsoft AdCenter Reporting Service.

=head1 INHERITANCE

Microsoft::AdCenter::V8::ReportingService::ReportRequest

=cut

sub _type_name {
    return 'SearchQueryPerformanceReportRequest';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    Aggregation
    Columns
    Filter
    Scope
    Time
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Aggregation => 'SearchQueryReportAggregation',
    Columns => 'ArrayOfSearchQueryPerformanceReportColumn',
    Filter => 'SearchQueryPerformanceReportFilter',
    Scope => 'AccountThroughAdGroupReportScope',
    Time => 'ReportTime',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Aggregation => 1,
    Columns => 1,
    Filter => 0,
    Scope => 1,
    Time => 1,
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

=head2 Aggregation

Gets/sets Aggregation (SearchQueryReportAggregation)

=head2 Columns

Gets/sets Columns (ArrayOfSearchQueryPerformanceReportColumn)

=head2 Filter

Gets/sets Filter (SearchQueryPerformanceReportFilter)

=head2 Scope

Gets/sets Scope (AccountThroughAdGroupReportScope)

=head2 Time

Gets/sets Time (ReportTime)

=cut

