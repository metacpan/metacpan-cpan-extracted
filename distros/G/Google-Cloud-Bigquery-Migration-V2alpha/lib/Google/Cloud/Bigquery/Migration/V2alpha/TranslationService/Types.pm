package Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TranslateQueryRequest',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryRequest'];

coerce 'TranslateQueryRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryRequest'->new($_) };

declare 'RepeatedTranslateQueryRequest',
    as ArrayRef[TranslateQueryRequest()];

coerce 'RepeatedTranslateQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryRequest'->new($_) } @$_ ] };

declare 'MapStringTranslateQueryRequest',
    as HashRef[TranslateQueryRequest()];

declare 'SqlTranslationSourceDialect',
    as (Int | Str);

declare 'TranslateQueryResponse',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryResponse'];

coerce 'TranslateQueryResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryResponse'->new($_) };

declare 'RepeatedTranslateQueryResponse',
    as ArrayRef[TranslateQueryResponse()];

coerce 'RepeatedTranslateQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryResponse'->new($_) } @$_ ] };

declare 'MapStringTranslateQueryResponse',
    as HashRef[TranslateQueryResponse()];

declare 'SqlTranslationErrorDetail',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationErrorDetail'];

coerce 'SqlTranslationErrorDetail',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationErrorDetail'->new($_) };

declare 'RepeatedSqlTranslationErrorDetail',
    as ArrayRef[SqlTranslationErrorDetail()];

coerce 'RepeatedSqlTranslationErrorDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationErrorDetail'->new($_) } @$_ ] };

declare 'MapStringSqlTranslationErrorDetail',
    as HashRef[SqlTranslationErrorDetail()];

declare 'SqlTranslationError',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationError'];

coerce 'SqlTranslationError',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationError'->new($_) };

declare 'RepeatedSqlTranslationError',
    as ArrayRef[SqlTranslationError()];

coerce 'RepeatedSqlTranslationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationError'->new($_) } @$_ ] };

declare 'MapStringSqlTranslationError',
    as HashRef[SqlTranslationError()];

declare 'SqlTranslationErrorType',
    as (Int | Str);

declare 'SqlTranslationWarning',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationWarning'];

coerce 'SqlTranslationWarning',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationWarning'->new($_) };

declare 'RepeatedSqlTranslationWarning',
    as ArrayRef[SqlTranslationWarning()];

coerce 'RepeatedSqlTranslationWarning',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationWarning'->new($_) } @$_ ] };

declare 'MapStringSqlTranslationWarning',
    as HashRef[SqlTranslationWarning()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
