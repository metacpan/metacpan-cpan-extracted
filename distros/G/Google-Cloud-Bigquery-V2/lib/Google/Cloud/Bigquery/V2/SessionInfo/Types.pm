package Google::Cloud::Bigquery::V2::SessionInfo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SessionInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::SessionInfo::SessionInfo'];

coerce 'SessionInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::SessionInfo::SessionInfo'->new($_) };

declare 'RepeatedSessionInfo',
    as ArrayRef[SessionInfo()];

coerce 'RepeatedSessionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::SessionInfo::SessionInfo'->new($_) } @$_ ] };

declare 'MapStringSessionInfo',
    as HashRef[SessionInfo()];

1;
