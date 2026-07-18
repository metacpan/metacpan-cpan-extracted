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

package Google::Cloud::Bigquery::V2::Bqml::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ModelDefinition',
    as InstanceOf['Google::Cloud::Bigquery::V2::Bqml::ModelDefinition'];

coerce 'ModelDefinition',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Bqml::ModelDefinition'->new($_) };

declare 'RepeatedModelDefinition',
    as ArrayRef[ModelDefinition()];

coerce 'RepeatedModelDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Bqml::ModelDefinition'->new($_) } @$_ ] };

declare 'MapStringModelDefinition',
    as HashRef[ModelDefinition()];

declare 'ModelOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::Bqml::ModelOptions'];

coerce 'ModelOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Bqml::ModelOptions'->new($_) };

declare 'RepeatedModelOptions',
    as ArrayRef[ModelOptions()];

coerce 'RepeatedModelOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Bqml::ModelOptions'->new($_) } @$_ ] };

declare 'MapStringModelOptions',
    as HashRef[ModelOptions()];

declare 'BqmlTrainingRun',
    as InstanceOf['Google::Cloud::Bigquery::V2::Bqml::BqmlTrainingRun'];

coerce 'BqmlTrainingRun',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Bqml::BqmlTrainingRun'->new($_) };

declare 'RepeatedBqmlTrainingRun',
    as ArrayRef[BqmlTrainingRun()];

coerce 'RepeatedBqmlTrainingRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Bqml::BqmlTrainingRun'->new($_) } @$_ ] };

declare 'MapStringBqmlTrainingRun',
    as HashRef[BqmlTrainingRun()];

declare 'BqmlTrainingOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::Bqml::BqmlTrainingOptions'];

coerce 'BqmlTrainingOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Bqml::BqmlTrainingOptions'->new($_) };

declare 'RepeatedBqmlTrainingOptions',
    as ArrayRef[BqmlTrainingOptions()];

coerce 'RepeatedBqmlTrainingOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Bqml::BqmlTrainingOptions'->new($_) } @$_ ] };

declare 'MapStringBqmlTrainingOptions',
    as HashRef[BqmlTrainingOptions()];

declare 'BqmlIterationResult',
    as InstanceOf['Google::Cloud::Bigquery::V2::Bqml::BqmlIterationResult'];

coerce 'BqmlIterationResult',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Bqml::BqmlIterationResult'->new($_) };

declare 'RepeatedBqmlIterationResult',
    as ArrayRef[BqmlIterationResult()];

coerce 'RepeatedBqmlIterationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Bqml::BqmlIterationResult'->new($_) } @$_ ] };

declare 'MapStringBqmlIterationResult',
    as HashRef[BqmlIterationResult()];

1;
