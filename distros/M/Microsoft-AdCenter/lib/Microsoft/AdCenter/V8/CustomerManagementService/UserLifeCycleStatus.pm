package Microsoft::AdCenter::V8::CustomerManagementService::UserLifeCycleStatus;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CustomerManagementService::UserLifeCycleStatus - Represents "UserLifeCycleStatus" in Microsoft AdCenter Customer Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Active
    Deleted
    Inactive
    New

=cut

sub Active {
    return 'Active';
}

sub Deleted {
    return 'Deleted';
}

sub Inactive {
    return 'Inactive';
}

sub New {
    return 'New';
}

1;
