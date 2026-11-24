package Google::Cloud::Retail::V2alpha::GenerativeQuestion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenerativeQuestionsFeatureConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig'];

coerce 'GenerativeQuestionsFeatureConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig'->new($_) };

declare 'RepeatedGenerativeQuestionsFeatureConfig',
    as ArrayRef[GenerativeQuestionsFeatureConfig()];

coerce 'RepeatedGenerativeQuestionsFeatureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig'->new($_) } @$_ ] };

declare 'MapStringGenerativeQuestionsFeatureConfig',
    as HashRef[GenerativeQuestionsFeatureConfig()];

declare 'GenerativeQuestionConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionConfig'];

coerce 'GenerativeQuestionConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionConfig'->new($_) };

declare 'RepeatedGenerativeQuestionConfig',
    as ArrayRef[GenerativeQuestionConfig()];

coerce 'RepeatedGenerativeQuestionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionConfig'->new($_) } @$_ ] };

declare 'MapStringGenerativeQuestionConfig',
    as HashRef[GenerativeQuestionConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::GenerativeQuestion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
