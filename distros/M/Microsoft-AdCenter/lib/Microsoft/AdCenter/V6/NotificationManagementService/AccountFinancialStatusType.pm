package Microsoft::AdCenter::V6::NotificationManagementService::AccountFinancialStatusType;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V6::NotificationManagementService::AccountFinancialStatusType - Represents "AccountFinancialStatusType" in Microsoft AdCenter Notification Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    CreditHold
    CreditWarning

=cut

sub CreditHold {
    return 'CreditHold';
}

sub CreditWarning {
    return 'CreditWarning';
}

1;
