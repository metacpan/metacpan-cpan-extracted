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

package Google::Cloud::Bigquery::V2::Clustering::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Clustering',
    as InstanceOf['Google::Cloud::Bigquery::V2::Clustering::Clustering'];

coerce 'Clustering',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Clustering::Clustering'->new($_) };

declare 'RepeatedClustering',
    as ArrayRef[Clustering()];

coerce 'RepeatedClustering',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Clustering::Clustering'->new($_) } @$_ ] };

declare 'MapStringClustering',
    as HashRef[Clustering()];

1;
