package Google::Cloud::Discoveryengine::V1alpha::SessionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListFilesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesRequest'];

coerce 'ListFilesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesRequest'->new($_) };

declare 'RepeatedListFilesRequest',
    as ArrayRef[ListFilesRequest()];

coerce 'RepeatedListFilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesRequest'->new($_) } @$_ ] };

declare 'MapStringListFilesRequest',
    as HashRef[ListFilesRequest()];

declare 'ListFilesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesResponse'];

coerce 'ListFilesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesResponse'->new($_) };

declare 'RepeatedListFilesResponse',
    as ArrayRef[ListFilesResponse()];

coerce 'RepeatedListFilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SessionService::ListFilesResponse'->new($_) } @$_ ] };

declare 'MapStringListFilesResponse',
    as HashRef[ListFilesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SessionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
