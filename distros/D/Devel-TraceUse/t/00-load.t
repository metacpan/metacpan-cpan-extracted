#!perl -T

use Test::More tests => 4;

my @inc_copy = @INC;

use_ok( 'Devel::TraceUse' );
diag( "Testing Devel::TraceUse $Devel::TraceUse::VERSION, Perl $], $^X" );

is( @INC, @inc_copy + 1, 'using module should add path to @INC' );
is( ref $INC[0], 'CODE', '... a coderef to the start' );

Devel::TraceUse->import();
is( @INC, @inc_copy + 1, '... but should add it only once' );

# suppress diagnostic output at the end
$SIG{__WARN__} = sub {};
