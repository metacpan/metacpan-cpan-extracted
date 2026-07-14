package Google::Api::Visibility::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Visibility',
    as InstanceOf['Google::Api::Visibility::Visibility'];

coerce 'Visibility',
    from HashRef, via { 'Google::Api::Visibility::Visibility'->new($_) };

declare 'RepeatedVisibility',
    as ArrayRef[Visibility()];

coerce 'RepeatedVisibility',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Visibility::Visibility'->new($_) } @$_ ] };

declare 'MapStringVisibility',
    as HashRef[Visibility()];

declare 'VisibilityRule',
    as InstanceOf['Google::Api::Visibility::VisibilityRule'];

coerce 'VisibilityRule',
    from HashRef, via { 'Google::Api::Visibility::VisibilityRule'->new($_) };

declare 'RepeatedVisibilityRule',
    as ArrayRef[VisibilityRule()];

coerce 'RepeatedVisibilityRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Visibility::VisibilityRule'->new($_) } @$_ ] };

declare 'MapStringVisibilityRule',
    as HashRef[VisibilityRule()];

1;
