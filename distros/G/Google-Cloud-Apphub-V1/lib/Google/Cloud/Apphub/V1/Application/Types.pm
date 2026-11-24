package Google::Cloud::Apphub::V1::Application::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Application',
    as InstanceOf['Google::Cloud::Apphub::V1::Application::Application'];

coerce 'Application',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Application::Application'->new($_) };

declare 'RepeatedApplication',
    as ArrayRef[Application()];

coerce 'RepeatedApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Application::Application'->new($_) } @$_ ] };

declare 'MapStringApplication',
    as HashRef[Application()];

declare 'State',
    as (Int | Str);

declare 'ApplicationType',
    as InstanceOf['Google::Cloud::Apphub::V1::Application::ApplicationType'];

coerce 'ApplicationType',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Application::ApplicationType'->new($_) };

declare 'RepeatedApplicationType',
    as ArrayRef[ApplicationType()];

coerce 'RepeatedApplicationType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Application::ApplicationType'->new($_) } @$_ ] };

declare 'MapStringApplicationType',
    as HashRef[ApplicationType()];

declare 'Type',
    as (Int | Str);

declare 'Scope',
    as InstanceOf['Google::Cloud::Apphub::V1::Application::Scope'];

coerce 'Scope',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Application::Scope'->new($_) };

declare 'RepeatedScope',
    as ArrayRef[Scope()];

coerce 'RepeatedScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Application::Scope'->new($_) } @$_ ] };

declare 'MapStringScope',
    as HashRef[Scope()];

declare 'Type',
    as (Int | Str);

declare 'ApplicationProperties',
    as InstanceOf['Google::Cloud::Apphub::V1::Application::ApplicationProperties'];

coerce 'ApplicationProperties',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Application::ApplicationProperties'->new($_) };

declare 'RepeatedApplicationProperties',
    as ArrayRef[ApplicationProperties()];

coerce 'RepeatedApplicationProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Application::ApplicationProperties'->new($_) } @$_ ] };

declare 'MapStringApplicationProperties',
    as HashRef[ApplicationProperties()];

declare 'ExtendedMetadataEntry',
    as InstanceOf['Google::Cloud::Apphub::V1::Application::ApplicationProperties::ExtendedMetadataEntry'];

coerce 'ExtendedMetadataEntry',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Application::ApplicationProperties::ExtendedMetadataEntry'->new($_) };

declare 'RepeatedExtendedMetadataEntry',
    as ArrayRef[ExtendedMetadataEntry()];

coerce 'RepeatedExtendedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Application::ApplicationProperties::ExtendedMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringExtendedMetadataEntry',
    as HashRef[ExtendedMetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Apphub::V1::Application::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
