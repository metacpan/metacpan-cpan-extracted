package Google::Cloud::Securitycenter::V2::SecurityMarks::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SecurityMarks',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks'];

coerce 'SecurityMarks',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks'->new($_) };

declare 'RepeatedSecurityMarks',
    as ArrayRef[SecurityMarks()];

coerce 'RepeatedSecurityMarks',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks'->new($_) } @$_ ] };

declare 'MapStringSecurityMarks',
    as HashRef[SecurityMarks()];

declare 'MarksEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks::MarksEntry'];

coerce 'MarksEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks::MarksEntry'->new($_) };

declare 'RepeatedMarksEntry',
    as ArrayRef[MarksEntry()];

coerce 'RepeatedMarksEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecurityMarks::SecurityMarks::MarksEntry'->new($_) } @$_ ] };

declare 'MapStringMarksEntry',
    as HashRef[MarksEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::SecurityMarks::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
