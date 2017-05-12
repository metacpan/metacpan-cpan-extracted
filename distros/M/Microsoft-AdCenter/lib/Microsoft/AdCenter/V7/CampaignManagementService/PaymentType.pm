package Microsoft::AdCenter::V7::CampaignManagementService::PaymentType;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::CampaignManagementService::PaymentType - Represents "PaymentType" in Microsoft AdCenter Campaign Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    AmericanExpress
    Cash
    CashOnDelivery
    DinersClub
    DirectDebit
    Invoice
    MasterCard
    Other
    PayPal
    TravellersCheck
    Visa

=cut

sub AmericanExpress {
    return 'AmericanExpress';
}

sub Cash {
    return 'Cash';
}

sub CashOnDelivery {
    return 'CashOnDelivery';
}

sub DinersClub {
    return 'DinersClub';
}

sub DirectDebit {
    return 'DirectDebit';
}

sub Invoice {
    return 'Invoice';
}

sub MasterCard {
    return 'MasterCard';
}

sub Other {
    return 'Other';
}

sub PayPal {
    return 'PayPal';
}

sub TravellersCheck {
    return 'TravellersCheck';
}

sub Visa {
    return 'Visa';
}

1;
