package Microsoft::AdCenter::V8::CampaignManagementService::Day;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::Day - Represents "Day" in Microsoft AdCenter Campaign Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Friday
    Monday
    Saturday
    Sunday
    Thursday
    Tuesday
    Wednesday

=cut

sub Friday {
    return 'Friday';
}

sub Monday {
    return 'Monday';
}

sub Saturday {
    return 'Saturday';
}

sub Sunday {
    return 'Sunday';
}

sub Thursday {
    return 'Thursday';
}

sub Tuesday {
    return 'Tuesday';
}

sub Wednesday {
    return 'Wednesday';
}

1;
