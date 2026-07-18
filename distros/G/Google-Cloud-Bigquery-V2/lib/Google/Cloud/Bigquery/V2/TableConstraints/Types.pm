# Copyright (C) 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Cloud::Bigquery::V2::TableConstraints::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PrimaryKey',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableConstraints::PrimaryKey'];

coerce 'PrimaryKey',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableConstraints::PrimaryKey'->new($_) };

declare 'RepeatedPrimaryKey',
    as ArrayRef[PrimaryKey()];

coerce 'RepeatedPrimaryKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableConstraints::PrimaryKey'->new($_) } @$_ ] };

declare 'MapStringPrimaryKey',
    as HashRef[PrimaryKey()];

declare 'ColumnReference',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableConstraints::ColumnReference'];

coerce 'ColumnReference',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableConstraints::ColumnReference'->new($_) };

declare 'RepeatedColumnReference',
    as ArrayRef[ColumnReference()];

coerce 'RepeatedColumnReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableConstraints::ColumnReference'->new($_) } @$_ ] };

declare 'MapStringColumnReference',
    as HashRef[ColumnReference()];

declare 'ForeignKey',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableConstraints::ForeignKey'];

coerce 'ForeignKey',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableConstraints::ForeignKey'->new($_) };

declare 'RepeatedForeignKey',
    as ArrayRef[ForeignKey()];

coerce 'RepeatedForeignKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableConstraints::ForeignKey'->new($_) } @$_ ] };

declare 'MapStringForeignKey',
    as HashRef[ForeignKey()];

declare 'TableConstraints',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableConstraints::TableConstraints'];

coerce 'TableConstraints',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableConstraints::TableConstraints'->new($_) };

declare 'RepeatedTableConstraints',
    as ArrayRef[TableConstraints()];

coerce 'RepeatedTableConstraints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableConstraints::TableConstraints'->new($_) } @$_ ] };

declare 'MapStringTableConstraints',
    as HashRef[TableConstraints()];

1;
