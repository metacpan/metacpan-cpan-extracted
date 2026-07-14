package Google::Api::SourceInfo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SourceInfo',
    as InstanceOf['Google::Api::SourceInfo::SourceInfo'];

coerce 'SourceInfo',
    from HashRef, via { 'Google::Api::SourceInfo::SourceInfo'->new($_) };

declare 'RepeatedSourceInfo',
    as ArrayRef[SourceInfo()];

coerce 'RepeatedSourceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::SourceInfo::SourceInfo'->new($_) } @$_ ] };

declare 'MapStringSourceInfo',
    as HashRef[SourceInfo()];

1;
