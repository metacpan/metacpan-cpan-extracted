#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;

use File::Basename qw( dirname );
use File::Spec ();
use FindBin qw( $RealBin );

use Test2::V1 qw( -utf8 );
use Test2::Tools::Subtest qw( subtest_streamed );
use Test::Script 1.28;

my $lib_path;
BEGIN {
    $lib_path = File::Spec->catdir(($RealBin =~ /(.+)/msx)[0], q{.}, 'lib');
}
use lib "$lib_path";

use Test2::Require::Platform::Unix;

subtest_streamed 'Script runs --version' => sub {
    my $stdout;
    my $this_dir = File::Spec->rel2abs( dirname( File::Spec->rel2abs( __FILE__ ) ) );
    ($this_dir) = $this_dir =~ /(.+)/msx; # Make it non-tainted
    my $prg_path = File::Spec->catfile( $this_dir,
        'env-dot-override-example-synopsis.sh' );
    T2->note("run: $prg_path");
    program_runs([ $prg_path, ], { stdout => \$stdout, }, 'Verify output');
    T2->like( (split qr/\n/msx, $stdout)[0], qr/^ VAR:Good \s value $/msx, 'Correct stdout');
    T2->like( (split qr/\n/msx, $stdout)[1], qr/^ VAR:Better \s value $/msx, 'Correct stdout');

    T2->done_testing;
};

T2->done_testing;
