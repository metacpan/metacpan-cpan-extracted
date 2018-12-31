use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 3;

my @inc_copy = @INC;

# load the module
require Devel::TraceUse;
my $trace_use = \&Devel::TraceUse::trace_use;

# check @INC
is_deeply(
    \@INC,
    [ $trace_use, @inc_copy ],
    'loading Devel::TraceUse added the hook to @INC'
);

# update @INC
# (with an eval string, to pick the new definition)
eval 'use lib "/some/directory";';
is_deeply(
    [ @INC[ 0 .. 1 ] ],
    [ '/some/directory', $trace_use ],
    '@INC modified by use lib'
) or diag Dumper( \@inc_copy, \@INC );

# call require
eval 'require This::Does::Not::Exist;';
is_deeply(
    [ @INC[ 0 .. 1 ] ],
    [ $trace_use, '/some/directory' ],
    'the trace_use coderef is back at the front'
) or diag Dumper( \@inc_copy, \@INC );
