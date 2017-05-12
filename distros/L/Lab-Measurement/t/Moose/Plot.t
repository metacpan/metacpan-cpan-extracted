#!perl

use strict;
use warnings;
use 5.010;
use lib 't';
use Test::More;
use Test::File;
use Lab::Test import => [qw/file_filter_ok/];
use File::Spec::Functions qw/catfile/;
use Lab::Moose;
use Module::Load 'autoload';
use File::Temp qw/tempfile tempdir/;
use File::Slurper 'read_binary';
use PDL;

eval {
    autoload 'PDL::Graphics::Gnuplot';
    1;
} or do {
    plan skip_all => "test requires PDL::Graphics::Gnuplot";
};

# Start P::G::G to inititialize $gp_version
{
    my $gp = PDL::Graphics::Gnuplot->new('dumb');
}

my $gp_version = $PDL::Graphics::Gnuplot::gp_version;

if ( not length($gp_version) ) {
    BAIL_OUT("no gnuplot version defined");
}

if ( $gp_version < 5 ) {
    plan skip_all => "test requires gnuplot 5.0, this is gnuplot $gp_version";
}

my $dir = tempdir( CLEANUP => 1 );

# Low-level plotting
autoload 'Lab::Moose::Plot';

my $file = catfile( $dir, 'low_level_plot.txt' );

say $file;
my $plot = Lab::Moose::Plot->new(
    terminal         => 'dumb',
    terminal_options => { output => $file }
);

my $x = sequence(10);
my $y = $x**2;

$plot->plot(
    curve_options => { with => 'points' },
    data => [ $x, $y ],
);

my $kill_trailing_spaces = qr/ *$/m;
file_filter_ok(
    $file, squared_plot_expected(), $kill_trailing_spaces,
    'plot x**2 vs x'
);

# DataFile::Gnuplot2D

{

    my $folder = datafolder( path => catfile( $dir, 'gnuplot' ) );
    my $file = datafile(
        type     => 'Gnuplot::2D',
        folder   => $folder,
        filename => 'file.dat',
        columns  => [qw/A B C/]
    );
    my $path = $file->path();

    my $AB_plot = catfile( $dir, 'AB_plot.txt' );
    my $BC_plot = catfile( $dir, 'BC_plot.txt' );
    my $BC_plot_hardcopy = 'BC_plot.png';
    my $BC_plot_hardcopy_path = catfile( $folder->path(), $BC_plot_hardcopy );

    $file->add_plot(
        x                => 'A',
        y                => 'B',
        terminal         => 'dumb',
        terminal_options => { output => $AB_plot },
        curve_options    => { with => 'points' },
    );

    # Same with hard-copy
    $file->add_plot(
        x                => 'A',
        y                => 'B',
        terminal         => 'dumb',
        terminal_options => { output => $AB_plot . 2 },
        curve_options    => { with => 'points' },
        hard_copy        => 'AB_plot.png',
    );

    # With refresh handle
    $file->add_plot(
        handle           => 'BC',
        x                => 'B',
        y                => 'C',
        terminal         => 'dumb',
        terminal_options => { output => $BC_plot },
        curve_options    => { with => 'points' },
        hard_copy        => $BC_plot_hardcopy,
    );

    for my $i ( 1 .. 10 ) {
        $file->log( A => $i, B => 2 * $i, C => 3 * $i );
    }

    file_filter_ok(
        $AB_plot, AB_plot_expected(), $kill_trailing_spaces,
        "plotting A vs B"
    );
    file_not_empty_ok(
        catfile( $folder->path(), 'AB_plot.png' ),
        'A-B plot hardcopy is not empty'
    );

    file_not_exists_ok( $BC_plot, "B-C not yet plotted" );
    file_empty_ok( $BC_plot_hardcopy_path, "B-C hardcopy is empty" );

    $file->refresh_plots( handle => 'BC' );

    file_filter_ok(
        $BC_plot, BC_plot_expected(), $kill_trailing_spaces,
        "plotting B vs C"
    );
    file_not_empty_ok( $BC_plot_hardcopy_path, "B-C hardcopy is not empty" );

}

done_testing();

sub squared_plot_expected {
    return <<"EOF";
\f

  90 +-+-----+-------+------+-------+-------+-------+------+-------+-----+-+
     +       +       +      +       +       +       +      +       +       +
  80 +-+                                                                 +-A
     |                                                                     |
  70 +-+                                                                 +-+
     |                                                             A       |
  60 +-+                                                                 +-+
     |                                                                     |
  50 +-+                                                                 +-+
     |                                                     A               |
     |                                                                     |
  40 +-+                                            A                    +-+
     |                                                                     |
  30 +-+                                                                 +-+
     |                                      A                              |
  20 +-+                                                                 +-+
     |                              A                                      |
  10 +-+                    A                                            +-+
     +       +       A      +       +       +       +      +       +       +
   0 A-+-----A-------+------+-------+-------+-------+------+-------+-----+-+
     0       1       2      3       4       5       6      7       8       9

EOF
}

sub AB_plot_expected {
    return <<"EOF";
\f

  20 +-+-----+-------+------+-------+-------+-------+------+-------+-----+-A
     +       +       +      +       +       +       +      +       +       +
  18 +-+                                                           A     +-+
     |                                                                     |
  16 +-+                                                   A             +-+
     |                                                                     |
  14 +-+                                            A                    +-+
     |                                                                     |
  12 +-+                                    A                            +-+
     |                                                                     |
     |                                                                     |
  10 +-+                            A                                    +-+
     |                                                                     |
   8 +-+                    A                                            +-+
     |                                                                     |
   6 +-+             A                                                   +-+
     |                                                                     |
   4 +-+     A                                                           +-+
     +       +       +      +       +       +       +      +       +       +
   2 A-+-----+-------+------+-------+-------+-------+------+-------+-----+-+
     1       2       3      4       5       6       7      8       9       10

EOF
}

sub BC_plot_expected {
    return <<"EOF";
\f

  30 +-+-----+-------+------+-------+-------+-------+------+-------+-----+-A
     +       +       +      +       +       +       +      +       +       +
     |                                                             A       |
  25 +-+                                                                 +-+
     |                                                     A               |
     |                                                                     |
  20 +-+                                            A                    +-+
     |                                                                     |
     |                                      A                              |
  15 +-+                            A                                    +-+
     |                                                                     |
     |                      A                                              |
     |                                                                     |
  10 +-+             A                                                   +-+
     |                                                                     |
     |       A                                                             |
   5 +-+                                                                 +-+
     A                                                                     |
     +       +       +      +       +       +       +      +       +       +
   0 +-+-----+-------+------+-------+-------+-------+------+-------+-----+-+
     2       4       6      8       10      12      14     16      18      20

EOF
}
