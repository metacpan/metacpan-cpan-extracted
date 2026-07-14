package Google::Type::LocalizedText::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LocalizedText',
    as InstanceOf['Google::Type::LocalizedText::LocalizedText'];

coerce 'LocalizedText',
    from HashRef, via { 'Google::Type::LocalizedText::LocalizedText'->new($_) };

declare 'RepeatedLocalizedText',
    as ArrayRef[LocalizedText()];

coerce 'RepeatedLocalizedText',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::LocalizedText::LocalizedText'->new($_) } @$_ ] };

declare 'MapStringLocalizedText',
    as HashRef[LocalizedText()];

1;
