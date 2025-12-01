use strict;
use warnings;

use Test::More tests => 3;
use Test::Script qw( script_compiles script_fails script_stderr_like );

use File::Spec::Functions qw( catfile );

my $utility = catfile( qw( t examples broken ) );
script_compiles $utility;
script_fails $utility, { exit => 255 }, 'Has fatal error';
script_stderr_like qr/getopts: .* alphanumeric .* at $utility .*/, 'Check error details'
