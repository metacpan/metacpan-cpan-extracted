package Google::Spanner::V1::Location::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Range',
    as InstanceOf['Google::Spanner::V1::Location::Range'];

coerce 'Range',
    from HashRef, via { 'Google::Spanner::V1::Location::Range'->new($_) };

declare 'RepeatedRange',
    as ArrayRef[Range()];

coerce 'RepeatedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Location::Range'->new($_) } @$_ ] };

declare 'MapStringRange',
    as HashRef[Range()];

declare 'Tablet',
    as InstanceOf['Google::Spanner::V1::Location::Tablet'];

coerce 'Tablet',
    from HashRef, via { 'Google::Spanner::V1::Location::Tablet'->new($_) };

declare 'RepeatedTablet',
    as ArrayRef[Tablet()];

coerce 'RepeatedTablet',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Location::Tablet'->new($_) } @$_ ] };

declare 'MapStringTablet',
    as HashRef[Tablet()];

declare 'Role',
    as (Int | Str);

declare 'Group',
    as InstanceOf['Google::Spanner::V1::Location::Group'];

coerce 'Group',
    from HashRef, via { 'Google::Spanner::V1::Location::Group'->new($_) };

declare 'RepeatedGroup',
    as ArrayRef[Group()];

coerce 'RepeatedGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Location::Group'->new($_) } @$_ ] };

declare 'MapStringGroup',
    as HashRef[Group()];

declare 'KeyRecipe',
    as InstanceOf['Google::Spanner::V1::Location::KeyRecipe'];

coerce 'KeyRecipe',
    from HashRef, via { 'Google::Spanner::V1::Location::KeyRecipe'->new($_) };

declare 'RepeatedKeyRecipe',
    as ArrayRef[KeyRecipe()];

coerce 'RepeatedKeyRecipe',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Location::KeyRecipe'->new($_) } @$_ ] };

declare 'MapStringKeyRecipe',
    as HashRef[KeyRecipe()];

declare 'Part',
    as InstanceOf['Google::Spanner::V1::Location::KeyRecipe::Part'];

coerce 'Part',
    from HashRef, via { 'Google::Spanner::V1::Location::KeyRecipe::Part'->new($_) };

declare 'RepeatedPart',
    as ArrayRef[Part()];

coerce 'RepeatedPart',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Location::KeyRecipe::Part'->new($_) } @$_ ] };

declare 'MapStringPart',
    as HashRef[Part()];

declare 'Order',
    as (Int | Str);

declare 'NullOrder',
    as (Int | Str);

declare 'RecipeList',
    as InstanceOf['Google::Spanner::V1::Location::RecipeList'];

coerce 'RecipeList',
    from HashRef, via { 'Google::Spanner::V1::Location::RecipeList'->new($_) };

declare 'RepeatedRecipeList',
    as ArrayRef[RecipeList()];

coerce 'RepeatedRecipeList',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Location::RecipeList'->new($_) } @$_ ] };

declare 'MapStringRecipeList',
    as HashRef[RecipeList()];

declare 'CacheUpdate',
    as InstanceOf['Google::Spanner::V1::Location::CacheUpdate'];

coerce 'CacheUpdate',
    from HashRef, via { 'Google::Spanner::V1::Location::CacheUpdate'->new($_) };

declare 'RepeatedCacheUpdate',
    as ArrayRef[CacheUpdate()];

coerce 'RepeatedCacheUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Location::CacheUpdate'->new($_) } @$_ ] };

declare 'MapStringCacheUpdate',
    as HashRef[CacheUpdate()];

declare 'RoutingHint',
    as InstanceOf['Google::Spanner::V1::Location::RoutingHint'];

coerce 'RoutingHint',
    from HashRef, via { 'Google::Spanner::V1::Location::RoutingHint'->new($_) };

declare 'RepeatedRoutingHint',
    as ArrayRef[RoutingHint()];

coerce 'RepeatedRoutingHint',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Location::RoutingHint'->new($_) } @$_ ] };

declare 'MapStringRoutingHint',
    as HashRef[RoutingHint()];

declare 'SkippedTablet',
    as InstanceOf['Google::Spanner::V1::Location::RoutingHint::SkippedTablet'];

coerce 'SkippedTablet',
    from HashRef, via { 'Google::Spanner::V1::Location::RoutingHint::SkippedTablet'->new($_) };

declare 'RepeatedSkippedTablet',
    as ArrayRef[SkippedTablet()];

coerce 'RepeatedSkippedTablet',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Location::RoutingHint::SkippedTablet'->new($_) } @$_ ] };

declare 'MapStringSkippedTablet',
    as HashRef[SkippedTablet()];

1;

__END__

=head1 NAME

Google::Spanner::V1::Location::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
