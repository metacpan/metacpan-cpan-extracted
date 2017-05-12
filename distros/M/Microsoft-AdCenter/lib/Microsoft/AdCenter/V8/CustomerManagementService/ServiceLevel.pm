package Microsoft::AdCenter::V8::CustomerManagementService::ServiceLevel;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CustomerManagementService::ServiceLevel - Represents "ServiceLevel" in Microsoft AdCenter Customer Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Internal
    Premium
    Select
    SelfServe
    SelfServeTrusted

=cut

sub Internal {
    return 'Internal';
}

sub Premium {
    return 'Premium';
}

sub Select {
    return 'Select';
}

sub SelfServe {
    return 'SelfServe';
}

sub SelfServeTrusted {
    return 'SelfServeTrusted';
}

1;
