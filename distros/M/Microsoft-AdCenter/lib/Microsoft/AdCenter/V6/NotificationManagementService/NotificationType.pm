package Microsoft::AdCenter::V6::NotificationManagementService::NotificationType;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V6::NotificationManagementService::NotificationType - Represents "NotificationType" in Microsoft AdCenter Notification Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    AccountClosed
    AccountSignupPaymentReceipt
    ApproachingCreditCardExpiration
    CreditCardExpired
    EditorialRejection
    NewCustomerSignup
    NewUserAdded
    UnableToChargeCreditCard
    UserNameReminder
    UserPasswordReset

=cut

sub AccountClosed {
    return 'AccountClosed';
}

sub AccountSignupPaymentReceipt {
    return 'AccountSignupPaymentReceipt';
}

sub ApproachingCreditCardExpiration {
    return 'ApproachingCreditCardExpiration';
}

sub CreditCardExpired {
    return 'CreditCardExpired';
}

sub EditorialRejection {
    return 'EditorialRejection';
}

sub NewCustomerSignup {
    return 'NewCustomerSignup';
}

sub NewUserAdded {
    return 'NewUserAdded';
}

sub UnableToChargeCreditCard {
    return 'UnableToChargeCreditCard';
}

sub UserNameReminder {
    return 'UserNameReminder';
}

sub UserPasswordReset {
    return 'UserPasswordReset';
}

1;
