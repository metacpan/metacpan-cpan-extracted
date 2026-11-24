package Google::Cloud::Connectors::V1::Settings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetGlobalSettingsRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Settings::GetGlobalSettingsRequest'];

coerce 'GetGlobalSettingsRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Settings::GetGlobalSettingsRequest'->new($_) };

declare 'RepeatedGetGlobalSettingsRequest',
    as ArrayRef[GetGlobalSettingsRequest()];

coerce 'RepeatedGetGlobalSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Settings::GetGlobalSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetGlobalSettingsRequest',
    as HashRef[GetGlobalSettingsRequest()];

declare 'Settings',
    as InstanceOf['Google::Cloud::Connectors::V1::Settings::Settings'];

coerce 'Settings',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Settings::Settings'->new($_) };

declare 'RepeatedSettings',
    as ArrayRef[Settings()];

coerce 'RepeatedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Settings::Settings'->new($_) } @$_ ] };

declare 'MapStringSettings',
    as HashRef[Settings()];

1;

__END__

=head1 NAME

Google::Cloud::Connectors::V1::Settings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
