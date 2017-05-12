#!/usr/bin/env perl

use strict;
use warnings;

use MarpaX::Languages::Lua::Parser;

# ---------------------------------

my($input_file_name) = shift || die "Usage: $0 a_lua_source_file_name\n";
my($parser)          = MarpaX::Languages::Lua::Parser -> new(input_file_name => $input_file_name);

$parser -> run;

print map{"$_\n"} @{$parser -> output_tokens};
