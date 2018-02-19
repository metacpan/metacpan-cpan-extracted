#!perl

use warnings;
use strict;
use 5.010;
use lib 't';
use Test::More;
use Lab::Test import => ['file_ok'];
use File::Temp qw/tempdir/;
use Test::File;
use Test::Fatal;
use File::Spec::Functions qw/catfile/;
use Lab::Moose;
use PDL::Core qw/pdl/;
use Module::Load 'autoload';

eval {
    autoload 'PDL::Graphics::Gnuplot';
    1;
} or do {
    plan skip_all => "test requires PDL::Graphics::Gnuplot";
};

my $dir = tempdir( CLEANUP => 1 );
my $folder = datafolder( path => catfile( $dir, 'gnuplot' ) );
my $file = datafile(
    type     => 'Gnuplot',
    folder   => $folder,
    filename => 'file.dat',
    columns  => [qw/A B C/],
);
my $path = $file->path();
$file->log( A => 0.7, B => 2, C => 3 );
$file->new_block();
$file->log_comment( comment => 'YOLO' );
$file->log( A => 2, B => 3, C => 4 );

my $expected = <<"EOF";
# A\tB\tC
0.7\t2\t3

# YOLO
2\t3\t4
EOF
file_ok( $path, $expected, "gnuplot file log method" );

# log block

my $block = pdl [ [ 10, 30 ], [ 20, 40 ] ];

$file->log_block(
    prefix => { A => 1 },
    block  => $block
);
$expected .= <<"EOF";
1\t10\t20
1\t30\t40
EOF
file_ok( $path, $expected, "log_block method" );

# log_block without prefix
$block = pdl [ [ 1, 4, 7 ], [ 2, 5, 8 ], [ 3, 6, 9 ] ];

$file->log_block(
    block => $block,
);

$expected .= <<"EOF";
1\t2\t3
4\t5\t6
7\t8\t9
EOF
file_ok( $path, $expected, "log_block without prefix" );

# 1D block

$block = [ 1, 2, 3 ];

$file->log_block(
    prefix => { A => 5, B => 6 },
    block  => $block,
);

$expected .= <<"EOF";
5\t6\t1
5\t6\t2
5\t6\t3
EOF

file_ok( $path, $expected, "log_block with 1D pdl" );

# Illegal stuff
ok(
    exception { $file->log( A => 1, B => 2 ) },
    "missing column"
);

ok(
    exception { $file->log( A => 1, B => 2, C => 3, D => 4 ) },
    "unknown column"
);

ok(
    exception {
        my $pdl = pdl [ 1, 2 ];
        $file->log_block( prefix => { A => 1 }, block => $pdl );
    },
    "missing prefix column"
);

ok(
    exception {
        my $pdl => [ 1, 2 ];
        $file->log_block(
            prefix => { A => 1, B => 2, C => 3 },
            block  => $pdl
        );
    },
    "too many prefix columns"
);

ok(
    exception {
        my $pdl = pdl [ 1, 2 ];
        $file->log_block( prefix => { A => 1 }, block => $pdl );
    },
    "missing data column"
);

ok(
    exception {
        my $pdl = pdl [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 7, 8 ] ];
        $file->log_block( block => $pdl );
    },
    "too many data columns"
);

done_testing();
