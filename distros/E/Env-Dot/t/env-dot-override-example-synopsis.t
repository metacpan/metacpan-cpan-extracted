#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;

use Test2::V0;
set_encoding('utf8');

# Add t/lib to @INC
use FindBin 1.51 qw( $RealBin );
use File::Spec;
my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{.}, 'lib' );
}
use lib "$lib_path";

use Test2::Require::OS::Linux;

use Test::Script;

subtest 'Script runs --version' => sub {
    my $stdout;
    program_runs( [ 't/env-dot-override-example-synopsis.sh', ], { stdout => \$stdout, }, 'Verify output' );
    like( ( split qr/\n/msx, $stdout )[0], qr/^ VAR:Good \s value $/msx,   'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[1], qr/^ VAR:Better \s value $/msx, 'Correct stdout' );

    done_testing;
};

done_testing;
