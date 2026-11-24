package Google::Cloud::Geminidataanalytics::V1alpha::Usage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TokenUsage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1alpha::Usage::TokenUsage'];

coerce 'TokenUsage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1alpha::Usage::TokenUsage'->new($_) };

declare 'RepeatedTokenUsage',
    as ArrayRef[TokenUsage()];

coerce 'RepeatedTokenUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1alpha::Usage::TokenUsage'->new($_) } @$_ ] };

declare 'MapStringTokenUsage',
    as HashRef[TokenUsage()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1alpha::Usage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
