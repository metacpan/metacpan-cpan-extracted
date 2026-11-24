package Google::Cloud::Eventarc::V1::Channel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Channel',
    as InstanceOf['Google::Cloud::Eventarc::V1::Channel::Channel'];

coerce 'Channel',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Channel::Channel'->new($_) };

declare 'RepeatedChannel',
    as ArrayRef[Channel()];

coerce 'RepeatedChannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Channel::Channel'->new($_) } @$_ ] };

declare 'MapStringChannel',
    as HashRef[Channel()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Eventarc::V1::Channel::Channel::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Channel::Channel::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Channel::Channel::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::Channel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
