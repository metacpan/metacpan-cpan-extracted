package Google::Cloud::Ces::V1::WidgetService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenerateChatTokenRequest',
    as InstanceOf['Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenRequest'];

coerce 'GenerateChatTokenRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenRequest'->new($_) };

declare 'RepeatedGenerateChatTokenRequest',
    as ArrayRef[GenerateChatTokenRequest()];

coerce 'RepeatedGenerateChatTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateChatTokenRequest',
    as HashRef[GenerateChatTokenRequest()];

declare 'GenerateChatTokenResponse',
    as InstanceOf['Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenResponse'];

coerce 'GenerateChatTokenResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenResponse'->new($_) };

declare 'RepeatedGenerateChatTokenResponse',
    as ArrayRef[GenerateChatTokenResponse()];

coerce 'RepeatedGenerateChatTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::WidgetService::GenerateChatTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateChatTokenResponse',
    as HashRef[GenerateChatTokenResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::WidgetService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
