package Microsoft::AdCenter::V8::AdIntelligenceService::TargetAdPosition;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::AdIntelligenceService::TargetAdPosition - Represents "TargetAdPosition" in Microsoft AdCenter Ad Intelligence Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    MainLine
    MainLine1
    SideBar

=cut

sub MainLine {
    return 'MainLine';
}

sub MainLine1 {
    return 'MainLine1';
}

sub SideBar {
    return 'SideBar';
}

1;
