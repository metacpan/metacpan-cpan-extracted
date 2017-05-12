package Microsoft::AdCenter::V8::AdIntelligenceService::Scale;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::AdIntelligenceService::Scale - Represents "Scale" in Microsoft AdCenter Ad Intelligence Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    High
    Low
    Medium
    Minimal
    VeryHigh

=cut

sub High {
    return 'High';
}

sub Low {
    return 'Low';
}

sub Medium {
    return 'Medium';
}

sub Minimal {
    return 'Minimal';
}

sub VeryHigh {
    return 'VeryHigh';
}

1;
