package Google::Cloud::Bigquery::V2::SecureContext::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SecureContext',
    as InstanceOf['Google::Cloud::Bigquery::V2::SecureContext::SecureContext'];

coerce 'SecureContext',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::SecureContext::SecureContext'->new($_) };

declare 'RepeatedSecureContext',
    as ArrayRef[SecureContext()];

coerce 'RepeatedSecureContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::SecureContext::SecureContext'->new($_) } @$_ ] };

declare 'MapStringSecureContext',
    as HashRef[SecureContext()];

1;
