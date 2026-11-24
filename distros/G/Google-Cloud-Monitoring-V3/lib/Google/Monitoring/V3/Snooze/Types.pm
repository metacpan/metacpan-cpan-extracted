package Google::Monitoring::V3::Snooze::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Snooze',
    as InstanceOf['Google::Monitoring::V3::Snooze::Snooze'];

coerce 'Snooze',
    from HashRef, via { 'Google::Monitoring::V3::Snooze::Snooze'->new($_) };

declare 'RepeatedSnooze',
    as ArrayRef[Snooze()];

coerce 'RepeatedSnooze',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Snooze::Snooze'->new($_) } @$_ ] };

declare 'MapStringSnooze',
    as HashRef[Snooze()];

declare 'Criteria',
    as InstanceOf['Google::Monitoring::V3::Snooze::Snooze::Criteria'];

coerce 'Criteria',
    from HashRef, via { 'Google::Monitoring::V3::Snooze::Snooze::Criteria'->new($_) };

declare 'RepeatedCriteria',
    as ArrayRef[Criteria()];

coerce 'RepeatedCriteria',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Snooze::Snooze::Criteria'->new($_) } @$_ ] };

declare 'MapStringCriteria',
    as HashRef[Criteria()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::Snooze::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
