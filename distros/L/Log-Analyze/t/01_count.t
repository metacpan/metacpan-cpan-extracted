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

    $f[0] =~ /\[(\d\d)\/Aug\/2008:(\d\d):(\d\d):(\d\d)/;
    my $date = $1;
    my $hour = $2;
    my $min  = $3;
    my $sec  = $4;

    $analyzer->analyze( [$hour], "count" );
}
close(LOG);

{
    my $tree    = $analyzer->tree;
    my $correct = {
        '11' => 25,
        '21' => 24,
        '05' => 2,
        '04' => 6,
        '17' => 15,
        '02' => 4,
        '22' => 30,
        '18' => 21,
        '08' => 20,
        '03' => 7,
        '06' => 9,
        '23' => 25,
        '13' => 21,
        '16' => 17,
        '01' => 9,
        '12' => 17,
        '14' => 25,
        '15' => 20,
        '20' => 17,
        '07' => 17,
        '00' => 14,
        '10' => 26,
        '19' => 16,
        '09' => 16
    };
    is_deeply( $tree, $correct, "tree is deeply matched" );
}

{
    my $matrix  = $analyzer->matrix;
    my $correct = [
        [ '00', 14 ],
        [ '01', 9 ],
        [ '02', 4 ],
        [ '03', 7 ],
        [ '04', 6 ],
        [ '05', 2 ],
        [ '06', 9 ],
        [ '07', 17 ],
        [ '08', 20 ],
        [ '09', 16 ],
        [ '10', 26 ],
        [ '11', 25 ],
        [ '12', 17 ],
        [ '13', 21 ],
        [ '14', 25 ],
        [ '15', 20 ],
        [ '16', 17 ],
        [ '17', 15 ],
        [ '18', 21 ],
        [ '19', 16 ],
        [ '20', 17 ],
        [ '21', 24 ],
        [ '22', 30 ],
        [ '23', 25 ]
    ];
    is_deeply( $matrix, $correct, "matrix is deeply matched" );
}