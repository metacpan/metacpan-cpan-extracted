package Google::Cloud::Security::Publicca::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateExternalAccountKeyRequest',
    as InstanceOf['Google::Cloud::Security::Publicca::V1::Service::CreateExternalAccountKeyRequest'];

coerce 'CreateExternalAccountKeyRequest',
    from HashRef, via { 'Google::Cloud::Security::Publicca::V1::Service::CreateExternalAccountKeyRequest'->new($_) };

declare 'RepeatedCreateExternalAccountKeyRequest',
    as ArrayRef[CreateExternalAccountKeyRequest()];

coerce 'RepeatedCreateExternalAccountKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Publicca::V1::Service::CreateExternalAccountKeyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExternalAccountKeyRequest',
    as HashRef[CreateExternalAccountKeyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Security::Publicca::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
