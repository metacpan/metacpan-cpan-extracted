package Google::Cloud::Dataqna::V1alpha::AnnotatedString::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AnnotatedString',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString'];

coerce 'AnnotatedString',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString'->new($_) };

declare 'RepeatedAnnotatedString',
    as ArrayRef[AnnotatedString()];

coerce 'RepeatedAnnotatedString',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString'->new($_) } @$_ ] };

declare 'MapStringAnnotatedString',
    as HashRef[AnnotatedString()];

declare 'SemanticMarkupType',
    as (Int | Str);

declare 'SemanticMarkup',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString::SemanticMarkup'];

coerce 'SemanticMarkup',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString::SemanticMarkup'->new($_) };

declare 'RepeatedSemanticMarkup',
    as ArrayRef[SemanticMarkup()];

coerce 'RepeatedSemanticMarkup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString::SemanticMarkup'->new($_) } @$_ ] };

declare 'MapStringSemanticMarkup',
    as HashRef[SemanticMarkup()];

1;

__END__

=head1 NAME

Google::Cloud::Dataqna::V1alpha::AnnotatedString::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
