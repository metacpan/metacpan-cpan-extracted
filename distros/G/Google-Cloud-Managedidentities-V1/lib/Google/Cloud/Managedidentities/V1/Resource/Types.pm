package Google::Cloud::Managedidentities::V1::Resource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Domain',
    as InstanceOf['Google::Cloud::Managedidentities::V1::Resource::Domain'];

coerce 'Domain',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1::Resource::Domain'->new($_) };

declare 'RepeatedDomain',
    as ArrayRef[Domain()];

coerce 'RepeatedDomain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1::Resource::Domain'->new($_) } @$_ ] };

declare 'MapStringDomain',
    as HashRef[Domain()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Managedidentities::V1::Resource::Domain::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1::Resource::Domain::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1::Resource::Domain::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Trust',
    as InstanceOf['Google::Cloud::Managedidentities::V1::Resource::Trust'];

coerce 'Trust',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1::Resource::Trust'->new($_) };

declare 'RepeatedTrust',
    as ArrayRef[Trust()];

coerce 'RepeatedTrust',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1::Resource::Trust'->new($_) } @$_ ] };

declare 'MapStringTrust',
    as HashRef[Trust()];

declare 'State',
    as (Int | Str);

declare 'TrustType',
    as (Int | Str);

declare 'TrustDirection',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Managedidentities::V1::Resource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
