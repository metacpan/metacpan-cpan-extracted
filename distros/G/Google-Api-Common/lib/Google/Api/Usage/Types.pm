package Google::Api::Usage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Usage',
    as InstanceOf['Google::Api::Usage::Usage'];

coerce 'Usage',
    from HashRef, via { 'Google::Api::Usage::Usage'->new($_) };

declare 'RepeatedUsage',
    as ArrayRef[Usage()];

coerce 'RepeatedUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Usage::Usage'->new($_) } @$_ ] };

declare 'MapStringUsage',
    as HashRef[Usage()];

declare 'UsageRule',
    as InstanceOf['Google::Api::Usage::UsageRule'];

coerce 'UsageRule',
    from HashRef, via { 'Google::Api::Usage::UsageRule'->new($_) };

declare 'RepeatedUsageRule',
    as ArrayRef[UsageRule()];

coerce 'RepeatedUsageRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Usage::UsageRule'->new($_) } @$_ ] };

declare 'MapStringUsageRule',
    as HashRef[UsageRule()];

1;

__END__

=head1 NAME

Google::Api::Usage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
