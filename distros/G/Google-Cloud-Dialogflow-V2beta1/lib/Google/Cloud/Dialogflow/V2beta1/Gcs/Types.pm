package Google::Cloud::Dialogflow::V2beta1::Gcs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GcsSources',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSources'];

coerce 'GcsSources',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSources'->new($_) };

declare 'RepeatedGcsSources',
    as ArrayRef[GcsSources()];

coerce 'RepeatedGcsSources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSources'->new($_) } @$_ ] };

declare 'MapStringGcsSources',
    as HashRef[GcsSources()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Gcs::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Gcs::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Gcs::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Gcs::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Gcs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
