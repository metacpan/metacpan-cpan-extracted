package Google::Cloud::Eventarc::V1::GoogleApiSource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoogleApiSource',
    as InstanceOf['Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource'];

coerce 'GoogleApiSource',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource'->new($_) };

declare 'RepeatedGoogleApiSource',
    as ArrayRef[GoogleApiSource()];

coerce 'RepeatedGoogleApiSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource'->new($_) } @$_ ] };

declare 'MapStringGoogleApiSource',
    as HashRef[GoogleApiSource()];

declare 'ProjectSubscriptions',
    as InstanceOf['Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::ProjectSubscriptions'];

coerce 'ProjectSubscriptions',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::ProjectSubscriptions'->new($_) };

declare 'RepeatedProjectSubscriptions',
    as ArrayRef[ProjectSubscriptions()];

coerce 'RepeatedProjectSubscriptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::ProjectSubscriptions'->new($_) } @$_ ] };

declare 'MapStringProjectSubscriptions',
    as HashRef[ProjectSubscriptions()];

declare 'OrganizationSubscription',
    as InstanceOf['Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::OrganizationSubscription'];

coerce 'OrganizationSubscription',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::OrganizationSubscription'->new($_) };

declare 'RepeatedOrganizationSubscription',
    as ArrayRef[OrganizationSubscription()];

coerce 'RepeatedOrganizationSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::OrganizationSubscription'->new($_) } @$_ ] };

declare 'MapStringOrganizationSubscription',
    as HashRef[OrganizationSubscription()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::GoogleApiSource::GoogleApiSource::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::GoogleApiSource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
