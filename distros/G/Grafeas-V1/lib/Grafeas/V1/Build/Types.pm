package Grafeas::V1::Build::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BuildNote',
    as InstanceOf['Grafeas::V1::Build::BuildNote'];

coerce 'BuildNote',
    from HashRef, via { 'Grafeas::V1::Build::BuildNote'->new($_) };

declare 'RepeatedBuildNote',
    as ArrayRef[BuildNote()];

coerce 'RepeatedBuildNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Build::BuildNote'->new($_) } @$_ ] };

declare 'MapStringBuildNote',
    as HashRef[BuildNote()];

declare 'BuildOccurrence',
    as InstanceOf['Grafeas::V1::Build::BuildOccurrence'];

coerce 'BuildOccurrence',
    from HashRef, via { 'Grafeas::V1::Build::BuildOccurrence'->new($_) };

declare 'RepeatedBuildOccurrence',
    as ArrayRef[BuildOccurrence()];

coerce 'RepeatedBuildOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Build::BuildOccurrence'->new($_) } @$_ ] };

declare 'MapStringBuildOccurrence',
    as HashRef[BuildOccurrence()];

1;

__END__

=head1 NAME

Grafeas::V1::Build::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
