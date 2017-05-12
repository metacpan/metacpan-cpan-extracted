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

    $analyzer->analyze( [ $date, $hour ], "count" );
}
close(LOG);

{
    my $tree = $analyzer->tree;
    my $correct = tree_correct_data();
    is_deeply( $tree, $correct, "tree is deeply matched" );
}

{
    my $matrix = $analyzer->matrix;
    my $correct = matrix_correct_data();
    is_deeply( $matrix, $correct, "matrix is deeply matched" );
}

sub tree_correct_data {
    my $data = {
        '11' => {
            '01' => 9,
            '05' => 2,
            '04' => 6,
            '02' => 4,
            '07' => 17,
            '03' => 7,
            '08' => 20,
            '00' => 14,
            '06' => 9
        },
        '10' => {
            '11' => 25,
            '21' => 24,
            '17' => 15,
            '12' => 17,
            '20' => 17,
            '15' => 20,
            '14' => 25,
            '22' => 30,
            '18' => 21,
            '23' => 25,
            '19' => 16,
            '10' => 26,
            '13' => 21,
            '16' => 17,
            '09' => 16
        }
    };
    return $data;
}

sub matrix_correct_data {
    my $data = [
        [ '10', '09', 16 ],
        [ '10', '10', 26 ],
        [ '10', '11', 25 ],
        [ '10', '12', 17 ],
        [ '10', '13', 21 ],
        [ '10', '14', 25 ],
        [ '10', '15', 20 ],
        [ '10', '16', 17 ],
        [ '10', '17', 15 ],
        [ '10', '18', 21 ],
        [ '10', '19', 16 ],
        [ '10', '20', 17 ],
        [ '10', '21', 24 ],
        [ '10', '22', 30 ],
        [ '10', '23', 25 ],
        [ '11', '00', 14 ],
        [ '11', '01', 9 ],
        [ '11', '02', 4 ],
        [ '11', '03', 7 ],
        [ '11', '04', 6 ],
        [ '11', '05', 2 ],
        [ '11', '06', 9 ],
        [ '11', '07', 17 ],
        [ '11', '08', 20 ]
    ];
    return $data;
}