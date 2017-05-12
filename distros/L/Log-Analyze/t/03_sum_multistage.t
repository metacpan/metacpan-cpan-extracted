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

    my $ua;
    if ( $f[1] =~ /MSIE/ ) {
        $ua = "ie";
    }
    elsif ( $f[1] = ~/Firefox/ ) {
        $ua = "firefox";
    }
    my $num = $f[2];

    $analyzer->analyze( [ $hour, $ua ], "sum" => $num );
}
close(LOG);

{
    my $tree    = $analyzer->tree;
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
            'ie'      => 133,
            'firefox' => 6
        },
        '21' => {
            'ie'      => 108,
            'firefox' => 10
        },
        '05' => { 'ie' => 11 },
        '04' => { 'ie' => 26 },
        '17' => {
            'ie'      => 87,
            'firefox' => 1
        },
        '02' => {
            'ie'      => 14,
            'firefox' => 1
        },
        '22' => {
            'ie'      => 180,
            'firefox' => 13
        },
        '18' => {
            'ie'      => 104,
            'firefox' => 4
        },
        '08' => {
            'ie'      => 90,
            'firefox' => 15
        },
        '03' => {
            'ie'      => 32,
            'firefox' => 16
        },
        '06' => {
            'ie'      => 54,
            'firefox' => 9
        },
        '23' => { 'ie' => 139 },
        '13' => {
            'ie'      => 118,
            'firefox' => 3
        },
        '16' => {
            'ie'      => 68,
            'firefox' => 16
        },
        '01' => {
            'ie'      => 42,
            'firefox' => 21
        },
        '12' => {
            'ie'      => 100,
            'firefox' => 9
        },
        '14' => {
            'ie'      => 115,
            'firefox' => 9
        },
        '15' => {
            'ie'      => 133,
            'firefox' => 13
        },
        '20' => {
            'ie'      => 89,
            'firefox' => 10
        },
        '07' => {
            'ie'      => 96,
            'firefox' => 1
        },
        '00' => {
            'ie'      => 51,
            'firefox' => 28
        },
        '10' => {
            'ie'      => 134,
            'firefox' => 11
        },
        '19' => {
            'ie'      => 75,
            'firefox' => 9
        },
        '09' => {
            'ie'      => 81,
            'firefox' => 15
        }
    };
    return $data;
}

sub matrix_correct_data {
    my $data = [
        [ '00', 'firefox', 28 ],
        [ '00', 'ie',      51 ],
        [ '01', 'firefox', 21 ],
        [ '01', 'ie',      42 ],
        [ '02', 'firefox', 1 ],
        [ '02', 'ie',      14 ],
        [ '03', 'firefox', 16 ],
        [ '03', 'ie',      32 ],
        [ '04', 'ie',      26 ],
        [ '05', 'ie',      11 ],
        [ '06', 'firefox', 9 ],
        [ '06', 'ie',      54 ],
        [ '07', 'firefox', 1 ],
        [ '07', 'ie',      96 ],
        [ '08', 'firefox', 15 ],
        [ '08', 'ie',      90 ],
        [ '09', 'firefox', 15 ],
        [ '09', 'ie',      81 ],
        [ '10', 'firefox', 11 ],
        [ '10', 'ie',      134 ],
        [ '11', 'firefox', 6 ],
        [ '11', 'ie',      133 ],
        [ '12', 'firefox', 9 ],
        [ '12', 'ie',      100 ],
        [ '13', 'firefox', 3 ],
        [ '13', 'ie',      118 ],
        [ '14', 'firefox', 9 ],
        [ '14', 'ie',      115 ],
        [ '15', 'firefox', 13 ],
        [ '15', 'ie',      133 ],
        [ '16', 'firefox', 16 ],
        [ '16', 'ie',      68 ],
        [ '17', 'firefox', 1 ],
        [ '17', 'ie',      87 ],
        [ '18', 'firefox', 4 ],
        [ '18', 'ie',      104 ],
        [ '19', 'firefox', 9 ],
        [ '19', 'ie',      75 ],
        [ '20', 'firefox', 10 ],
        [ '20', 'ie',      89 ],
        [ '21', 'firefox', 10 ],
        [ '21', 'ie',      108 ],
        [ '22', 'firefox', 13 ],
        [ '22', 'ie',      180 ],
        [ '23', 'ie',      139 ]
    ];
    return $data;
}