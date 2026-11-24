package Google::Cloud::Securitycenter::V2::Finding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Finding',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Finding::Finding'];

coerce 'Finding',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Finding::Finding'->new($_) };

declare 'RepeatedFinding',
    as ArrayRef[Finding()];

coerce 'RepeatedFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Finding::Finding'->new($_) } @$_ ] };

declare 'MapStringFinding',
    as HashRef[Finding()];

declare 'State',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'Mute',
    as (Int | Str);

declare 'FindingClass',
    as (Int | Str);

declare 'MuteInfo',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Finding::Finding::MuteInfo'];

coerce 'MuteInfo',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Finding::Finding::MuteInfo'->new($_) };

declare 'RepeatedMuteInfo',
    as ArrayRef[MuteInfo()];

coerce 'RepeatedMuteInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Finding::Finding::MuteInfo'->new($_) } @$_ ] };

declare 'MapStringMuteInfo',
    as HashRef[MuteInfo()];

declare 'StaticMute',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Finding::Finding::MuteInfo::StaticMute'];

coerce 'StaticMute',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Finding::Finding::MuteInfo::StaticMute'->new($_) };

declare 'RepeatedStaticMute',
    as ArrayRef[StaticMute()];

coerce 'RepeatedStaticMute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Finding::Finding::MuteInfo::StaticMute'->new($_) } @$_ ] };

declare 'MapStringStaticMute',
    as HashRef[StaticMute()];

declare 'DynamicMuteRecord',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Finding::Finding::MuteInfo::DynamicMuteRecord'];

coerce 'DynamicMuteRecord',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Finding::Finding::MuteInfo::DynamicMuteRecord'->new($_) };

declare 'RepeatedDynamicMuteRecord',
    as ArrayRef[DynamicMuteRecord()];

coerce 'RepeatedDynamicMuteRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Finding::Finding::MuteInfo::DynamicMuteRecord'->new($_) } @$_ ] };

declare 'MapStringDynamicMuteRecord',
    as HashRef[DynamicMuteRecord()];

declare 'SourcePropertiesEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Finding::Finding::SourcePropertiesEntry'];

coerce 'SourcePropertiesEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Finding::Finding::SourcePropertiesEntry'->new($_) };

declare 'RepeatedSourcePropertiesEntry',
    as ArrayRef[SourcePropertiesEntry()];

coerce 'RepeatedSourcePropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Finding::Finding::SourcePropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringSourcePropertiesEntry',
    as HashRef[SourcePropertiesEntry()];

declare 'ExternalSystemsEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Finding::Finding::ExternalSystemsEntry'];

coerce 'ExternalSystemsEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Finding::Finding::ExternalSystemsEntry'->new($_) };

declare 'RepeatedExternalSystemsEntry',
    as ArrayRef[ExternalSystemsEntry()];

coerce 'RepeatedExternalSystemsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Finding::Finding::ExternalSystemsEntry'->new($_) } @$_ ] };

declare 'MapStringExternalSystemsEntry',
    as HashRef[ExternalSystemsEntry()];

declare 'ContactsEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Finding::Finding::ContactsEntry'];

coerce 'ContactsEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Finding::Finding::ContactsEntry'->new($_) };

declare 'RepeatedContactsEntry',
    as ArrayRef[ContactsEntry()];

coerce 'RepeatedContactsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Finding::Finding::ContactsEntry'->new($_) } @$_ ] };

declare 'MapStringContactsEntry',
    as HashRef[ContactsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::Finding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
