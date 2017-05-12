use strict;
use warnings;
use Log::Analyze;
use File::Spec;
use Test::More tests => 2;

my $logfile = File::Spec->catfile( 't', 'data', 'log.txt' );
my $analyzer = Log::Analyze->new;

open( LOG, $logfile );
while (<LOG>) {
    chomp;
    my @f = split( /\t/, $_ );

    my $ua;
    if ( $f[1] =~ /MSIE/ ) {
        $ua = "ie";
    }
    elsif ( $f[1] = ~/Firefox/ ) {
        $ua = "firefox";
    }
    my $num = $f[2];

    $analyzer->analyze( [$ua], "sum" => $num );
}
close(LOG);

{
    my $tree    = $analyzer->tree;
    my $correct = {
        'ie'      => 2080,
        'firefox' => 220
    };
    is_deeply( $tree, $correct, "tree is deeply matched" );
}

{
    my $matrix = $analyzer->matrix;
    my $correct = [ [ 'firefox', 220 ], [ 'ie', 2080 ] ];
    is_deeply( $matrix, $correct, "matrix is deeply matched" );
}
