package Google::Cloud::Discoveryengine::V1beta::RankService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RankingRecord',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::RankService::RankingRecord'];

coerce 'RankingRecord',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::RankService::RankingRecord'->new($_) };

declare 'RepeatedRankingRecord',
    as ArrayRef[RankingRecord()];

coerce 'RepeatedRankingRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::RankService::RankingRecord'->new($_) } @$_ ] };

declare 'MapStringRankingRecord',
    as HashRef[RankingRecord()];

declare 'RankRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest'];

coerce 'RankRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest'->new($_) };

declare 'RepeatedRankRequest',
    as ArrayRef[RankRequest()];

coerce 'RepeatedRankRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest'->new($_) } @$_ ] };

declare 'MapStringRankRequest',
    as HashRef[RankRequest()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'RankResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse'];

coerce 'RankResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse'->new($_) };

declare 'RepeatedRankResponse',
    as ArrayRef[RankResponse()];

coerce 'RepeatedRankResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse'->new($_) } @$_ ] };

declare 'MapStringRankResponse',
    as HashRef[RankResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::RankService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
