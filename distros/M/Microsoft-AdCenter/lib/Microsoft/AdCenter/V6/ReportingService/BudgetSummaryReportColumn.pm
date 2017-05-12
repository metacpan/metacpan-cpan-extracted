package Microsoft::AdCenter::V6::ReportingService::BudgetSummaryReportColumn;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V6::ReportingService::BudgetSummaryReportColumn - Represents "BudgetSummaryReportColumn" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    AccountName
    AccountNumber
    CampaignName
    CurrencyCode
    DailySpend
    Date
    MonthlyBudget
    MonthToDateSpend
    ParticipationRate

=cut

sub AccountName {
    return 'AccountName';
}

sub AccountNumber {
    return 'AccountNumber';
}

sub CampaignName {
    return 'CampaignName';
}

sub CurrencyCode {
    return 'CurrencyCode';
}

sub DailySpend {
    return 'DailySpend';
}

sub Date {
    return 'Date';
}

sub MonthlyBudget {
    return 'MonthlyBudget';
}

sub MonthToDateSpend {
    return 'MonthToDateSpend';
}

sub ParticipationRate {
    return 'ParticipationRate';
}

1;
