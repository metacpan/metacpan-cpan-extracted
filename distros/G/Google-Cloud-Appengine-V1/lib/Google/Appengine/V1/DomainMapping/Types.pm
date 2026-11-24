package Google::Appengine::V1::DomainMapping::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DomainMapping',
    as InstanceOf['Google::Appengine::V1::DomainMapping::DomainMapping'];

coerce 'DomainMapping',
    from HashRef, via { 'Google::Appengine::V1::DomainMapping::DomainMapping'->new($_) };

declare 'RepeatedDomainMapping',
    as ArrayRef[DomainMapping()];

coerce 'RepeatedDomainMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::DomainMapping::DomainMapping'->new($_) } @$_ ] };

declare 'MapStringDomainMapping',
    as HashRef[DomainMapping()];

declare 'SslSettings',
    as InstanceOf['Google::Appengine::V1::DomainMapping::SslSettings'];

coerce 'SslSettings',
    from HashRef, via { 'Google::Appengine::V1::DomainMapping::SslSettings'->new($_) };

declare 'RepeatedSslSettings',
    as ArrayRef[SslSettings()];

coerce 'RepeatedSslSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::DomainMapping::SslSettings'->new($_) } @$_ ] };

declare 'MapStringSslSettings',
    as HashRef[SslSettings()];

declare 'SslManagementType',
    as (Int | Str);

declare 'ResourceRecord',
    as InstanceOf['Google::Appengine::V1::DomainMapping::ResourceRecord'];

coerce 'ResourceRecord',
    from HashRef, via { 'Google::Appengine::V1::DomainMapping::ResourceRecord'->new($_) };

declare 'RepeatedResourceRecord',
    as ArrayRef[ResourceRecord()];

coerce 'RepeatedResourceRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::DomainMapping::ResourceRecord'->new($_) } @$_ ] };

declare 'MapStringResourceRecord',
    as HashRef[ResourceRecord()];

declare 'RecordType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Appengine::V1::DomainMapping::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
