package Google::Cloud::Websecurityscanner::V1::Finding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Finding',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::Finding::Finding'];

coerce 'Finding',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::Finding::Finding'->new($_) };

declare 'RepeatedFinding',
    as ArrayRef[Finding()];

coerce 'RepeatedFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::Finding::Finding'->new($_) } @$_ ] };

declare 'MapStringFinding',
    as HashRef[Finding()];

declare 'Severity',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Websecurityscanner::V1::Finding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
