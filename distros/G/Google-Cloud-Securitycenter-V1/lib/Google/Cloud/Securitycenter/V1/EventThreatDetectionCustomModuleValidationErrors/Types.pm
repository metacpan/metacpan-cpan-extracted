package Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CustomModuleValidationErrors',
    as InstanceOf['Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationErrors'];

coerce 'CustomModuleValidationErrors',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationErrors'->new($_) };

declare 'RepeatedCustomModuleValidationErrors',
    as ArrayRef[CustomModuleValidationErrors()];

coerce 'RepeatedCustomModuleValidationErrors',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationErrors'->new($_) } @$_ ] };

declare 'MapStringCustomModuleValidationErrors',
    as HashRef[CustomModuleValidationErrors()];

declare 'CustomModuleValidationError',
    as InstanceOf['Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationError'];

coerce 'CustomModuleValidationError',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationError'->new($_) };

declare 'RepeatedCustomModuleValidationError',
    as ArrayRef[CustomModuleValidationError()];

coerce 'RepeatedCustomModuleValidationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::CustomModuleValidationError'->new($_) } @$_ ] };

declare 'MapStringCustomModuleValidationError',
    as HashRef[CustomModuleValidationError()];

declare 'Position',
    as InstanceOf['Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::Position'];

coerce 'Position',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::Position'->new($_) };

declare 'RepeatedPosition',
    as ArrayRef[Position()];

coerce 'RepeatedPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::Position'->new($_) } @$_ ] };

declare 'MapStringPosition',
    as HashRef[Position()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModuleValidationErrors::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
