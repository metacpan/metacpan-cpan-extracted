package Google::Cloud::Discoveryengine::V1beta::SampleQuery::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SampleQuery',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery'];

coerce 'SampleQuery',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery'->new($_) };

declare 'RepeatedSampleQuery',
    as ArrayRef[SampleQuery()];

coerce 'RepeatedSampleQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery'->new($_) } @$_ ] };

declare 'MapStringSampleQuery',
    as HashRef[SampleQuery()];

declare 'QueryEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery::QueryEntry'];

coerce 'QueryEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery::QueryEntry'->new($_) };

declare 'RepeatedQueryEntry',
    as ArrayRef[QueryEntry()];

coerce 'RepeatedQueryEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery::QueryEntry'->new($_) } @$_ ] };

declare 'MapStringQueryEntry',
    as HashRef[QueryEntry()];

declare 'Target',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery::QueryEntry::Target'];

coerce 'Target',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery::QueryEntry::Target'->new($_) };

declare 'RepeatedTarget',
    as ArrayRef[Target()];

coerce 'RepeatedTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery::QueryEntry::Target'->new($_) } @$_ ] };

declare 'MapStringTarget',
    as HashRef[Target()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SampleQuery::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
