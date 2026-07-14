package Google::Api::Log::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LogDescriptor',
    as InstanceOf['Google::Api::Log::LogDescriptor'];

coerce 'LogDescriptor',
    from HashRef, via { 'Google::Api::Log::LogDescriptor'->new($_) };

declare 'RepeatedLogDescriptor',
    as ArrayRef[LogDescriptor()];

coerce 'RepeatedLogDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Log::LogDescriptor'->new($_) } @$_ ] };

declare 'MapStringLogDescriptor',
    as HashRef[LogDescriptor()];

1;
