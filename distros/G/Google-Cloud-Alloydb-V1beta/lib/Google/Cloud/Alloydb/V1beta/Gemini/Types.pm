package Google::Cloud::Alloydb::V1beta::Gemini::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GCAEntitlementType',
    as (Int | Str);

declare 'GeminiClusterConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Gemini::GeminiClusterConfig'];

coerce 'GeminiClusterConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Gemini::GeminiClusterConfig'->new($_) };

declare 'RepeatedGeminiClusterConfig',
    as ArrayRef[GeminiClusterConfig()];

coerce 'RepeatedGeminiClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Gemini::GeminiClusterConfig'->new($_) } @$_ ] };

declare 'MapStringGeminiClusterConfig',
    as HashRef[GeminiClusterConfig()];

declare 'GeminiInstanceConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Gemini::GeminiInstanceConfig'];

coerce 'GeminiInstanceConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Gemini::GeminiInstanceConfig'->new($_) };

declare 'RepeatedGeminiInstanceConfig',
    as ArrayRef[GeminiInstanceConfig()];

coerce 'RepeatedGeminiInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Gemini::GeminiInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringGeminiInstanceConfig',
    as HashRef[GeminiInstanceConfig()];

declare 'GCAInstanceConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::Gemini::GCAInstanceConfig'];

coerce 'GCAInstanceConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::Gemini::GCAInstanceConfig'->new($_) };

declare 'RepeatedGCAInstanceConfig',
    as ArrayRef[GCAInstanceConfig()];

coerce 'RepeatedGCAInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::Gemini::GCAInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringGCAInstanceConfig',
    as HashRef[GCAInstanceConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Alloydb::V1beta::Gemini::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
