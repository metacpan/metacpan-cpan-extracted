package Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AnnotationSpecSet',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpecSet'];

coerce 'AnnotationSpecSet',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpecSet'->new($_) };

declare 'RepeatedAnnotationSpecSet',
    as ArrayRef[AnnotationSpecSet()];

coerce 'RepeatedAnnotationSpecSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpecSet'->new($_) } @$_ ] };

declare 'MapStringAnnotationSpecSet',
    as HashRef[AnnotationSpecSet()];

declare 'AnnotationSpec',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec'];

coerce 'AnnotationSpec',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec'->new($_) };

declare 'RepeatedAnnotationSpec',
    as ArrayRef[AnnotationSpec()];

coerce 'RepeatedAnnotationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::AnnotationSpec'->new($_) } @$_ ] };

declare 'MapStringAnnotationSpec',
    as HashRef[AnnotationSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
