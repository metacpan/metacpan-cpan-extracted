package Google::Appengine::V1::Certificate::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ManagementStatus',
    as (Int | Str);

declare 'AuthorizedCertificate',
    as InstanceOf['Google::Appengine::V1::Certificate::AuthorizedCertificate'];

coerce 'AuthorizedCertificate',
    from HashRef, via { 'Google::Appengine::V1::Certificate::AuthorizedCertificate'->new($_) };

declare 'RepeatedAuthorizedCertificate',
    as ArrayRef[AuthorizedCertificate()];

coerce 'RepeatedAuthorizedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Certificate::AuthorizedCertificate'->new($_) } @$_ ] };

declare 'MapStringAuthorizedCertificate',
    as HashRef[AuthorizedCertificate()];

declare 'CertificateRawData',
    as InstanceOf['Google::Appengine::V1::Certificate::CertificateRawData'];

coerce 'CertificateRawData',
    from HashRef, via { 'Google::Appengine::V1::Certificate::CertificateRawData'->new($_) };

declare 'RepeatedCertificateRawData',
    as ArrayRef[CertificateRawData()];

coerce 'RepeatedCertificateRawData',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Certificate::CertificateRawData'->new($_) } @$_ ] };

declare 'MapStringCertificateRawData',
    as HashRef[CertificateRawData()];

declare 'ManagedCertificate',
    as InstanceOf['Google::Appengine::V1::Certificate::ManagedCertificate'];

coerce 'ManagedCertificate',
    from HashRef, via { 'Google::Appengine::V1::Certificate::ManagedCertificate'->new($_) };

declare 'RepeatedManagedCertificate',
    as ArrayRef[ManagedCertificate()];

coerce 'RepeatedManagedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Certificate::ManagedCertificate'->new($_) } @$_ ] };

declare 'MapStringManagedCertificate',
    as HashRef[ManagedCertificate()];

1;

__END__

=head1 NAME

Google::Appengine::V1::Certificate::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
