package Google::Cloud::Certificatemanager::Logging::V1::Logs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CertificatesExpiry',
    as InstanceOf['Google::Cloud::Certificatemanager::Logging::V1::Logs::CertificatesExpiry'];

coerce 'CertificatesExpiry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::Logging::V1::Logs::CertificatesExpiry'->new($_) };

declare 'RepeatedCertificatesExpiry',
    as ArrayRef[CertificatesExpiry()];

coerce 'RepeatedCertificatesExpiry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::Logging::V1::Logs::CertificatesExpiry'->new($_) } @$_ ] };

declare 'MapStringCertificatesExpiry',
    as HashRef[CertificatesExpiry()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Certificatemanager::Logging::V1::Logs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
