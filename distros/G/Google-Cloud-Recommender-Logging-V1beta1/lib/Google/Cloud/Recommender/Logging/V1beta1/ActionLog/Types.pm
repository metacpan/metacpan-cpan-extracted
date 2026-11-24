package Google::Cloud::Recommender::Logging::V1beta1::ActionLog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ActionLog',
    as InstanceOf['Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog'];

coerce 'ActionLog',
    from HashRef, via { 'Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog'->new($_) };

declare 'RepeatedActionLog',
    as ArrayRef[ActionLog()];

coerce 'RepeatedActionLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog'->new($_) } @$_ ] };

declare 'MapStringActionLog',
    as HashRef[ActionLog()];

declare 'StateMetadataEntry',
    as InstanceOf['Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog::StateMetadataEntry'];

coerce 'StateMetadataEntry',
    from HashRef, via { 'Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog::StateMetadataEntry'->new($_) };

declare 'RepeatedStateMetadataEntry',
    as ArrayRef[StateMetadataEntry()];

coerce 'RepeatedStateMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::Logging::V1beta1::ActionLog::ActionLog::StateMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringStateMetadataEntry',
    as HashRef[StateMetadataEntry()];

declare 'InsightActionLog',
    as InstanceOf['Google::Cloud::Recommender::Logging::V1beta1::ActionLog::InsightActionLog'];

coerce 'InsightActionLog',
    from HashRef, via { 'Google::Cloud::Recommender::Logging::V1beta1::ActionLog::InsightActionLog'->new($_) };

declare 'RepeatedInsightActionLog',
    as ArrayRef[InsightActionLog()];

coerce 'RepeatedInsightActionLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::Logging::V1beta1::ActionLog::InsightActionLog'->new($_) } @$_ ] };

declare 'MapStringInsightActionLog',
    as HashRef[InsightActionLog()];

declare 'StateMetadataEntry',
    as InstanceOf['Google::Cloud::Recommender::Logging::V1beta1::ActionLog::InsightActionLog::StateMetadataEntry'];

coerce 'StateMetadataEntry',
    from HashRef, via { 'Google::Cloud::Recommender::Logging::V1beta1::ActionLog::InsightActionLog::StateMetadataEntry'->new($_) };

declare 'RepeatedStateMetadataEntry',
    as ArrayRef[StateMetadataEntry()];

coerce 'RepeatedStateMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::Logging::V1beta1::ActionLog::InsightActionLog::StateMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringStateMetadataEntry',
    as HashRef[StateMetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Recommender::Logging::V1beta1::ActionLog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
