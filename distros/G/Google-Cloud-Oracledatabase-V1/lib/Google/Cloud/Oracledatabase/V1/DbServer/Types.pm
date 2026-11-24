package Google::Cloud::Oracledatabase::V1::DbServer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DbServer',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbServer::DbServer'];

coerce 'DbServer',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbServer::DbServer'->new($_) };

declare 'RepeatedDbServer',
    as ArrayRef[DbServer()];

coerce 'RepeatedDbServer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbServer::DbServer'->new($_) } @$_ ] };

declare 'MapStringDbServer',
    as HashRef[DbServer()];

declare 'DbServerProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbServer::DbServerProperties'];

coerce 'DbServerProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbServer::DbServerProperties'->new($_) };

declare 'RepeatedDbServerProperties',
    as ArrayRef[DbServerProperties()];

coerce 'RepeatedDbServerProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbServer::DbServerProperties'->new($_) } @$_ ] };

declare 'MapStringDbServerProperties',
    as HashRef[DbServerProperties()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbServer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
