package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticTablePrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::StaticTablePrompt'];

coerce 'StaticTablePrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::StaticTablePrompt'->new($_) };

declare 'RepeatedStaticTablePrompt',
    as ArrayRef[StaticTablePrompt()];

coerce 'RepeatedStaticTablePrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::StaticTablePrompt'->new($_) } @$_ ] };

declare 'MapStringStaticTablePrompt',
    as HashRef[StaticTablePrompt()];

declare 'TableColumn',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableColumn'];

coerce 'TableColumn',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableColumn'->new($_) };

declare 'RepeatedTableColumn',
    as ArrayRef[TableColumn()];

coerce 'RepeatedTableColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableColumn'->new($_) } @$_ ] };

declare 'MapStringTableColumn',
    as HashRef[TableColumn()];

declare 'HorizontalAlignment',
    as (Int | Str);

declare 'TableCell',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableCell'];

coerce 'TableCell',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableCell'->new($_) };

declare 'RepeatedTableCell',
    as ArrayRef[TableCell()];

coerce 'RepeatedTableCell',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableCell'->new($_) } @$_ ] };

declare 'MapStringTableCell',
    as HashRef[TableCell()];

declare 'TableRow',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableRow'];

coerce 'TableRow',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableRow'->new($_) };

declare 'RepeatedTableRow',
    as ArrayRef[TableRow()];

coerce 'RepeatedTableRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::TableRow'->new($_) } @$_ ] };

declare 'MapStringTableRow',
    as HashRef[TableRow()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
