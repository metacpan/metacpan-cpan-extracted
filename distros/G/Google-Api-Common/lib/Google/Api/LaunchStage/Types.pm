package Google::Api::LaunchStage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LaunchStage',
    as (Int | Str);

1;
