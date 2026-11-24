package Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EnrollmentActivity',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity'];

coerce 'EnrollmentActivity',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity'->new($_) };

declare 'RepeatedEnrollmentActivity',
    as ArrayRef[EnrollmentActivity()];

coerce 'RepeatedEnrollmentActivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity'->new($_) } @$_ ] };

declare 'MapStringEnrollmentActivity',
    as HashRef[EnrollmentActivity()];

declare 'Matched',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity::Matched'];

coerce 'Matched',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity::Matched'->new($_) };

declare 'RepeatedMatched',
    as ArrayRef[Matched()];

coerce 'RepeatedMatched',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity::Matched'->new($_) } @$_ ] };

declare 'MapStringMatched',
    as HashRef[Matched()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::EnrollmentActivity::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::Logging::V1::EnrollmentActivity::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
