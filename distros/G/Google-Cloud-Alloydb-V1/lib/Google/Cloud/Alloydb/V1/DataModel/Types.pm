package Google::Cloud::Alloydb::V1::DataModel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlResult',
    as InstanceOf['Google::Cloud::Alloydb::V1::DataModel::SqlResult'];

coerce 'SqlResult',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::DataModel::SqlResult'->new($_) };

declare 'RepeatedSqlResult',
    as ArrayRef[SqlResult()];

coerce 'RepeatedSqlResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::DataModel::SqlResult'->new($_) } @$_ ] };

declare 'MapStringSqlResult',
    as HashRef[SqlResult()];

declare 'SqlResultColumn',
    as InstanceOf['Google::Cloud::Alloydb::V1::DataModel::SqlResultColumn'];

coerce 'SqlResultColumn',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::DataModel::SqlResultColumn'->new($_) };

declare 'RepeatedSqlResultColumn',
    as ArrayRef[SqlResultColumn()];

coerce 'RepeatedSqlResultColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::DataModel::SqlResultColumn'->new($_) } @$_ ] };

declare 'MapStringSqlResultColumn',
    as HashRef[SqlResultColumn()];

declare 'SqlResultRow',
    as InstanceOf['Google::Cloud::Alloydb::V1::DataModel::SqlResultRow'];

coerce 'SqlResultRow',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::DataModel::SqlResultRow'->new($_) };

declare 'RepeatedSqlResultRow',
    as ArrayRef[SqlResultRow()];

coerce 'RepeatedSqlResultRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::DataModel::SqlResultRow'->new($_) } @$_ ] };

declare 'MapStringSqlResultRow',
    as HashRef[SqlResultRow()];

declare 'SqlResultValue',
    as InstanceOf['Google::Cloud::Alloydb::V1::DataModel::SqlResultValue'];

coerce 'SqlResultValue',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::DataModel::SqlResultValue'->new($_) };

declare 'RepeatedSqlResultValue',
    as ArrayRef[SqlResultValue()];

coerce 'RepeatedSqlResultValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::DataModel::SqlResultValue'->new($_) } @$_ ] };

declare 'MapStringSqlResultValue',
    as HashRef[SqlResultValue()];

1;

__END__

=head1 NAME

Google::Cloud::Alloydb::V1::DataModel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
