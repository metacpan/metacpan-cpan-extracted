use strict;
use warnings;

use Debug::Helper::Flag DEBUG_FLAG => 0;

use Test::More tests => 2;
use Test::Lib;

use Local::ImportModule;

is(Debug::Helper::Flag::DEBUG_FLAG,   !!0, 'Debug::Helper::Flag::DEBUG_FLAG');
is(Local::ImportModule::DEBUG_FLAG, Debug::Helper::Flag::DEBUG_FLAG,
   'Local::ImportModule::DEBUG_FLAG');

