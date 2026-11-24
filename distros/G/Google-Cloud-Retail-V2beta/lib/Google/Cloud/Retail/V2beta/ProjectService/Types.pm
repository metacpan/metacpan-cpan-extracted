package Google::Cloud::Retail::V2beta::ProjectService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetAlertConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest'];

coerce 'GetAlertConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest'->new($_) };

declare 'RepeatedGetAlertConfigRequest',
    as ArrayRef[GetAlertConfigRequest()];

coerce 'RepeatedGetAlertConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAlertConfigRequest',
    as HashRef[GetAlertConfigRequest()];

declare 'UpdateAlertConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2beta::ProjectService::UpdateAlertConfigRequest'];

coerce 'UpdateAlertConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::ProjectService::UpdateAlertConfigRequest'->new($_) };

declare 'RepeatedUpdateAlertConfigRequest',
    as ArrayRef[UpdateAlertConfigRequest()];

coerce 'RepeatedUpdateAlertConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::ProjectService::UpdateAlertConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAlertConfigRequest',
    as HashRef[UpdateAlertConfigRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2beta::ProjectService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
