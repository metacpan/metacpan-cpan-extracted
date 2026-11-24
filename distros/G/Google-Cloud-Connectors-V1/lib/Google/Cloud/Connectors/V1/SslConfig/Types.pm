package Google::Cloud::Connectors::V1::SslConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SslType',
    as (Int | Str);

declare 'CertType',
    as (Int | Str);

declare 'SslConfigTemplate',
    as InstanceOf['Google::Cloud::Connectors::V1::SslConfig::SslConfigTemplate'];

coerce 'SslConfigTemplate',
    from HashRef, via { 'Google::Cloud::Connectors::V1::SslConfig::SslConfigTemplate'->new($_) };

declare 'RepeatedSslConfigTemplate',
    as ArrayRef[SslConfigTemplate()];

coerce 'RepeatedSslConfigTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::SslConfig::SslConfigTemplate'->new($_) } @$_ ] };

declare 'MapStringSslConfigTemplate',
    as HashRef[SslConfigTemplate()];

declare 'SslConfig',
    as InstanceOf['Google::Cloud::Connectors::V1::SslConfig::SslConfig'];

coerce 'SslConfig',
    from HashRef, via { 'Google::Cloud::Connectors::V1::SslConfig::SslConfig'->new($_) };

declare 'RepeatedSslConfig',
    as ArrayRef[SslConfig()];

coerce 'RepeatedSslConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::SslConfig::SslConfig'->new($_) } @$_ ] };

declare 'MapStringSslConfig',
    as HashRef[SslConfig()];

declare 'TrustModel',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Connectors::V1::SslConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
