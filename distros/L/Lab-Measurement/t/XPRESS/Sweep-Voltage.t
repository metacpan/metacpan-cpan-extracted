#!/usr/bin/env perl

use 5.010;
use warnings;
use strict;

use lib qw(t/);

use Lab::Test import => ['file_ok_crlf'];
use Test::More tests => 1;
use File::Spec::Functions;
use File::Path qw/remove_tree/;
use File::Temp qw/tempdir/;

use Lab::Measurement;
use Lab::SCPI;
use Scalar::Util qw(looks_like_number);

use MockTest;

my $query;
my $yoko = Instrument(
    'YokogawaGS200',
    {
        connection_type => get_connection_type(),
        gpib_address    => get_gpib_address(2),
        logfile         => get_logfile('t/XPRESS/Sweep-Voltage.yml'),
        gate_protect    => 0,
    }
);

my $sweep = Sweep(
    'Voltage',
    {
        instrument => $yoko,
        mode       => 'step',
        jump       => 1,
        points     => [ 0, 1 ],
        stepwidth  => [0.1],
        rate       => [0.1],
    }
);

my $folder = tempdir( cleanup => 1 );
say "folder: $folder";

# ugly, but seems the only way to use temporary files
$Lab::XPRESS::Data::XPRESS_DataFile::GLOBAL_PATH = $folder;
my $file     = 'voltage';
my $DataFile = DataFile($file);
$DataFile->add_column('volt');

my $measurement = sub {
    my $sweep = shift;
    my $voltage = $yoko->get_value( { read_mode => 'cache' } );
    $sweep->LOG( { volt => $voltage } );
};

$DataFile->add_measurement($measurement);
$sweep->add_DataFile($DataFile);

$sweep->start();

my $file_path = catfile( $folder, 'MEAS_000', "${file}.dat" );

my $expected = <<"EOD";
#COLUMNS#\tvolt
+0.00000E+0
+0.10000E+0
+0.20000E+0
+0.30000E+0
+0.40000E+0
+0.50000E+0
+0.60000E+0
+0.70000E+0
+0.80000E+0
+0.90000E+0
+1.00000E+0
EOD

file_ok_crlf( $file_path, $expected, "data file as expectey" );
