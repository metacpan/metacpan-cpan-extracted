package Google::Cloud::Networksecurity::V1::SecurityProfileGroup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SecurityProfileGroup',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfileGroup'];

coerce 'SecurityProfileGroup',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfileGroup'->new($_) };

declare 'RepeatedSecurityProfileGroup',
    as ArrayRef[SecurityProfileGroup()];

coerce 'RepeatedSecurityProfileGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfileGroup'->new($_) } @$_ ] };

declare 'MapStringSecurityProfileGroup',
    as HashRef[SecurityProfileGroup()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfileGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfileGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfileGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'SecurityProfile',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfile'];

coerce 'SecurityProfile',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfile'->new($_) };

declare 'RepeatedSecurityProfile',
    as ArrayRef[SecurityProfile()];

coerce 'RepeatedSecurityProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfile'->new($_) } @$_ ] };

declare 'MapStringSecurityProfile',
    as HashRef[SecurityProfile()];

declare 'ProfileType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfile::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfile::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroup::SecurityProfile::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
