package Google::Cloud::Automl::V1beta1::AnnotationPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AnnotationPayload',
    as InstanceOf['Google::Cloud::Automl::V1beta1::AnnotationPayload::AnnotationPayload'];

coerce 'AnnotationPayload',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::AnnotationPayload::AnnotationPayload'->new($_) };

declare 'RepeatedAnnotationPayload',
    as ArrayRef[AnnotationPayload()];

coerce 'RepeatedAnnotationPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::AnnotationPayload::AnnotationPayload'->new($_) } @$_ ] };

declare 'MapStringAnnotationPayload',
    as HashRef[AnnotationPayload()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::AnnotationPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
