package Google::Cloud::Servicedirectory::V1beta1::LookupService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResolveServiceRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceRequest'];

coerce 'ResolveServiceRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceRequest'->new($_) };

declare 'RepeatedResolveServiceRequest',
    as ArrayRef[ResolveServiceRequest()];

coerce 'RepeatedResolveServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceRequest'->new($_) } @$_ ] };

declare 'MapStringResolveServiceRequest',
    as HashRef[ResolveServiceRequest()];

declare 'ResolveServiceResponse',
    as InstanceOf['Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceResponse'];

coerce 'ResolveServiceResponse',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceResponse'->new($_) };

declare 'RepeatedResolveServiceResponse',
    as ArrayRef[ResolveServiceResponse()];

coerce 'RepeatedResolveServiceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1beta1::LookupService::ResolveServiceResponse'->new($_) } @$_ ] };

declare 'MapStringResolveServiceResponse',
    as HashRef[ResolveServiceResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Servicedirectory::V1beta1::LookupService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
