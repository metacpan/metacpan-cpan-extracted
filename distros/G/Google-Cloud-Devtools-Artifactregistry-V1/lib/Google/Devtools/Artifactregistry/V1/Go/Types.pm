package Google::Devtools::Artifactregistry::V1::Go::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoModule',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Go::GoModule'];

coerce 'GoModule',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Go::GoModule'->new($_) };

declare 'RepeatedGoModule',
    as ArrayRef[GoModule()];

coerce 'RepeatedGoModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Go::GoModule'->new($_) } @$_ ] };

declare 'MapStringGoModule',
    as HashRef[GoModule()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::Go::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
