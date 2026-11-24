package Google::Cloud::Chronicle::V1::Entity::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Entity',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'Watchlist',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::Watchlist'];

coerce 'Watchlist',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::Watchlist'->new($_) };

declare 'RepeatedWatchlist',
    as ArrayRef[Watchlist()];

coerce 'RepeatedWatchlist',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::Watchlist'->new($_) } @$_ ] };

declare 'MapStringWatchlist',
    as HashRef[Watchlist()];

declare 'EntityPopulationMechanism',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityPopulationMechanism'];

coerce 'EntityPopulationMechanism',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityPopulationMechanism'->new($_) };

declare 'RepeatedEntityPopulationMechanism',
    as ArrayRef[EntityPopulationMechanism()];

coerce 'RepeatedEntityPopulationMechanism',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityPopulationMechanism'->new($_) } @$_ ] };

declare 'MapStringEntityPopulationMechanism',
    as HashRef[EntityPopulationMechanism()];

declare 'Manual',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityPopulationMechanism::Manual'];

coerce 'Manual',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityPopulationMechanism::Manual'->new($_) };

declare 'RepeatedManual',
    as ArrayRef[Manual()];

coerce 'RepeatedManual',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityPopulationMechanism::Manual'->new($_) } @$_ ] };

declare 'MapStringManual',
    as HashRef[Manual()];

declare 'EntityCount',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityCount'];

coerce 'EntityCount',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityCount'->new($_) };

declare 'RepeatedEntityCount',
    as ArrayRef[EntityCount()];

coerce 'RepeatedEntityCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityCount'->new($_) } @$_ ] };

declare 'MapStringEntityCount',
    as HashRef[EntityCount()];

declare 'WatchlistUserPreferences',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::WatchlistUserPreferences'];

coerce 'WatchlistUserPreferences',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::WatchlistUserPreferences'->new($_) };

declare 'RepeatedWatchlistUserPreferences',
    as ArrayRef[WatchlistUserPreferences()];

coerce 'RepeatedWatchlistUserPreferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::WatchlistUserPreferences'->new($_) } @$_ ] };

declare 'MapStringWatchlistUserPreferences',
    as HashRef[WatchlistUserPreferences()];

declare 'GetWatchlistRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::GetWatchlistRequest'];

coerce 'GetWatchlistRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::GetWatchlistRequest'->new($_) };

declare 'RepeatedGetWatchlistRequest',
    as ArrayRef[GetWatchlistRequest()];

coerce 'RepeatedGetWatchlistRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::GetWatchlistRequest'->new($_) } @$_ ] };

declare 'MapStringGetWatchlistRequest',
    as HashRef[GetWatchlistRequest()];

declare 'ListWatchlistsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::ListWatchlistsRequest'];

coerce 'ListWatchlistsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::ListWatchlistsRequest'->new($_) };

declare 'RepeatedListWatchlistsRequest',
    as ArrayRef[ListWatchlistsRequest()];

coerce 'RepeatedListWatchlistsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::ListWatchlistsRequest'->new($_) } @$_ ] };

declare 'MapStringListWatchlistsRequest',
    as HashRef[ListWatchlistsRequest()];

declare 'ListWatchlistsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::ListWatchlistsResponse'];

coerce 'ListWatchlistsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::ListWatchlistsResponse'->new($_) };

declare 'RepeatedListWatchlistsResponse',
    as ArrayRef[ListWatchlistsResponse()];

coerce 'RepeatedListWatchlistsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::ListWatchlistsResponse'->new($_) } @$_ ] };

declare 'MapStringListWatchlistsResponse',
    as HashRef[ListWatchlistsResponse()];

declare 'CreateWatchlistRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::CreateWatchlistRequest'];

coerce 'CreateWatchlistRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::CreateWatchlistRequest'->new($_) };

declare 'RepeatedCreateWatchlistRequest',
    as ArrayRef[CreateWatchlistRequest()];

coerce 'RepeatedCreateWatchlistRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::CreateWatchlistRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWatchlistRequest',
    as HashRef[CreateWatchlistRequest()];

declare 'UpdateWatchlistRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::UpdateWatchlistRequest'];

coerce 'UpdateWatchlistRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::UpdateWatchlistRequest'->new($_) };

declare 'RepeatedUpdateWatchlistRequest',
    as ArrayRef[UpdateWatchlistRequest()];

coerce 'RepeatedUpdateWatchlistRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::UpdateWatchlistRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWatchlistRequest',
    as HashRef[UpdateWatchlistRequest()];

declare 'DeleteWatchlistRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Entity::DeleteWatchlistRequest'];

coerce 'DeleteWatchlistRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Entity::DeleteWatchlistRequest'->new($_) };

declare 'RepeatedDeleteWatchlistRequest',
    as ArrayRef[DeleteWatchlistRequest()];

coerce 'RepeatedDeleteWatchlistRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Entity::DeleteWatchlistRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWatchlistRequest',
    as HashRef[DeleteWatchlistRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::Entity::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
