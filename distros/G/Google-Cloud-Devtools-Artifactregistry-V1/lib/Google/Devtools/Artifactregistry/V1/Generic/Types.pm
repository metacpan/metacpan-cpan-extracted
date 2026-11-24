package Google::Devtools::Artifactregistry::V1::Generic::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenericArtifact',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Generic::GenericArtifact'];

coerce 'GenericArtifact',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Generic::GenericArtifact'->new($_) };

declare 'RepeatedGenericArtifact',
    as ArrayRef[GenericArtifact()];

coerce 'RepeatedGenericArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Generic::GenericArtifact'->new($_) } @$_ ] };

declare 'MapStringGenericArtifact',
    as HashRef[GenericArtifact()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::Generic::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
