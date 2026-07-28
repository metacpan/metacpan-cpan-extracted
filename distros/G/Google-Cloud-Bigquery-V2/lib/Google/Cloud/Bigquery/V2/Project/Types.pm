package Google::Cloud::Bigquery::V2::Project::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetServiceAccountRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest'];

coerce 'GetServiceAccountRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest'->new($_) };

declare 'RepeatedGetServiceAccountRequest',
    as ArrayRef[GetServiceAccountRequest()];

coerce 'RepeatedGetServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceAccountRequest',
    as HashRef[GetServiceAccountRequest()];

declare 'GetServiceAccountResponse',
    as InstanceOf['Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse'];

coerce 'GetServiceAccountResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse'->new($_) };

declare 'RepeatedGetServiceAccountResponse',
    as ArrayRef[GetServiceAccountResponse()];

coerce 'RepeatedGetServiceAccountResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse'->new($_) } @$_ ] };

declare 'MapStringGetServiceAccountResponse',
    as HashRef[GetServiceAccountResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::Project::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
