package Google::Cloud::Networksecurity::V1::Tls::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GrpcEndpoint',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Tls::GrpcEndpoint'];

coerce 'GrpcEndpoint',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Tls::GrpcEndpoint'->new($_) };

declare 'RepeatedGrpcEndpoint',
    as ArrayRef[GrpcEndpoint()];

coerce 'RepeatedGrpcEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Tls::GrpcEndpoint'->new($_) } @$_ ] };

declare 'MapStringGrpcEndpoint',
    as HashRef[GrpcEndpoint()];

declare 'ValidationCA',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Tls::ValidationCA'];

coerce 'ValidationCA',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Tls::ValidationCA'->new($_) };

declare 'RepeatedValidationCA',
    as ArrayRef[ValidationCA()];

coerce 'RepeatedValidationCA',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Tls::ValidationCA'->new($_) } @$_ ] };

declare 'MapStringValidationCA',
    as HashRef[ValidationCA()];

declare 'CertificateProviderInstance',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Tls::CertificateProviderInstance'];

coerce 'CertificateProviderInstance',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Tls::CertificateProviderInstance'->new($_) };

declare 'RepeatedCertificateProviderInstance',
    as ArrayRef[CertificateProviderInstance()];

coerce 'RepeatedCertificateProviderInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Tls::CertificateProviderInstance'->new($_) } @$_ ] };

declare 'MapStringCertificateProviderInstance',
    as HashRef[CertificateProviderInstance()];

declare 'CertificateProvider',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Tls::CertificateProvider'];

coerce 'CertificateProvider',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Tls::CertificateProvider'->new($_) };

declare 'RepeatedCertificateProvider',
    as ArrayRef[CertificateProvider()];

coerce 'RepeatedCertificateProvider',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Tls::CertificateProvider'->new($_) } @$_ ] };

declare 'MapStringCertificateProvider',
    as HashRef[CertificateProvider()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::Tls::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
