package Google::Cloud::Dialogflow::Cx::V3beta1::Gcs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Gcs::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Gcs::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Gcs::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Gcs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
