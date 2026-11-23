package Google::Ai::Generativelanguage::V1beta::CachedContent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CachedContent',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent'];

coerce 'CachedContent',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent'->new($_) };

declare 'RepeatedCachedContent',
    as ArrayRef[CachedContent()];

coerce 'RepeatedCachedContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent'->new($_) } @$_ ] };

declare 'MapStringCachedContent',
    as HashRef[CachedContent()];

declare 'UsageMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent::UsageMetadata'];

coerce 'UsageMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent::UsageMetadata'->new($_) };

declare 'RepeatedUsageMetadata',
    as ArrayRef[UsageMetadata()];

coerce 'RepeatedUsageMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent::UsageMetadata'->new($_) } @$_ ] };

declare 'MapStringUsageMetadata',
    as HashRef[UsageMetadata()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CachedContent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
