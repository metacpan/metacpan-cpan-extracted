package Microsoft::AdCenter::V8::CampaignManagementService::HourRange;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::HourRange - Represents "HourRange" in Microsoft AdCenter Campaign Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    ElevenAMToTwoPM
    ElevenPMToThreeAM
    SevenAMToElevenAM
    SixPMToElevenPM
    ThreeAMToSevenAM
    TwoPMToSixPM

=cut

sub ElevenAMToTwoPM {
    return 'ElevenAMToTwoPM';
}

sub ElevenPMToThreeAM {
    return 'ElevenPMToThreeAM';
}

sub SevenAMToElevenAM {
    return 'SevenAMToElevenAM';
}

sub SixPMToElevenPM {
    return 'SixPMToElevenPM';
}

sub ThreeAMToSevenAM {
    return 'ThreeAMToSevenAM';
}

sub TwoPMToSixPM {
    return 'TwoPMToSixPM';
}

1;
