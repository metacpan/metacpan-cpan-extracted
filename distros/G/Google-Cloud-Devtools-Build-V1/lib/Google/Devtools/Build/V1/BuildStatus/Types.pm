package Google::Devtools::Build::V1::BuildStatus::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BuildStatus',
    as InstanceOf['Google::Devtools::Build::V1::BuildStatus::BuildStatus'];

coerce 'BuildStatus',
    from HashRef, via { 'Google::Devtools::Build::V1::BuildStatus::BuildStatus'->new($_) };

declare 'RepeatedBuildStatus',
    as ArrayRef[BuildStatus()];

coerce 'RepeatedBuildStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::BuildStatus::BuildStatus'->new($_) } @$_ ] };

declare 'MapStringBuildStatus',
    as HashRef[BuildStatus()];

declare 'Result',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Devtools::Build::V1::BuildStatus::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
