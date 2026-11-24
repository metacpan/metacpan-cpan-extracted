package Google::Cloud::Discoveryengine::V1alpha::DataStore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataStore',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore'];

coerce 'DataStore',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore'->new($_) };

declare 'RepeatedDataStore',
    as ArrayRef[DataStore()];

coerce 'RepeatedDataStore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore'->new($_) } @$_ ] };

declare 'MapStringDataStore',
    as HashRef[DataStore()];

declare 'ContentConfig',
    as (Int | Str);

declare 'LanguageInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DataStore::LanguageInfo'];

coerce 'LanguageInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DataStore::LanguageInfo'->new($_) };

declare 'RepeatedLanguageInfo',
    as ArrayRef[LanguageInfo()];

coerce 'RepeatedLanguageInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DataStore::LanguageInfo'->new($_) } @$_ ] };

declare 'MapStringLanguageInfo',
    as HashRef[LanguageInfo()];

declare 'WorkspaceConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DataStore::WorkspaceConfig'];

coerce 'WorkspaceConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DataStore::WorkspaceConfig'->new($_) };

declare 'RepeatedWorkspaceConfig',
    as ArrayRef[WorkspaceConfig()];

coerce 'RepeatedWorkspaceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DataStore::WorkspaceConfig'->new($_) } @$_ ] };

declare 'MapStringWorkspaceConfig',
    as HashRef[WorkspaceConfig()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::DataStore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
