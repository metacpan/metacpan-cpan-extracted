package Microsoft::AdCenter::V7::CustomerManagementService::AccountFinancialStatus;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::CustomerManagementService::AccountFinancialStatus - Represents "AccountFinancialStatus" in Microsoft AdCenter Customer Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    ClearFinancialStatus
    CreditWarning
    Hold
    PendingCreditCheck
    Proposed
    SoldToOnly
    TaxOnHold
    UserHold
    WriteOff

=cut

sub ClearFinancialStatus {
    return 'ClearFinancialStatus';
}

sub CreditWarning {
    return 'CreditWarning';
}

sub Hold {
    return 'Hold';
}

sub PendingCreditCheck {
    return 'PendingCreditCheck';
}

sub Proposed {
    return 'Proposed';
}

sub SoldToOnly {
    return 'SoldToOnly';
}

sub TaxOnHold {
    return 'TaxOnHold';
}

sub UserHold {
    return 'UserHold';
}

sub WriteOff {
    return 'WriteOff';
}

1;
