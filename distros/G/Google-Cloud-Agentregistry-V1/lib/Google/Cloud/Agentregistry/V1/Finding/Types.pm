package Google::Cloud::Agentregistry::V1::Finding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Severity',
    as (Int | Str);

declare 'Finding',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Finding::Finding'];

coerce 'Finding',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Finding::Finding'->new($_) };

declare 'RepeatedFinding',
    as ArrayRef[Finding()];

coerce 'RepeatedFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Finding::Finding'->new($_) } @$_ ] };

declare 'MapStringFinding',
    as HashRef[Finding()];

declare 'FindingClass',
    as (Int | Str);

declare 'File',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Finding::Finding::File'];

coerce 'File',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Finding::Finding::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Finding::Finding::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::Finding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
