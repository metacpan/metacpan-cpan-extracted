package Google::Cloud::Retail::V2alpha::BranchService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListBranchesRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::BranchService::ListBranchesRequest'];

coerce 'ListBranchesRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::BranchService::ListBranchesRequest'->new($_) };

declare 'RepeatedListBranchesRequest',
    as ArrayRef[ListBranchesRequest()];

coerce 'RepeatedListBranchesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::BranchService::ListBranchesRequest'->new($_) } @$_ ] };

declare 'MapStringListBranchesRequest',
    as HashRef[ListBranchesRequest()];

declare 'ListBranchesResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::BranchService::ListBranchesResponse'];

coerce 'ListBranchesResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::BranchService::ListBranchesResponse'->new($_) };

declare 'RepeatedListBranchesResponse',
    as ArrayRef[ListBranchesResponse()];

coerce 'RepeatedListBranchesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::BranchService::ListBranchesResponse'->new($_) } @$_ ] };

declare 'MapStringListBranchesResponse',
    as HashRef[ListBranchesResponse()];

declare 'GetBranchRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::BranchService::GetBranchRequest'];

coerce 'GetBranchRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::BranchService::GetBranchRequest'->new($_) };

declare 'RepeatedGetBranchRequest',
    as ArrayRef[GetBranchRequest()];

coerce 'RepeatedGetBranchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::BranchService::GetBranchRequest'->new($_) } @$_ ] };

declare 'MapStringGetBranchRequest',
    as HashRef[GetBranchRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::BranchService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
