package Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoogleApiSourceActivity',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity'];

coerce 'GoogleApiSourceActivity',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity'->new($_) };

declare 'RepeatedGoogleApiSourceActivity',
    as ArrayRef[GoogleApiSourceActivity()];

coerce 'RepeatedGoogleApiSourceActivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity'->new($_) } @$_ ] };

declare 'MapStringGoogleApiSourceActivity',
    as HashRef[GoogleApiSourceActivity()];

declare 'Published',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity::Published'];

coerce 'Published',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity::Published'->new($_) };

declare 'RepeatedPublished',
    as ArrayRef[Published()];

coerce 'RepeatedPublished',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity::Published'->new($_) } @$_ ] };

declare 'MapStringPublished',
    as HashRef[Published()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
