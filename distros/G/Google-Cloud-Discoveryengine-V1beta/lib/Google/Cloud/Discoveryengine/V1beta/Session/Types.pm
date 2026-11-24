package Google::Cloud::Discoveryengine::V1beta::Session::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Session',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Session::Session'];

coerce 'Session',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Session::Session'->new($_) };

declare 'RepeatedSession',
    as ArrayRef[Session()];

coerce 'RepeatedSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Session::Session'->new($_) } @$_ ] };

declare 'MapStringSession',
    as HashRef[Session()];

declare 'State',
    as (Int | Str);

declare 'Turn',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Session::Session::Turn'];

coerce 'Turn',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Session::Session::Turn'->new($_) };

declare 'RepeatedTurn',
    as ArrayRef[Turn()];

coerce 'RepeatedTurn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Session::Session::Turn'->new($_) } @$_ ] };

declare 'MapStringTurn',
    as HashRef[Turn()];

declare 'QueryConfigEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Session::Session::Turn::QueryConfigEntry'];

coerce 'QueryConfigEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Session::Session::Turn::QueryConfigEntry'->new($_) };

declare 'RepeatedQueryConfigEntry',
    as ArrayRef[QueryConfigEntry()];

coerce 'RepeatedQueryConfigEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Session::Session::Turn::QueryConfigEntry'->new($_) } @$_ ] };

declare 'MapStringQueryConfigEntry',
    as HashRef[QueryConfigEntry()];

declare 'Query',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Session::Query'];

coerce 'Query',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Session::Query'->new($_) };

declare 'RepeatedQuery',
    as ArrayRef[Query()];

coerce 'RepeatedQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Session::Query'->new($_) } @$_ ] };

declare 'MapStringQuery',
    as HashRef[Query()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Session::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
