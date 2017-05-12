package Microsoft::AdCenter::V8::NotificationService::NotificationType;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::NotificationService::NotificationType - Represents "NotificationType" in Microsoft AdCenter Notification Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    CreditCardPendingExpiration
    DepletedBudget
    EditorialRejection
    ExpiredCreditCard
    ExpiredInsertionOrder
    LowBudgetBalance

=cut

sub CreditCardPendingExpiration {
    return 'CreditCardPendingExpiration';
}

sub DepletedBudget {
    return 'DepletedBudget';
}

sub EditorialRejection {
    return 'EditorialRejection';
}

sub ExpiredCreditCard {
    return 'ExpiredCreditCard';
}

sub ExpiredInsertionOrder {
    return 'ExpiredInsertionOrder';
}

sub LowBudgetBalance {
    return 'LowBudgetBalance';
}

1;
