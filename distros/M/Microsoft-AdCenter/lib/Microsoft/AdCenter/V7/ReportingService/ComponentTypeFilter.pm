package Microsoft::AdCenter::V7::ReportingService::ComponentTypeFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::ReportingService::ComponentTypeFilter - Represents "ComponentTypeFilter" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Basic
    Deeplink
    FavoriteIcon
    Form
    Image
    TitledLink
    Video

=cut

sub Basic {
    return 'Basic';
}

sub Deeplink {
    return 'Deeplink';
}

sub FavoriteIcon {
    return 'FavoriteIcon';
}

sub Form {
    return 'Form';
}

sub Image {
    return 'Image';
}

sub TitledLink {
    return 'TitledLink';
}

sub Video {
    return 'Video';
}

1;
