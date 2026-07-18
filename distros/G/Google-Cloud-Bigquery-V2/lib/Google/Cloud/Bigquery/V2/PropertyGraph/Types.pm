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

package Google::Cloud::Bigquery::V2::PropertyGraph::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PropertyGraph',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::PropertyGraph'];

coerce 'PropertyGraph',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::PropertyGraph'->new($_) };

declare 'RepeatedPropertyGraph',
    as ArrayRef[PropertyGraph()];

coerce 'RepeatedPropertyGraph',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::PropertyGraph'->new($_) } @$_ ] };

declare 'MapStringPropertyGraph',
    as HashRef[PropertyGraph()];

declare 'View',
    as (Int | Str);

declare 'PropertyGraphElementTable',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::PropertyGraphElementTable'];

coerce 'PropertyGraphElementTable',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::PropertyGraphElementTable'->new($_) };

declare 'RepeatedPropertyGraphElementTable',
    as ArrayRef[PropertyGraphElementTable()];

coerce 'RepeatedPropertyGraphElementTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::PropertyGraphElementTable'->new($_) } @$_ ] };

declare 'MapStringPropertyGraphElementTable',
    as HashRef[PropertyGraphElementTable()];

declare 'NodeReference',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::NodeReference'];

coerce 'NodeReference',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::NodeReference'->new($_) };

declare 'RepeatedNodeReference',
    as ArrayRef[NodeReference()];

coerce 'RepeatedNodeReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::NodeReference'->new($_) } @$_ ] };

declare 'MapStringNodeReference',
    as HashRef[NodeReference()];

declare 'LabelAndProperties',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::LabelAndProperties'];

coerce 'LabelAndProperties',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::LabelAndProperties'->new($_) };

declare 'RepeatedLabelAndProperties',
    as ArrayRef[LabelAndProperties()];

coerce 'RepeatedLabelAndProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::LabelAndProperties'->new($_) } @$_ ] };

declare 'MapStringLabelAndProperties',
    as HashRef[LabelAndProperties()];

declare 'LabelInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::LabelInfo'];

coerce 'LabelInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::LabelInfo'->new($_) };

declare 'RepeatedLabelInfo',
    as ArrayRef[LabelInfo()];

coerce 'RepeatedLabelInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::LabelInfo'->new($_) } @$_ ] };

declare 'MapStringLabelInfo',
    as HashRef[LabelInfo()];

declare 'Property',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::Property'];

coerce 'Property',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::Property'->new($_) };

declare 'RepeatedProperty',
    as ArrayRef[Property()];

coerce 'RepeatedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::Property'->new($_) } @$_ ] };

declare 'MapStringProperty',
    as HashRef[Property()];

declare 'ExpressionKind',
    as (Int | Str);

declare 'PropertyInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::PropertyInfo'];

coerce 'PropertyInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::PropertyInfo'->new($_) };

declare 'RepeatedPropertyInfo',
    as ArrayRef[PropertyInfo()];

coerce 'RepeatedPropertyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::PropertyInfo'->new($_) } @$_ ] };

declare 'MapStringPropertyInfo',
    as HashRef[PropertyInfo()];

declare 'SemanticGraphAttributes',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::SemanticGraphAttributes'];

coerce 'SemanticGraphAttributes',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::SemanticGraphAttributes'->new($_) };

declare 'RepeatedSemanticGraphAttributes',
    as ArrayRef[SemanticGraphAttributes()];

coerce 'RepeatedSemanticGraphAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::SemanticGraphAttributes'->new($_) } @$_ ] };

declare 'MapStringSemanticGraphAttributes',
    as HashRef[SemanticGraphAttributes()];

declare 'FlattenedView',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::FlattenedView'];

coerce 'FlattenedView',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::FlattenedView'->new($_) };

declare 'RepeatedFlattenedView',
    as ArrayRef[FlattenedView()];

coerce 'RepeatedFlattenedView',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::FlattenedView'->new($_) } @$_ ] };

declare 'MapStringFlattenedView',
    as HashRef[FlattenedView()];

declare 'FlattenedViewError',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::FlattenedViewError'];

coerce 'FlattenedViewError',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::FlattenedViewError'->new($_) };

declare 'RepeatedFlattenedViewError',
    as ArrayRef[FlattenedViewError()];

coerce 'RepeatedFlattenedViewError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::FlattenedViewError'->new($_) } @$_ ] };

declare 'MapStringFlattenedViewError',
    as HashRef[FlattenedViewError()];

declare 'GetPropertyGraphRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::GetPropertyGraphRequest'];

coerce 'GetPropertyGraphRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::GetPropertyGraphRequest'->new($_) };

declare 'RepeatedGetPropertyGraphRequest',
    as ArrayRef[GetPropertyGraphRequest()];

coerce 'RepeatedGetPropertyGraphRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::GetPropertyGraphRequest'->new($_) } @$_ ] };

declare 'MapStringGetPropertyGraphRequest',
    as HashRef[GetPropertyGraphRequest()];

declare 'DeletePropertyGraphRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::DeletePropertyGraphRequest'];

coerce 'DeletePropertyGraphRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::DeletePropertyGraphRequest'->new($_) };

declare 'RepeatedDeletePropertyGraphRequest',
    as ArrayRef[DeletePropertyGraphRequest()];

coerce 'RepeatedDeletePropertyGraphRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::DeletePropertyGraphRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePropertyGraphRequest',
    as HashRef[DeletePropertyGraphRequest()];

declare 'ListPropertyGraphsRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsRequest'];

coerce 'ListPropertyGraphsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsRequest'->new($_) };

declare 'RepeatedListPropertyGraphsRequest',
    as ArrayRef[ListPropertyGraphsRequest()];

coerce 'RepeatedListPropertyGraphsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsRequest'->new($_) } @$_ ] };

declare 'MapStringListPropertyGraphsRequest',
    as HashRef[ListPropertyGraphsRequest()];

declare 'ListPropertyGraphsResponse',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsResponse'];

coerce 'ListPropertyGraphsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsResponse'->new($_) };

declare 'RepeatedListPropertyGraphsResponse',
    as ArrayRef[ListPropertyGraphsResponse()];

coerce 'RepeatedListPropertyGraphsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsResponse'->new($_) } @$_ ] };

declare 'MapStringListPropertyGraphsResponse',
    as HashRef[ListPropertyGraphsResponse()];

1;
