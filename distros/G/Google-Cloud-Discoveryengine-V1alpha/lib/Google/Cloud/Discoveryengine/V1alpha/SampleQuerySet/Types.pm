package Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SampleQuerySet',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet'];

coerce 'SampleQuerySet',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet'->new($_) };

declare 'RepeatedSampleQuerySet',
    as ArrayRef[SampleQuerySet()];

coerce 'RepeatedSampleQuerySet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet'->new($_) } @$_ ] };

declare 'MapStringSampleQuerySet',
    as HashRef[SampleQuerySet()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
