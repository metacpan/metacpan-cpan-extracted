package Google::Cloud::Bigquery::Migration::V2::TranslationUsability::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GcsReportLogMessage',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationUsability::GcsReportLogMessage'];

coerce 'GcsReportLogMessage',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationUsability::GcsReportLogMessage'->new($_) };

declare 'RepeatedGcsReportLogMessage',
    as ArrayRef[GcsReportLogMessage()];

coerce 'RepeatedGcsReportLogMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationUsability::GcsReportLogMessage'->new($_) } @$_ ] };

declare 'MapStringGcsReportLogMessage',
    as HashRef[GcsReportLogMessage()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::TranslationUsability::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
