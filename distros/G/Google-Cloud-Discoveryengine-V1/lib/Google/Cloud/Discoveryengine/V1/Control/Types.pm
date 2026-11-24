package Google::Cloud::Discoveryengine::V1::Control::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Condition',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'QueryTerm',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Condition::QueryTerm'];

coerce 'QueryTerm',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Condition::QueryTerm'->new($_) };

declare 'RepeatedQueryTerm',
    as ArrayRef[QueryTerm()];

coerce 'RepeatedQueryTerm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Condition::QueryTerm'->new($_) } @$_ ] };

declare 'MapStringQueryTerm',
    as HashRef[QueryTerm()];

declare 'TimeRange',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Condition::TimeRange'];

coerce 'TimeRange',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Condition::TimeRange'->new($_) };

declare 'RepeatedTimeRange',
    as ArrayRef[TimeRange()];

coerce 'RepeatedTimeRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Condition::TimeRange'->new($_) } @$_ ] };

declare 'MapStringTimeRange',
    as HashRef[TimeRange()];

declare 'Control',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Control'];

coerce 'Control',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Control'->new($_) };

declare 'RepeatedControl',
    as ArrayRef[Control()];

coerce 'RepeatedControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Control'->new($_) } @$_ ] };

declare 'MapStringControl',
    as HashRef[Control()];

declare 'BoostAction',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Control::BoostAction'];

coerce 'BoostAction',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Control::BoostAction'->new($_) };

declare 'RepeatedBoostAction',
    as ArrayRef[BoostAction()];

coerce 'RepeatedBoostAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Control::BoostAction'->new($_) } @$_ ] };

declare 'MapStringBoostAction',
    as HashRef[BoostAction()];

declare 'InterpolationBoostSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Control::BoostAction::InterpolationBoostSpec'];

coerce 'InterpolationBoostSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Control::BoostAction::InterpolationBoostSpec'->new($_) };

declare 'RepeatedInterpolationBoostSpec',
    as ArrayRef[InterpolationBoostSpec()];

coerce 'RepeatedInterpolationBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Control::BoostAction::InterpolationBoostSpec'->new($_) } @$_ ] };

declare 'MapStringInterpolationBoostSpec',
    as HashRef[InterpolationBoostSpec()];

declare 'AttributeType',
    as (Int | Str);

declare 'InterpolationType',
    as (Int | Str);

declare 'ControlPoint',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Control::BoostAction::InterpolationBoostSpec::ControlPoint'];

coerce 'ControlPoint',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Control::BoostAction::InterpolationBoostSpec::ControlPoint'->new($_) };

declare 'RepeatedControlPoint',
    as ArrayRef[ControlPoint()];

coerce 'RepeatedControlPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Control::BoostAction::InterpolationBoostSpec::ControlPoint'->new($_) } @$_ ] };

declare 'MapStringControlPoint',
    as HashRef[ControlPoint()];

declare 'FilterAction',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Control::FilterAction'];

coerce 'FilterAction',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Control::FilterAction'->new($_) };

declare 'RepeatedFilterAction',
    as ArrayRef[FilterAction()];

coerce 'RepeatedFilterAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Control::FilterAction'->new($_) } @$_ ] };

declare 'MapStringFilterAction',
    as HashRef[FilterAction()];

declare 'RedirectAction',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Control::RedirectAction'];

coerce 'RedirectAction',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Control::RedirectAction'->new($_) };

declare 'RepeatedRedirectAction',
    as ArrayRef[RedirectAction()];

coerce 'RepeatedRedirectAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Control::RedirectAction'->new($_) } @$_ ] };

declare 'MapStringRedirectAction',
    as HashRef[RedirectAction()];

declare 'SynonymsAction',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Control::SynonymsAction'];

coerce 'SynonymsAction',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Control::SynonymsAction'->new($_) };

declare 'RepeatedSynonymsAction',
    as ArrayRef[SynonymsAction()];

coerce 'RepeatedSynonymsAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Control::SynonymsAction'->new($_) } @$_ ] };

declare 'MapStringSynonymsAction',
    as HashRef[SynonymsAction()];

declare 'PromoteAction',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Control::Control::PromoteAction'];

coerce 'PromoteAction',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Control::Control::PromoteAction'->new($_) };

declare 'RepeatedPromoteAction',
    as ArrayRef[PromoteAction()];

coerce 'RepeatedPromoteAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Control::Control::PromoteAction'->new($_) } @$_ ] };

declare 'MapStringPromoteAction',
    as HashRef[PromoteAction()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::Control::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
