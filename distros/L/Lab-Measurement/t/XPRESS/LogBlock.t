#!perl
use 5.010;
use warnings;
use strict;

use lib 't';

use Lab::Test import => [qw/is_float file_ok_crlf/];
use Test::More tests => 12;

use File::Spec::Functions;
use File::Path qw/remove_tree/;
use File::Temp qw/tempdir/;

use File::Slurper 'read_binary';
use Lab::Measurement;

my $source = Instrument(
    'DummySource',
    {
        connection_type => 'DEBUG',
        gate_protect    => 0
    }
);

my $sweep = Sweep(
    'Voltage',
    {
        instrument => $source,
        mode       => 'step',
        jump       => 1,
        points     => [ 0, 1 ],
        stepwidth  => [0.1],
        rate       => [0.1],
    }
);

# We can't use a subdir of t/, as it would contain a copy of this script.

my $folder = tempdir( cleanup => 1 );
say "folder: $folder";

# ugly, but seems the only way to use temporary files
$Lab::XPRESS::Data::XPRESS_DataFile::GLOBAL_PATH = $folder;
my $file     = 'blockfile';
my $DataFile = DataFile($file);
$DataFile->add_column('volt');
$DataFile->add_column('f');
$DataFile->add_column('transmission');

my $expected_voltage = 0;
my $measurement      = sub {
    my $sweep   = shift;
    my $voltage = $sweep->get_value();
    my $block   = [ [ 1, 2 ], [ 2, 3 ], [ 3, 4 ] ];
    is_float( $voltage, $expected_voltage, "voltage is set" );
    $expected_voltage += 0.1;
    $sweep->LogBlock(
        prefix => [$voltage],
        block  => $block
    );
};

$DataFile->add_measurement($measurement);
$sweep->add_DataFile($DataFile);

$sweep->start();

my $expected = <<'EOF';
#COLUMNS#	volt	f	transmission
0	1	2
0	2	3
0	3	4
0.1	1	2
0.1	2	3
0.1	3	4
0.2	1	2
0.2	2	3
0.2	3	4
0.3	1	2
0.3	2	3
0.3	3	4
0.4	1	2
0.4	2	3
0.4	3	4
0.5	1	2
0.5	2	3
0.5	3	4
0.6	1	2
0.6	2	3
0.6	3	4
0.7	1	2
0.7	2	3
0.7	3	4
0.8	1	2
0.8	2	3
0.8	3	4
0.9	1	2
0.9	2	3
0.9	3	4
1	1	2
1	2	3
1	3	4
EOF

my $file_path = catfile( $folder, 'MEAS_000', "${file}.dat" );

file_ok_crlf( $file_path, $expected, "data file as expected" );

