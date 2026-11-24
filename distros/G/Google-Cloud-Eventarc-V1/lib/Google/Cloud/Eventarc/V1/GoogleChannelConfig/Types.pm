package Google::Cloud::Eventarc::V1::GoogleChannelConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoogleChannelConfig',
    as InstanceOf['Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig'];

coerce 'GoogleChannelConfig',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig'->new($_) };

declare 'RepeatedGoogleChannelConfig',
    as ArrayRef[GoogleChannelConfig()];

coerce 'RepeatedGoogleChannelConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig'->new($_) } @$_ ] };

declare 'MapStringGoogleChannelConfig',
    as HashRef[GoogleChannelConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::GoogleChannelConfig::GoogleChannelConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::GoogleChannelConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
