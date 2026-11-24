package Google::Devtools::Artifactregistry::V1::KfpArtifact::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'KfpArtifact',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::KfpArtifact::KfpArtifact'];

coerce 'KfpArtifact',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::KfpArtifact::KfpArtifact'->new($_) };

declare 'RepeatedKfpArtifact',
    as ArrayRef[KfpArtifact()];

coerce 'RepeatedKfpArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::KfpArtifact::KfpArtifact'->new($_) } @$_ ] };

declare 'MapStringKfpArtifact',
    as HashRef[KfpArtifact()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::KfpArtifact::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
