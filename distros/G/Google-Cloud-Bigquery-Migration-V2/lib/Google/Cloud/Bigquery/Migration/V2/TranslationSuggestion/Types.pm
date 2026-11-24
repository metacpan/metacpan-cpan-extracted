package Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TranslationReportRecord',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion::TranslationReportRecord'];

coerce 'TranslationReportRecord',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion::TranslationReportRecord'->new($_) };

declare 'RepeatedTranslationReportRecord',
    as ArrayRef[TranslationReportRecord()];

coerce 'RepeatedTranslationReportRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion::TranslationReportRecord'->new($_) } @$_ ] };

declare 'MapStringTranslationReportRecord',
    as HashRef[TranslationReportRecord()];

declare 'Severity',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
