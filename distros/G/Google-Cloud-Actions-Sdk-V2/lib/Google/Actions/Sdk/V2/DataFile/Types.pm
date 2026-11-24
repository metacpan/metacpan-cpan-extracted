package Google::Actions::Sdk::V2::DataFile::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataFiles',
    as InstanceOf['Google::Actions::Sdk::V2::DataFile::DataFiles'];

coerce 'DataFiles',
    from HashRef, via { 'Google::Actions::Sdk::V2::DataFile::DataFiles'->new($_) };

declare 'RepeatedDataFiles',
    as ArrayRef[DataFiles()];

coerce 'RepeatedDataFiles',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::DataFile::DataFiles'->new($_) } @$_ ] };

declare 'MapStringDataFiles',
    as HashRef[DataFiles()];

declare 'DataFile',
    as InstanceOf['Google::Actions::Sdk::V2::DataFile::DataFile'];

coerce 'DataFile',
    from HashRef, via { 'Google::Actions::Sdk::V2::DataFile::DataFile'->new($_) };

declare 'RepeatedDataFile',
    as ArrayRef[DataFile()];

coerce 'RepeatedDataFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::DataFile::DataFile'->new($_) } @$_ ] };

declare 'MapStringDataFile',
    as HashRef[DataFile()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::DataFile::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
