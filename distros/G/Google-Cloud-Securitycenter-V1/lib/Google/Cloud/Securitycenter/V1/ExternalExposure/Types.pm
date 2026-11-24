package Google::Cloud::Securitycenter::V1::ExternalExposure::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExternalExposure',
    as InstanceOf['Google::Cloud::Securitycenter::V1::ExternalExposure::ExternalExposure'];

coerce 'ExternalExposure',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::ExternalExposure::ExternalExposure'->new($_) };

declare 'RepeatedExternalExposure',
    as ArrayRef[ExternalExposure()];

coerce 'RepeatedExternalExposure',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::ExternalExposure::ExternalExposure'->new($_) } @$_ ] };

declare 'MapStringExternalExposure',
    as HashRef[ExternalExposure()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::ExternalExposure::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
