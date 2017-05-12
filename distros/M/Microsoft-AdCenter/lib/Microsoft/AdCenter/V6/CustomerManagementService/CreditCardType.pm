package Microsoft::AdCenter::V6::CustomerManagementService::CreditCardType;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V6::CustomerManagementService::CreditCardType - Represents "CreditCardType" in Microsoft AdCenter Customer Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    AmExCard
    JCBCard
    MasterCard
    Unset
    VisaCard

=cut

sub AmExCard {
    return 'AmExCard';
}

sub JCBCard {
    return 'JCBCard';
}

sub MasterCard {
    return 'MasterCard';
}

sub Unset {
    return 'Unset';
}

sub VisaCard {
    return 'VisaCard';
}

1;
