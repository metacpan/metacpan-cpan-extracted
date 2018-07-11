#!perl

use warnings;
use strict;
use 5.010;
use lib 't';
use Test::More;
use Lab::Test import => ['file_ok'];
use File::Glob 'bsd_glob';
use File::Spec::Functions 'catfile';
use Lab::Moose;
use YAML::XS 'LoadFile';

use File::Temp qw/tempdir/;

my $dir = catfile( tempdir(), 'sweep' );
warn "dir: $dir\n";

sub dummysource {
    return instrument(
        type                 => 'DummySource',
        connection_type      => 'Debug',
        connection_options   => { verbose => 0 },
        verbose              => 0,
        max_units            => 100,
        min_units            => -10,
        max_units_per_step   => 100,
        max_units_per_second => 1000000,
    );
}

{
    #
    # Basic 1D sweep
    #

    my $source = dummysource();
    my $sweep  = sweep(
        type       => 'Step::Voltage',
        instrument => $source,
        from       => 0,
        to         => 0.5,
        step       => 0.1
    );

    my $datafile = sweep_datafile( columns => [qw/level value/] );

    my $value = 0;
    my $meas  = sub {
        my $sweep = shift;
        $sweep->log( level => $source->get_level, value => $value++ );
    };
    $sweep->start(
        measurement => $meas,
        datafile    => $datafile,
        folder      => $dir,
        date_prefix => 1,
        meta_data   => { foo => 1, bar => 2 },

        # use default datafile_dim and point_dim
    );

    my $expected = <<"EOF";
# level\tvalue
0\t0
0.1\t1
0.2\t2
0.3\t3
0.4\t4
0.5\t5
EOF
    my $foldername = $sweep->foldername;
    like(
        $foldername, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}_/,
        "foldername contains date"
    );
    my $path = catfile( $sweep->foldername, 'data.dat' );
    file_ok( $path, $expected, "basic 1D sweep: datafile" );
    my $meta_file = catfile( $sweep->foldername, 'META.yml' );
    my $meta = LoadFile($meta_file);
    is( $meta->{foo}, 1, "meta data: foo => 1" );
    is( $meta->{bar}, 2, "meta data: bar => 2" );
}

{
    #
    # Basic 1D sweep with list points
    #

    my $source = dummysource();
    my $sweep  = sweep(
        type       => 'Step::Voltage',
        instrument => $source,
        list       => [ 1, 4, 9, 16 ],
    );

    my $datafile = sweep_datafile( columns => [qw/level value/] );

    my $value = 0;
    my $meas  = sub {
        my $sweep = shift;
        $sweep->log( level => $source->get_level, value => $value++ );
    };
    $sweep->start(
        measurement => $meas,
        datafile    => $datafile,
        folder      => $dir,

        # use default datafile_dim and point_dim
    );

    my $expected = <<"EOF";
# level\tvalue
1\t0
4\t1
9\t2
16\t3
EOF
    my $path = catfile( $sweep->foldername, 'data.dat' );
    file_ok( $path, $expected, "basic 1D sweep with list: datafile" );
}

{
    #
    # Basic 1D sweep with points/steps
    #

    my $source = dummysource();
    my $sweep  = sweep(
        type       => 'Step::Voltage',
        instrument => $source,
        points     => [ 0, 1, 2 ],
        steps => [ 0.5, 0.2 ],
    );

    my $datafile = sweep_datafile( columns => [qw/level value/] );

    my $value = 0;
    my $meas  = sub {
        my $sweep = shift;
        $sweep->log( level => $source->get_level, value => $value++ );
    };
    $sweep->start(
        measurement => $meas,
        datafile    => $datafile,
        folder      => $dir,

        # use default datafile_dim and point_dim
    );

    my $expected = <<"EOF";
# level\tvalue
0\t0
0.5\t1
1\t2
1\t3
1.2\t4
1.4\t5
1.6\t6
1.8\t7
2\t8
EOF
    my $path = catfile( $sweep->foldername, 'data.dat' );
    file_ok( $path, $expected, "basic 1D sweep with list: datafile" );
}

{
    #
    # Basic 1D sweep with points/step
    #

    my $source = dummysource();
    my $sweep  = sweep(
        type       => 'Step::Voltage',
        instrument => $source,
        points     => [ 0, 1, 2 ],
        step       => 0.5
    );

    my $datafile = sweep_datafile( columns => [qw/level value/] );

    my $value = 0;
    my $meas  = sub {
        my $sweep = shift;
        $sweep->log( level => $source->get_level, value => $value++ );
    };
    $sweep->start(
        measurement => $meas,
        datafile    => $datafile,
        folder      => $dir,

        # use default datafile_dim and point_dim
    );

    my $expected = <<"EOF";
# level\tvalue
0\t0
0.5\t1
1\t2
1\t3
1.5\t4
2\t5
EOF
    my $path = catfile( $sweep->foldername, 'data.dat' );
    file_ok( $path, $expected, "basic 1D sweep with list: datafile" );
}

{
    #
    # Basic 1D sweep with 2 datafiles
    #

    my $source = dummysource();
    my $sweep  = sweep(
        type       => 'Step::Voltage',
        instrument => $source,
        from       => 0,
        to         => 0.5,
        step       => 0.1
    );

    my $datafile = sweep_datafile( columns => [qw/level value/] );
    my $datafile2 = sweep_datafile(
        filename => 'data2',
        columns  => [qw/level value/]
    );
    my $value = 0;
    my $meas  = sub {
        my $sweep = shift;
        my $level = $source->get_level;
        $sweep->log(
            datafile => $datafile, level => $level,
            value    => $value++
        );
        $sweep->log(
            datafile => $datafile2, level => $level,
            value    => $value
        );

    };
    $sweep->start(
        measurement => $meas,
        datafiles   => [ $datafile, $datafile2 ],
        folder      => $dir,

        # use default datafile_dim and point_dim
    );

    my $expected = <<"EOF";
# level\tvalue
0\t0
0.1\t1
0.2\t2
0.3\t3
0.4\t4
0.5\t5
EOF
    my $foldername = $sweep->foldername;
    my $path = catfile( $foldername, 'data.dat' );
    file_ok( $path, $expected, "1D sweep 2 datafiles: datafile1" );
    $path = catfile( $foldername, 'data2.dat' );
    $expected = <<"EOF";
# level\tvalue
0\t1
0.1\t2
0.2\t3
0.3\t4
0.4\t5
0.5\t6
EOF
    file_ok( $path, $expected, "1D sweep 2 datafiles: datafile2" );

}

{
    #
    # Basic 2D sweep
    #

    my $gate       = dummysource();
    my $bias       = dummysource();
    my $gate_sweep = sweep(
        type       => 'Step::Voltage',
        instrument => $gate,
        from       => 0,
        to         => 2,
        step       => 1
    );

    my $bias_sweep = sweep(
        type       => 'Step::Voltage',
        instrument => $bias,
        from       => 0,
        to         => 2,
        step       => 1
    );

    my $datafile = sweep_datafile( columns => [qw/gate bias current/] );

    my $current = 0;
    my $meas    = sub {
        my $sweep = shift;
        $sweep->log(
            gate    => $gate->get_level(), bias => $bias->get_level(),
            current => $current++
        );
    };

    $gate_sweep->start(
        slave       => $bias_sweep,
        measurement => $meas,
        datafile    => $datafile,
        folder      => $dir,

        # use default datafile_dim and point_dim
    );

    my $expected = <<"EOF";
# gate\tbias\tcurrent
0\t0\t0
0\t1\t1
0\t2\t2

1\t0\t3
1\t1\t4
1\t2\t5

2\t0\t6
2\t1\t7
2\t2\t8

EOF
    my $path = catfile( $gate_sweep->foldername, 'data.dat' );
    file_ok( $path, $expected, "basic 2D sweep: datafile" );
}

{
    #
    # 2D sweep with subfolders (one point per datafile)
    #

    my $gate       = dummysource();
    my $bias       = dummysource();
    my $gate_sweep = sweep(
        type               => 'Step::Voltage',
        instrument         => $gate,
        from               => 0,
        to                 => 2,
        step               => 1,
        filename_extension => 'gate=',
    );

    my $bias_sweep = sweep(
        type               => 'Step::Voltage',
        instrument         => $bias,
        from               => 0,
        to                 => 2,
        step               => 1,
        filename_extension => 'bias=',
    );

    my $datafile = sweep_datafile( columns => [qw/gate bias current/] );

    my $current = 0;
    my $meas    = sub {
        my $sweep = shift;
        $sweep->log(
            gate    => $gate->get_level(), bias => $bias->get_level(),
            current => $current++
        );
    };

    $gate_sweep->start(
        slave        => $bias_sweep,
        measurement  => $meas,
        datafile     => $datafile,
        folder       => $dir,
        datafile_dim => 0,
    );

    my $foldername     = $gate_sweep->foldername;
    my @files          = bsd_glob( catfile( $foldername, '*/*' ) );
    my @expected_files = qw{
        gate=0/data_gate=0_bias=0.dat
        gate=0/data_gate=0_bias=1.dat
        gate=0/data_gate=0_bias=2.dat

        gate=1/data_gate=1_bias=0.dat
        gate=1/data_gate=1_bias=1.dat
        gate=1/data_gate=1_bias=2.dat

        gate=2/data_gate=2_bias=0.dat
        gate=2/data_gate=2_bias=1.dat
        gate=2/data_gate=2_bias=2.dat
    };
    @expected_files = map { catfile( $foldername, $_ ) } @expected_files;
    is_deeply(
        \@files, \@expected_files,
        "2D sweep with subfolders: output folder"
    );

    my $expected = <<"EOF";
# gate\tbias\tcurrent
2\t2\t8
EOF

    my $path = catfile( $foldername, 'gate=2', 'data_gate=2_bias=2.dat' );
    file_ok( $path, $expected, "2D sweep with subfolders: datafile" );
}

{
    #
    # 3D sweep
    #

    my $top  = dummysource();
    my $gate = dummysource();
    my $bias = dummysource();

    my $top_sweep = sweep(
        type               => 'Step::Voltage',
        instrument         => $top,
        from               => 0,
        to                 => 3,
        step               => 1,
        filename_extension => 'top=',
    );

    my $gate_sweep = sweep(
        type       => 'Step::Voltage',
        instrument => $gate,
        from       => 0,
        to         => 2,
        step       => 1
    );

    my $bias_sweep = sweep(
        type       => 'Step::Voltage',
        instrument => $bias,
        from       => 0,
        to         => 2,
        step       => 1
    );

    my $datafile = sweep_datafile( columns => [qw/top gate bias current/] );

    my $current = 0;
    my $meas    = sub {
        my $sweep = shift;
        $sweep->log(
            top  => $top->get_level(),  gate    => $gate->get_level(),
            bias => $bias->get_level(), current => $current++
        );
    };

    $top_sweep->start(
        slaves      => [ $gate_sweep, $bias_sweep ],
        measurement => $meas,
        datafile    => $datafile,
        folder      => $dir,

        # use default datafile_dim and point_dim
    );

    my $expected = <<"EOF";
# top\tgate\tbias\tcurrent
0\t0\t0\t0
0\t0\t1\t1
0\t0\t2\t2

0\t1\t0\t3
0\t1\t1\t4
0\t1\t2\t5

0\t2\t0\t6
0\t2\t1\t7
0\t2\t2\t8

EOF

    my $foldername = $top_sweep->foldername();
    my @files = bsd_glob( catfile( $foldername, '*' ) );
    my @expected_files
        = qw/data_top=0.dat data_top=1.dat data_top=2.dat data_top=3.dat META.yml Sweep.t/;

    @expected_files = map { catfile( $foldername, $_ ) } @expected_files;
    is_deeply( \@files, \@expected_files, "3D sweep: output folder" );

    my $path = catfile( $foldername, 'data_top=0.dat' );
    file_ok( $path, $expected, "3D sweep: datafile (top = 0)" );

    $expected =~ s/^0/2/mg;
    $expected =~ s/([0-9])$/$1 + 2*9/emg;
    $path = catfile( $foldername, 'data_top=2.dat' );
    file_ok( $path, $expected, "3D sweep: datafile (top = 2)" );
}

{
    #
    # 1D sweep and 1D data
    #

    my $source = dummysource();
    my $sweep  = sweep(
        type               => 'Step::Voltage',
        instrument         => $source,
        from               => 0,
        to                 => 3,
        step               => 1,
        filename_extension => 'level=',
    );

    my $datafile = sweep_datafile( columns => [qw/level frq value/] );

    my $value = 0;
    my $meas  = sub {
        my $sweep = shift;
        my $level = $source->get_level;
        my $block = [
            [ 1,      2,      3,      4,      5 ],
            [ $value, $value, $value, $value, $value ]
        ];
        ++$value;
        $sweep->log_block(
            prefix => { level => $level },
            block  => $block,
        );

    };
    $sweep->start(
        measurement => $meas,
        datafile    => $datafile,
        folder      => $dir,

        # one datafile for each call of the $meas sub
        point_dim    => 1,
        datafile_dim => 1,
    );

    my $foldername = $sweep->foldername;
    my @files = bsd_glob( catfile( $foldername, '*' ) );
    my @expected_files
        = qw/data_level=0.dat data_level=1.dat data_level=2.dat data_level=3.dat META.yml Sweep.t/;
    @expected_files = map { catfile( $foldername, $_ ) } @expected_files;
    is_deeply(
        \@files, \@expected_files,
        "1D Sweep with 1D data: output folder"
    );

    my $expected = <<"EOF";
# level\tfrq\tvalue
2\t1\t2
2\t2\t2
2\t3\t2
2\t4\t2
2\t5\t2
EOF
    my $path = catfile( $foldername, 'data_level=2.dat' );
    file_ok( $path, $expected, "1D Sweep with 1D data: datafile" );
}

{
    #
    # 1D sweep, 1D data and 2D datafile
    #

    my $source = dummysource();
    my $sweep  = sweep(
        type       => 'Step::Voltage',
        instrument => $source,
        from       => 0,
        to         => 2,
        step       => 1,
    );

    my $datafile = sweep_datafile( columns => [qw/level frq value/] );

    my $value = 0;
    my $meas  = sub {
        my $sweep = shift;
        my $level = $source->get_level;
        my $block = [
            [ 1,      2,      3,      4,      5 ],
            [ $value, $value, $value, $value, $value ]
        ];
        ++$value;
        $sweep->log_block(
            prefix => { level => $level },
            block  => $block,
        );

    };
    $sweep->start(
        measurement => $meas,
        datafile    => $datafile,
        folder      => $dir,

        # log all blocks into one datafile
        # datafile_dim defaults to 2
        point_dim => 1,

    );

    my $foldername     = $sweep->foldername;
    my @files          = bsd_glob( catfile( $foldername, '*' ) );
    my @expected_files = qw/data.dat META.yml Sweep.t/;
    @expected_files = map { catfile( $foldername, $_ ) } @expected_files;
    is_deeply(
        \@files, \@expected_files,
        "1D Sweep with 1D data: output folder"
    );

    my $expected = <<"EOF";
# level\tfrq\tvalue
0\t1\t0
0\t2\t0
0\t3\t0
0\t4\t0
0\t5\t0

1\t1\t1
1\t2\t1
1\t3\t1
1\t4\t1
1\t5\t1

2\t1\t2
2\t2\t2
2\t3\t2
2\t4\t2
2\t5\t2

EOF
    my $path = catfile( $foldername, 'data.dat' );
    file_ok( $path, $expected, "1D Sweep, 1D data, 2D datafile: datafile" );
}

{
    #
    # Two sweeps into one folder
    #
    my $folder = datafolder( path => $dir );
    my $source = dummysource();
    my $sweep1 = sweep(
        type       => 'Step::Voltage',
        instrument => $source,
        from       => 0,
        to         => 0.5,
        step       => 0.1
    );

    my $datafile1
        = sweep_datafile( filename => 'data1', columns => [qw/level value/] );

    my $value = 0;
    my $meas1 = sub {
        my $sweep = shift;
        $sweep->log( level => $source->get_level, value => $value++ );
    };
    $sweep1->start(
        measurement => $meas1,
        datafile    => $datafile1,
        folder      => $folder,
    );

    my $sweep2 = sweep(
        type       => 'Step::Voltage',
        instrument => $source,
        from       => 0,
        to         => 0.5,
        step       => 0.1
    );

    my $datafile2
        = sweep_datafile( filename => 'data2', columns => [qw/level value/] );

    my $meas2 = sub {
        my $sweep = shift;
        $sweep->log( level => $source->get_level, value => $value++ );
    };
    $sweep2->start(
        measurement => $meas2,
        datafile    => $datafile2,
        folder      => $folder,
    );

    my $foldername = $folder->path();

    my $expected1 = <<"EOF";
# level\tvalue
0\t0
0.1\t1
0.2\t2
0.3\t3
0.4\t4
0.5\t5
EOF
    my $path = catfile( $foldername, 'data1.dat' );
    file_ok( $path, $expected1, "sweep1: datafile" );

    my $expected2 = <<"EOF";
# level\tvalue
0\t6
0.1\t7
0.2\t8
0.3\t9
0.4\t10
0.5\t11
EOF
    $path = catfile( $foldername, 'data2.dat' );
    file_ok( $path, $expected2, "sweep2: datafile" );
}

{
    #
    # 1D sweep with backsweep
    #

    my $source = dummysource();
    my $sweep  = sweep(
        type               => 'Step::Voltage',
        instrument         => $source,
        from               => 0,
        to                 => 2,
        step               => 1,
        backsweep          => 1,
        filename_extension => '',

    );

    my $datafile = sweep_datafile( columns => [qw/level value/] );

    my $value = 0;
    my $meas  = sub {
        my $sweep = shift;
        $sweep->log( level => $source->get_level, value => $value++ );
    };
    $sweep->start(
        measurement  => $meas,
        datafile     => $datafile,
        folder       => $dir,
        datafile_dim => 0,
    );

    my $foldername     = $sweep->foldername;
    my @files          = bsd_glob( catfile( $foldername, '*' ) );
    my @expected_files = qw/
        data_0.dat
        data_0_backsweep.dat
        data_1.dat
        data_1_backsweep.dat
        data_2.dat
        data_2_backsweep.dat
        META.yml
        Sweep.t
        /;
    @expected_files = map { catfile( $foldername, $_ ) } @expected_files;
    is_deeply(
        \@files, \@expected_files,
        "1D Sweep with 1D data: output folder"
    );
}

{
    #
    # Step::Repeat
    #

    my $sweep = sweep(
        type  => 'Step::Repeat',
        count => 10,

    );

    my $datafile = sweep_datafile( columns => ['count'] );

    my $meas = sub {
        my $sweep = shift;
        my $c     = $sweep->get_value();
        $sweep->log( count => $c );
    };

    $sweep->start(
        measurement => $meas,
        datafile    => $datafile,
        folder      => $dir,
    );

    my $expected = <<"EOF";
# count
1
2
3
4
5
6
7
8
9
10
EOF
    my $path = catfile( $sweep->foldername, 'data.dat' );
    file_ok( $path, $expected, "Step::Repeat: datafile" );
}

done_testing();
