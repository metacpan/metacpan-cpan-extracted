package Microsoft::AdCenter::V7::CustomerManagementService::PaymentMethodType;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::CustomerManagementService::PaymentMethodType - Represents "PaymentMethodType" in Microsoft AdCenter Customer Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Check
    CreditCard
    ElectronicFundsTransfer
    Invoice

=cut

sub Check {
    return 'Check';
}

sub CreditCard {
    return 'CreditCard';
}

sub ElectronicFundsTransfer {
    return 'ElectronicFundsTransfer';
}

sub Invoice {
    return 'Invoice';
}

1;
