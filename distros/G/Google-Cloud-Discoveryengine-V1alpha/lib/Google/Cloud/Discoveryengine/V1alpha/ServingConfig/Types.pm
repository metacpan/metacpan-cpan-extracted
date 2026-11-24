package Google::Cloud::Discoveryengine::V1alpha::ServingConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig'];

coerce 'ServingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig'->new($_) };

declare 'RepeatedServingConfig',
    as ArrayRef[ServingConfig()];

coerce 'RepeatedServingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig'->new($_) } @$_ ] };

declare 'MapStringServingConfig',
    as HashRef[ServingConfig()];

declare 'MediaConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig::MediaConfig'];

coerce 'MediaConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig::MediaConfig'->new($_) };

declare 'RepeatedMediaConfig',
    as ArrayRef[MediaConfig()];

coerce 'RepeatedMediaConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig::MediaConfig'->new($_) } @$_ ] };

declare 'MapStringMediaConfig',
    as HashRef[MediaConfig()];

declare 'GenericConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig::GenericConfig'];

coerce 'GenericConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig::GenericConfig'->new($_) };

declare 'RepeatedGenericConfig',
    as ArrayRef[GenericConfig()];

coerce 'RepeatedGenericConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig::GenericConfig'->new($_) } @$_ ] };

declare 'MapStringGenericConfig',
    as HashRef[GenericConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::ServingConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
