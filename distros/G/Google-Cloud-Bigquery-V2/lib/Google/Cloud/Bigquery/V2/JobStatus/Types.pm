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

package Google::Cloud::Bigquery::V2::JobStatus::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobStatus',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStatus::JobStatus'];

coerce 'JobStatus',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStatus::JobStatus'->new($_) };

declare 'RepeatedJobStatus',
    as ArrayRef[JobStatus()];

coerce 'RepeatedJobStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStatus::JobStatus'->new($_) } @$_ ] };

declare 'MapStringJobStatus',
    as HashRef[JobStatus()];

declare 'ContinuousJobStatus',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStatus::ContinuousJobStatus'];

coerce 'ContinuousJobStatus',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStatus::ContinuousJobStatus'->new($_) };

declare 'RepeatedContinuousJobStatus',
    as ArrayRef[ContinuousJobStatus()];

coerce 'RepeatedContinuousJobStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStatus::ContinuousJobStatus'->new($_) } @$_ ] };

declare 'MapStringContinuousJobStatus',
    as HashRef[ContinuousJobStatus()];

1;
