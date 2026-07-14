package Google::Api::Backend::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Backend',
    as InstanceOf['Google::Api::Backend::Backend'];

coerce 'Backend',
    from HashRef, via { 'Google::Api::Backend::Backend'->new($_) };

declare 'RepeatedBackend',
    as ArrayRef[Backend()];

coerce 'RepeatedBackend',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Backend::Backend'->new($_) } @$_ ] };

declare 'MapStringBackend',
    as HashRef[Backend()];

declare 'BackendRule',
    as InstanceOf['Google::Api::Backend::BackendRule'];

coerce 'BackendRule',
    from HashRef, via { 'Google::Api::Backend::BackendRule'->new($_) };

declare 'RepeatedBackendRule',
    as ArrayRef[BackendRule()];

coerce 'RepeatedBackendRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Backend::BackendRule'->new($_) } @$_ ] };

declare 'MapStringBackendRule',
    as HashRef[BackendRule()];

declare 'PathTranslation',
    as (Int | Str);

declare 'OverridesByRequestProtocolEntry',
    as InstanceOf['Google::Api::Backend::BackendRule::OverridesByRequestProtocolEntry'];

coerce 'OverridesByRequestProtocolEntry',
    from HashRef, via { 'Google::Api::Backend::BackendRule::OverridesByRequestProtocolEntry'->new($_) };

declare 'RepeatedOverridesByRequestProtocolEntry',
    as ArrayRef[OverridesByRequestProtocolEntry()];

coerce 'RepeatedOverridesByRequestProtocolEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Backend::BackendRule::OverridesByRequestProtocolEntry'->new($_) } @$_ ] };

declare 'MapStringOverridesByRequestProtocolEntry',
    as HashRef[OverridesByRequestProtocolEntry()];

1;
