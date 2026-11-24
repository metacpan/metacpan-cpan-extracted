package Google::Cloud::Automl::V1beta1::AnnotationSpec::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AnnotationSpec',
    as InstanceOf['Google::Cloud::Automl::V1beta1::AnnotationSpec::AnnotationSpec'];

coerce 'AnnotationSpec',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::AnnotationSpec::AnnotationSpec'->new($_) };

declare 'RepeatedAnnotationSpec',
    as ArrayRef[AnnotationSpec()];

coerce 'RepeatedAnnotationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::AnnotationSpec::AnnotationSpec'->new($_) } @$_ ] };

declare 'MapStringAnnotationSpec',
    as HashRef[AnnotationSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::AnnotationSpec::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
