package Google::Cloud::Dataplex::V1::Security::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResourceAccessSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Security::ResourceAccessSpec'];

coerce 'ResourceAccessSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Security::ResourceAccessSpec'->new($_) };

declare 'RepeatedResourceAccessSpec',
    as ArrayRef[ResourceAccessSpec()];

coerce 'RepeatedResourceAccessSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Security::ResourceAccessSpec'->new($_) } @$_ ] };

declare 'MapStringResourceAccessSpec',
    as HashRef[ResourceAccessSpec()];

declare 'DataAccessSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Security::DataAccessSpec'];

coerce 'DataAccessSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Security::DataAccessSpec'->new($_) };

declare 'RepeatedDataAccessSpec',
    as ArrayRef[DataAccessSpec()];

coerce 'RepeatedDataAccessSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Security::DataAccessSpec'->new($_) } @$_ ] };

declare 'MapStringDataAccessSpec',
    as HashRef[DataAccessSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Security::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
