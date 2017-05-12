package Microsoft::AdCenter::V7::CampaignManagementService::KeywordEstimate;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V7::CampaignManagementService::KeywordEstimate - Represents "KeywordEstimate" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'KeywordEstimate';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v7';
}

our @_attributes = (qw/
    AverageMonthlyCost
    AverageMonthlyPosition
    BroadKeywordEstimate
    EstimatedTotalMonthlyImpressions
    ExactKeywordEstimate
    PhraseKeywordEstimate
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AverageMonthlyCost => 'double',
    AverageMonthlyPosition => 'int',
    BroadKeywordEstimate => 'MatchTypeEstimate',
    EstimatedTotalMonthlyImpressions => 'int',
    ExactKeywordEstimate => 'MatchTypeEstimate',
    PhraseKeywordEstimate => 'MatchTypeEstimate',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AverageMonthlyCost => 0,
    AverageMonthlyPosition => 0,
    BroadKeywordEstimate => 0,
    EstimatedTotalMonthlyImpressions => 0,
    ExactKeywordEstimate => 0,
    PhraseKeywordEstimate => 0,
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

=head2 AverageMonthlyCost

Gets/sets AverageMonthlyCost (double)

=head2 AverageMonthlyPosition

Gets/sets AverageMonthlyPosition (int)

=head2 BroadKeywordEstimate

Gets/sets BroadKeywordEstimate (MatchTypeEstimate)

=head2 EstimatedTotalMonthlyImpressions

Gets/sets EstimatedTotalMonthlyImpressions (int)

=head2 ExactKeywordEstimate

Gets/sets ExactKeywordEstimate (MatchTypeEstimate)

=head2 PhraseKeywordEstimate

Gets/sets PhraseKeywordEstimate (MatchTypeEstimate)

=cut

