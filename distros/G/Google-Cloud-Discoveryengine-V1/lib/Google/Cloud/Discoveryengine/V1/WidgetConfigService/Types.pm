package Google::Cloud::Discoveryengine::V1::WidgetConfigService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetWidgetConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest'];

coerce 'GetWidgetConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest'->new($_) };

declare 'RepeatedGetWidgetConfigRequest',
    as ArrayRef[GetWidgetConfigRequest()];

coerce 'RepeatedGetWidgetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetWidgetConfigRequest',
    as HashRef[GetWidgetConfigRequest()];

declare 'GetWidgetConfigRequestOption',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest::GetWidgetConfigRequestOption'];

coerce 'GetWidgetConfigRequestOption',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest::GetWidgetConfigRequestOption'->new($_) };

declare 'RepeatedGetWidgetConfigRequestOption',
    as ArrayRef[GetWidgetConfigRequestOption()];

coerce 'RepeatedGetWidgetConfigRequestOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest::GetWidgetConfigRequestOption'->new($_) } @$_ ] };

declare 'MapStringGetWidgetConfigRequestOption',
    as HashRef[GetWidgetConfigRequestOption()];

declare 'UpdateWidgetConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfigService::UpdateWidgetConfigRequest'];

coerce 'UpdateWidgetConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfigService::UpdateWidgetConfigRequest'->new($_) };

declare 'RepeatedUpdateWidgetConfigRequest',
    as ArrayRef[UpdateWidgetConfigRequest()];

coerce 'RepeatedUpdateWidgetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfigService::UpdateWidgetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWidgetConfigRequest',
    as HashRef[UpdateWidgetConfigRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::WidgetConfigService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
