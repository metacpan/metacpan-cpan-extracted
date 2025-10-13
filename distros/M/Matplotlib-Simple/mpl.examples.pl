#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use warnings::unused;
use autodie ':all';
use feature 'say';
use File::Temp 'tempfile';
use DDP { output => 'STDOUT', array_max => 10, show_memsize => 1 };
use Devel::Confess 'color';
use Matplotlib::Simple 'plot';

sub linspace {    # mostly written by Grok
    my ( $start, $stop, $num, $endpoint ) = @_;   # endpoint means include $stop
    $num      = defined $num      ? int($num) : 50;    # Default to 50 points
    $endpoint = defined $endpoint ? $endpoint : 1; # Default to include endpoint
    return ()       if $num < 0;     # Return empty array for invalid num
    return ($start) if $num == 1;    # Return single value if num is 1
    my ( @result, $step );

    if ($endpoint) {
        $step = ( $stop - $start ) / ( $num - 1 ) if $num > 1;
        for my $i ( 0 .. $num - 1 ) {
            $result[$i] = $start + $i * $step;
        }
    }
    else {
        $step = ( $stop - $start ) / $num;
        for my $i ( 0 .. $num - 1 ) {
            $result[$i] = $start + $i * $step;
        }
    }
    return @result;
}

sub generate_normal_dist {
    my ( $mean, $std_dev, $size ) = @_;
    $size = defined $size ? int $size : 100;    # default to 100 points
    my @numbers;
    for ( 1 .. int( $size / 2 ) + 1 ) {         # Box-Muller transform
        my $u1 = rand();
        my $u2 = rand();
        my $z0 = sqrt( -2.0 * log($u1) ) * cos( 2.0 * 3.141592653589793 * $u2 );
        my $z1 = sqrt( -2.0 * log($u1) ) * sin( 2.0 * 3.141592653589793 * $u2 )
          ;    # Scale and shift to match mean and std_dev
        push @numbers, ( $z0 * $std_dev + $mean, $z1 * $std_dev + $mean );
    }    # Trim to exact size if needed
    @numbers = @numbers[ 0 .. $size - 1 ] if @numbers > $size;
    @numbers = map { sprintf '%.1f', $_ } @numbers;
    return \@numbers;
}

sub rand_between {
    my ( $min, $max ) = @_;
    return $min + rand( $max - $min );
}

# generate random numbers for ROC-like distributions
my @xw = linspace( 0.1, 1, 100 );
my @y  = map { 2 - 1 / $_ } @xw;
my ( $fh, $tmp_filename ) =
  tempfile( DIR => '/tmp', SUFFIX => '.py', UNLINK => 0 );
close $fh;
plot(
    {
        data => {
            Clinical => [
                [
                    [@xw],    # x
                    [@y]      # y
                ],
                [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ],
                [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ]
            ],
            HGI => [
                [
                    [@xw],                            # x
                    [ map { 1.9 - 1.1 / $_ } @xw ]    # y
                ],
                [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ],
                [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ]
            ]
        },
        'output.filename' => 'output.images/single.wide.png',
        'plot.type'       => 'wide',
        color             => {
            Clinical => 'blue',
            HGI      => 'green'
        },
        title        => 'Visualization of similar lines plotted together',
        'input.file' => $tmp_filename,
        execute      => 0,
    }
);
plot(
    {
        data => [
            [
                [@xw],    # x
                [@y]      # y
            ],
            [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ],
            [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ]
        ],
        'output.filename' => 'output.images/single.array.png',
        'plot.type'       => 'wide',
        color             => 'red',
        title             => 'Visualization of similar lines plotted together',
        'input.file'      => $tmp_filename,
        execute           => 0,
    }
);
plot(
    {
        plots => [
            {
                data => [
                    [
                        [@xw],    # x
                        [@y]      # y
                    ],
                    [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ],
                    [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ]
                ],
                'plot.type' => 'wide',
                color       => 'red',
                title       => 'Visualization of similar lines plotted together'
            }
        ],
        'output.filename' => 'output.images/wide.subplots.png',
        suptitle          => 'SubPlots',
        'input.file'      => $tmp_filename,
        execute           => 0,
    }
);
plot(
    {
        'output.filename' => 'output.images/single.pie.png',
        data              => {                                 # simple hash
            Fri => 76,
            Mon => 73,
            Sat => 26,
            Sun => 11,
            Thu => 94,
            Tue => 93,
            Wed => 77
        },
        'plot.type'  => 'pie',
        title        => 'Single Simple Pie',
        'input.file' => $tmp_filename,
        execute      => 0,
    }
);
plot(
    {
        'output.filename' => 'output.images/pie.png',
        plots             => [
            {
                data => {
                    'Russian' => 106_000_000,    # Primarily European Russia
                    'German'  =>
                      95_000_000,    # Germany, Austria, Switzerland, etc.
                    'English' => 70_000_000,      # UK, Ireland, etc.
                    'French' => 66_000_000, # France, Belgium, Switzerland, etc.
                    'Italian'   => 59_000_000,    # Italy, Switzerland, etc.
                    'Spanish'   => 45_000_000,    # Spain
                    'Polish'    => 38_000_000,    # Poland
                    'Ukrainian' => 32_000_000,    # Ukraine
                    'Romanian'  => 24_000_000,    # Romania, Moldova
                    'Dutch'     => 22_000_000     # Netherlands, Belgium
                },
                'plot.type' => 'pie',
                title       => 'Top Languages in Europe',
                suptitle    => 'Pie in subplots',
            },
            {
                data => {
                    'Russian' => 106_000_000,     # Primarily European Russia
                    'German'  =>
                      95_000_000,    # Germany, Austria, Switzerland, etc.
                    'English' => 70_000_000,      # UK, Ireland, etc.
                    'French' => 66_000_000, # France, Belgium, Switzerland, etc.
                    'Italian'   => 59_000_000,    # Italy, Switzerland, etc.
                    'Spanish'   => 45_000_000,    # Spain
                    'Polish'    => 38_000_000,    # Poland
                    'Ukrainian' => 32_000_000,    # Ukraine
                    'Romanian'  => 24_000_000,    # Romania, Moldova
                    'Dutch'     => 22_000_000     # Netherlands, Belgium
                },
                'plot.type' => 'pie',
                title       => 'Top Languages in Europe',
                autopct     => '%1.1f%%',
            },
            {
                data => {
                    'United States'  => 86,
                    'United Kingdom' => 33,
                    'Germany'        => 29,
                    'France'         => 10,
                    'Japan'          => 7,
                    'Israel'         => 6,
                },
                title         => 'Chem. Nobels: swap text positions',
                'plot.type'   => 'pie',
                set_figwidth  => 12,
                autopct       => '%1.1f%%',
                pctdistance   => 1.25,
                labeldistance => 0.6,
            }
        ],
        'input.file' => $tmp_filename,
        execute      => 0,
        ncols        => 3,
    }
);
my $x = generate_normal_dist( 100, 15, 3 * 10 );
my $y = generate_normal_dist( 85,  15, 3 * 10 );
my $z = generate_normal_dist( 106, 15, 3 * 10 );

# single plots are simple
plot(
    {
        'output.filename' => 'output.images/single.boxplot.png',
        data              => {                                     # simple hash
            E => [ 55,    @{$x}, 160 ],
            B => [ @{$y}, 140 ],

            #		A => @a
        },
        'plot.type'  => 'boxplot',
        title        => 'Single Box Plot: Specified Colors',
        colors       => { E => 'yellow', B => 'purple' },
        'input.file' => $tmp_filename,
        execute      => 0,
    }
);
plot(
    {
        'output.filename' => 'output.images/boxplot.png',
        execute           => 0,
        'input.file'      => $tmp_filename,
        plots             => [
            {
                data => {
                    A => [ 55, @{$z} ],
                    E => [ @{$y} ],
                    B => [ 122, @{$z} ],
                },
                title       => 'Simple Boxplot',
                ylabel      => 'ylabel',
                xlabel      => 'label',
                'plot.type' => 'boxplot',
                suptitle    => 'Boxplot examples'
            },
            {
                color => 'pink',
                data  => {
                    A => [ 55, @{$z} ],
                    E => [ @{$y} ],
                    B => [ 122, @{$z} ],
                },
                title       => 'Specify single color',
                ylabel      => 'ylabel',
                xlabel      => 'label',
                'plot.type' => 'boxplot'
            },
            {
                colors => {
                    A => 'orange',
                    E => 'yellow',
                    B => 'purple'
                },
                data => {
                    A => [ 55, @{$z} ],
                    E => [ @{$y} ],
                    B => [ 122, @{$z} ],
                },
                title       => 'Specify set-specific color; showfliers = False',
                ylabel      => 'ylabel',
                xlabel      => 'label',
                'plot.type' => 'boxplot',
                showmeans   => 'True',
                showfliers  => 'False',
                set_figwidth => 12
            },
            {
                colors => {
                    A => 'orange',
                    E => 'yellow',
                    B => 'purple'
                },
                data => {
                    A => [ 55, @{$z} ],
                    E => [ @{$y} ],
                    B => [ 122, @{$z} ],
                },
                title       => 'Specify set-specific color; showmeans = False',
                ylabel      => 'ylabel',
                xlabel      => 'label',
                'plot.type' => 'boxplot',
                showmeans   => 'False',
            },
            {
                colors => {
                    A => 'orange',
                    E => 'yellow',
                    B => 'purple'
                },
                data => {
                    A => [ 55, @{$z} ],
                    E => [ @{$y} ],
                    B => [ 122, @{$z} ],
                },
                title       => 'Set-specific color; orientation = horizontal',
                ylabel      => 'ylabel',
                xlabel      => 'label',
                orientation => 'horizontal',
                'plot.type' => 'boxplot',
            },
            {
                colors => {
                    A => 'orange',
                    E => 'yellow',
                    B => 'purple'
                },
                data => {
                    A => [ 55, @{$z} ],
                    E => [ @{$y} ],
                    B => [ 122, @{$z} ],
                },
                title       => 'Notch = True',
                ylabel      => 'ylabel',
                xlabel      => 'label',
                notch       => 'True',
                'plot.type' => 'boxplot',
            },
            {
                colors => {
                    A => 'orange',
                    E => 'yellow',
                    B => 'purple'
                },
                data => {
                    A => [ 55, @{$z} ],
                    E => [ @{$y} ],
                    B => [ 122, @{$z} ],
                },
                title         => 'showcaps = False',
                ylabel        => 'ylabel',
                xlabel        => 'label',
                showcaps      => 'False',
                'plot.type'   => 'boxplot',
                set_figheight => 12,
            },
        ],
        ncols => 3,
        nrows => 3,
    }
);
plot(
    {
        'output.filename' => 'output.images/single.violinplot.png',
        data              => {                                     # simple hash
            A => [ 55, @{$z} ],
            E => [ @{$y} ],
            B => [ 122, @{$z} ],
        },
        'plot.type'  => 'violinplot',
        title        => 'Single Violin Plot: Specified Colors',
        colors       => { E => 'yellow', B => 'purple', A => 'green' },
        'input.file' => $tmp_filename,
        execute      => 0,
    }
);
plot(
    {
        'input.file'      => $tmp_filename,
        execute           => 0,
        'output.filename' => 'output.images/violin.png',
        plots             => [
            {
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 210 ),
                    B => generate_normal_dist( 85,  15, 3 * 210 )
                },
                'plot.type'  => 'violinplot',
                title        => 'Basic',
                xlabel       => 'xlabel',
                set_figwidth => 12,
                suptitle     => 'Violinplot'
            },
            {
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 210 ),
                    B => generate_normal_dist( 85,  15, 3 * 210 )
                },
                'plot.type' => 'violinplot',
                color       => 'red',
                title       => 'Set Same Color for All',
            },
            {
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 110 ),
                    B => generate_normal_dist( 85,  15, 3 * 110 )
                },
                'plot.type' => 'violinplot',
                colors      => {
                    E => 'yellow',
                    B => 'black'
                },
                title => 'Color by Key',
            },
            {
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 110 ),
                    B => generate_normal_dist( 85,  15, 3 * 110 )
                },
                orientation => 'horizontal',
                'plot.type' => 'violinplot',
                colors      => {
                    E => 'yellow',
                    B => 'black'
                },
                title => 'Horizontal orientation',
            },
            {
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 110 ),
                    B => generate_normal_dist( 85,  15, 3 * 110 )
                },
                whiskers    => 0,
                'plot.type' => 'violinplot',
                colors      => {
                    E => 'yellow',
                    B => 'black'
                },
                title => 'Whiskers off',
            },
        ],
        ncols => 3,
        nrows => 2,
    }
);
plot(
    {
        'output.filename' => 'output.images/single.barplot.png',
        data              => {                                     # simple hash
            Fri => 76,
            Mon => 73,
            Sat => 26,
            Sun => 11,
            Thu => 94,
            Tue => 93,
            Wed => 77
        },
        'plot.type'  => 'bar',
        xlabel       => '# of Days',
        ylabel       => 'Count',
        title        => 'Customer Calls by Days',
        execute      => 0,
        'input.file' => $tmp_filename,
    }
);
plot(
    {
        data => {
            E => generate_normal_dist( 100, 15, 3 * 210 ),
            B => generate_normal_dist( 85,  15, 3 * 210 )
        },
        execute           => 0,
        'input.file'      => $tmp_filename,
        'output.filename' => 'output.images/single.hexbin.png',
        'plot.type'       => 'hexbin',
        set_figwidth      => 12,
        title             => 'Simple Hexbin',
    }
);
plot(
    {
        'output.filename' => 'output.images/single.hist2d.png',
        data              => {
            E => generate_normal_dist( 100, 15, 3 * 210 ),
            B => generate_normal_dist( 85,  15, 3 * 210 )
        },
        'plot.type'  => 'hist2d',
        title        => 'title',
        execute      => 0,
        'input.file' => $tmp_filename,
    }
);
plot(
    {
        'input.file'      => $tmp_filename,
        execute           => 0,
        'output.filename' => 'output.images/hexbin.png',
        plots             => [
            {
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 210 ),
                    B => generate_normal_dist( 85,  15, 3 * 210 )
                },
                'plot.type'  => 'hexbin',
                title        => 'Simple Hexbin',
                xlabel       => 'xlabel',
                set_figwidth => 12,
            },
            {
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 210 ),
                    B => generate_normal_dist( 85,  15, 3 * 210 )
                },
                'plot.type' => 'hexbin',
                title       => 'colorbar logscale',
                cb_logscale => 1
            }
        ],
        ncols => 2
    }
);
my $pi = atan2( 0, -1 );
my @x  = linspace( -2 * $pi, 2 * $pi, 100, 1 );
plot(
    {
        'input.file'      => $tmp_filename,
        execute           => 0,
        'output.filename' => 'output.images/plot.png',
        plots             => [
            {    # plot 1
                data => {
                    'sin(x)' => [
                        [@x],                     # x
                        [ map { sin($_) } @x ]    # y
                    ],
                    'cos(x)' => [
                        [@x],                     # x
                        [ map { cos($_) } @x ]    # y
                    ],
                },
                'plot.type' => 'plot',
                title       => 'simple plot',
                set_xticks  =>
"[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
                  . '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']',
                'set.options' => {    # set options overrides global settings
                    'sin(x)' => 'color="blue", linewidth=2',
                    'cos(x)' => 'color="red",  linewidth=2'
                },
                set_xlim => "$x[0], $x[-1]",    # set min and max as a string
            },
            {                                   # plot 2
                data => {
                    'csc(x)' => [
                        [@x],                         # x
                        [ map { 1 / sin($_) } @x ]    # y
                    ],
                    'sec(x)' => [
                        [@x],                         # x
                        [ map { 1 / cos($_) } @x ]    # y
                    ],
                },
                'plot.type' => 'plot',
                title       => 'simple plot',
                set_xticks  =>
"[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
                  . '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']',
                'set.options' => {    # set options overrides global settings
                    'csc(x)' => 'color="purple", linewidth=2',
                    'sec(x)' => 'color="green",  linewidth=2'
                },
                set_xlim => "$x[0], $x[-1]",    # set min and max as a string
                set_ylim => '-9,9',
            },
        ],
        ncols        => 2,
        set_figwidth => 12,
    }
);
plot(
    {
        'input.file'      => $tmp_filename,
        execute           => 0,
        'output.filename' => 'output.images/plot.single.png',
        data              => {
            'sin(x)' => [
                [@x],                     # x
                [ map { sin($_) } @x ]    # y
            ],
            'cos(x)' => [
                [@x],                     # x
                [ map { cos($_) } @x ]    # y
            ],
        },
        'plot.type' => 'plot',
        title       => 'simple plot',
        set_xticks  =>
"[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
          . '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']',
        'set.options' => {    # set options overrides global settings
            'sin(x)' => 'color="blue", linewidth=2',
            'cos(x)' => 'color="red",  linewidth=2'
        }
    }
);
plot(
    {
        'input.file'      => $tmp_filename,
        execute           => 0,
        'output.filename' => 'output.images/barplots.png',
        plots             => [
            {    # simple plot
                data => {    # simple hash
                    Fri => 76,
                    Mon => 73,
                    Sat => 26,
                    Sun => 11,
                    Thu => 94,
                    Tue => 93,
                    Wed => 77
                },
                'plot.type' => 'bar',
                'key.order' =>
                  [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' ],
                suptitle => 'Types of Plots',    # applies to all
                color    => [
                    'red',  'orange', 'yellow', 'green',
                    'blue', 'indigo', 'fuchsia'
                ],
                edgecolor     => 'black',
                set_figwidth  => 40 / 1.5,       # applies to all plots
                set_figheight => 30 / 2,         # applies to all plots
                title         => 'bar: Rejections During Job Search',
                xlabel        => 'Day of the Week',
                ylabel        => 'No. of Rejections'
            },
            {                                    # grouped bar plot
                'plot.type' => 'bar',
                data        => {
                    1941 => {
                        UK      => 6.6,
                        US      => 6.2,
                        USSR    => 17.8,
                        Germany => 26.6
                    },
                    1942 => {
                        UK      => 7.6,
                        US      => 26.4,
                        USSR    => 19.2,
                        Germany => 29.7
                    },
                    1943 => {
                        UK      => 7.9,
                        US      => 61.4,
                        USSR    => 22.5,
                        Germany => 34.9
                    },
                    1944 => {
                        UK      => 7.4,
                        US      => 80.5,
                        USSR    => 27.0,
                        Germany => 31.4
                    },
                    1945 => {
                        UK      => 5.4,
                        US      => 83.1,
                        USSR    => 25.5,
                        Germany => 11.2    #Rapid decrease due to war's end
                    },
                },
                stacked => 0,
                title   => 'Hash of Hash Grouped Unstacked Barplot',
                xlabel  => 'r"$\it{anno}$ $\it{domini}$"',             # italic
                ylabel  => 'Military Expenditure (Billions of $)'
            },
            {    # grouped bar plot
                'plot.type' => 'bar',
                data        => {
                    1941 => {
                        UK      => 6.6,
                        US      => 6.2,
                        USSR    => 17.8,
                        Germany => 26.6
                    },
                    1942 => {
                        UK      => 7.6,
                        US      => 26.4,
                        USSR    => 19.2,
                        Germany => 29.7
                    },
                    1943 => {
                        UK      => 7.9,
                        US      => 61.4,
                        USSR    => 22.5,
                        Germany => 34.9
                    },
                    1944 => {
                        UK      => 7.4,
                        US      => 80.5,
                        USSR    => 27.0,
                        Germany => 31.4
                    },
                    1945 => {
                        UK      => 5.4,
                        US      => 83.1,
                        USSR    => 25.5,
                        Germany => 11.2    #Rapid decrease due to war's end
                    },
                },
                stacked => 1,
                title   => 'Hash of Hash Grouped Stacked Barplot',
                xlabel  => 'r"$\it{anno}$ $\it{domini}$"',           # italic
                ylabel  => 'Military Expenditure (Billions of $)'
            },
            { # grouped barplot: arrays indicate Union, Confederate which must be specified in options hash
                data =>
                  { # 4th plot: arrays indicate Union, Confederate which must be specified in options hash
                    'Antietam'         => [ 12400, 10300 ],
                    'Gettysburg'       => [ 23000, 28000 ],
                    'Chickamauga'      => [ 16000, 18000 ],
                    'Chancellorsville' => [ 17000, 13000 ],
                    'Wilderness'       => [ 17500, 11000 ],
                    'Spotsylvania'     => [ 18000, 12000 ],
                    'Cold Harbor'      => [ 12000, 5000 ],
                    'Shiloh'           => [ 13000, 10700 ],
                    'Second Bull Run'  => [ 10000, 8000 ],
                    'Fredericksburg'   => [ 12600, 5300 ],
                  },
                'plot.type' => 'barh',
                color       => [ 'blue', 'gray' ]
                ,    # colors match indices of data arrays
                label => [ 'North', 'South' ]
                ,    # colors match indices of data arrays
                xlabel => 'Casualties',
                ylabel => 'Battle',
                title  => 'barh: hash of array'
            },
            {        # 5th plot: barplot with groups
                data => {
                    1942 => [ 109867, 310000,  7700000 ],    # US, Japan, USSR
                    1943 => [ 221111, 440000,  9000000 ],
                    1944 => [ 318584, 610000,  7000000 ],
                    1945 => [ 318929, 1060000, 3000000 ],
                },
                color => [ 'blue', 'pink', 'red' ]
                ,    # colors match indices of data arrays
                label => [ 'USA', 'Japan', 'USSR' ]
                ,    # colors match indices of data arrays
                'log'       => 1,
                title       => 'grouped bar: Casualties in WWII',
                ylabel      => 'Casualties',
                'plot.type' => 'bar'
            },
            {        # nuclear weapons barplot
                'plot.type' => 'bar',
                color       => 'red',
                data        => {
                    'USA'         => 5277,    # FAS Estimate
                    'Russia'      => 5449,    # FAS Estimate
                    'UK'          => 225,     # Consistent estimate
                    'France'      => 290,     # Consistent estimate
                    'China'       => 600,     # FAS Estimate
                    'India'       => 180,     # FAS Estimate
                    'Pakistan'    => 130,     # FAS Estimate
                    'Israel'      => 90,      # FAS Estimate
                    'North Korea' => 50,      # FAS Estimate
                },
                edgecolor => 'blue',
                label     => 'labelXXX',
                title     => 'Simple hash for barchart with yerr',
                xlabel    => 'Country',
                yerr      => {
                    'USA'         => [ 15,  29 ],
                    'Russia'      => [ 199, 1000 ],
                    'UK'          => [ 15,  19 ],
                    'France'      => [ 19,  29 ],
                    'China'       => [ 200, 159 ],
                    'India'       => [ 15,  25 ],
                    'Pakistan'    => [ 15,  49 ],
                    'Israel'      => [ 90,  50 ],
                    'North Korea' => [ 10,  20 ],
                },
                ylabel    => '# of Nuclear Warheads',
                linewidth => 2,
                'log'     => 'True',                    #	linewidth				=> 1,
            }
        ],
        ncols => 3,
        nrows => 4
    }
);
plot(
    {
        'input.file'      => $tmp_filename,
        execute           => 0,
        'output.filename' => 'output.images/histogram.png',
        plots             => [
            {    # simple histogram
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 210 ),
                    B => generate_normal_dist( 100, 15, 3 * 210 ),
                    A => generate_normal_dist( 100, 15, 3 * 210 ),
                },
                'plot.type' => 'hist',
                alpha       => 0.25,
                bins        => 50,
                title       => 'alpha = 0.25',
                color       => {
                    B => 'Black',
                    E => 'Orange',
                    A => 'Yellow',
                },
                scatter => '['
                  . join( ',', 22 .. 44 ) . '],['
                  . join( ',', 22 .. 44 )
                  . '], label = "scatter"',
                xlabel   => 'Value',
                ylabel   => 'Frequency',
                suptitle =>
                  'Types of Plots',    # applies to all #				'log'					=> 1,
            },
            {                          # simple histogram
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 210 ),
                    B => generate_normal_dist( 100, 15, 3 * 210 ),
                    A => generate_normal_dist( 100, 15, 3 * 210 ),
                },
                'plot.type' => 'hist',
                alpha       => 0.75,
                bins        => 50,
                title       => 'alpha = 0.75',
                color       => {
                    B => 'Black',
                    E => 'Orange',
                    A => 'Yellow',
                },
                xlabel   => 'Value',
                ylabel   => 'Frequency',
                suptitle =>
                  'Types of Plots',    # applies to all #				'log'					=> 1,
            },
            {                          # simple histogram
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 210 ),
                    B => generate_normal_dist( 100, 15, 3 * 210 ),
                    A => generate_normal_dist( 100, 15, 3 * 210 ),
                },
                'plot.type' => 'hist',
                alpha       => 0.75,
                bins        => {
                    A => 10,
                    B => 25,
                    E => 50
                },
                title => 'Varying # of bins',
                color => {
                    B => 'Black',
                    E => 'Orange',
                    A => 'Yellow',
                },
                xlabel       => 'Value',
                ylabel       => 'Frequency',
                set_figwidth => 15,
                suptitle     =>
                  'Types of Plots',    # applies to all #				'log'					=> 1,
            },
            {                          # simple histogram
                data => {
                    E => generate_normal_dist( 100, 15, 3 * 210 ),
                    B => generate_normal_dist( 100, 15, 3 * 210 ),
                    A => generate_normal_dist( 100, 15, 3 * 210 ),
                },
                'plot.type' => 'hist',
                alpha       => 0.75,
                color       => {
                    B => 'Black',
                    E => 'Orange',
                    A => 'Yellow',
                },
                orientation  => 'horizontal',    # assign x and y labels smartly
                set_figwidth => 15,
                suptitle     => 'Types of Plots',           # applies to all
                title        => 'Horizontal orientation',
                ylabel       => 'Value',
                xlabel       => 'Frequency',                #				'log'					=> 1,
            },
        ],
        ncols => 3,
        nrows => 2,
    }
);
plot(
    {
        'input.file'      => $tmp_filename,
        'output.filename' => 'output.images/scatterplots.png',
        execute           => 0,
        nrows             => 2,
        ncols             => 3,
        set_figheight     => 8,
        set_figwidth      => 16,
        suptitle          => 'Scatterplot Examples',            # applies to all
        plots             => [
            {    # single-set scatter; no label
                data => {
                    X => generate_normal_dist( 100, 15, 210 ),    # x-axis
                    Y => generate_normal_dist( 100, 15, 210 ),    # y-axis
                    Z => generate_normal_dist( 100, 15, 210 )     # color
                },
                title     => '"Single Set Scatterplot: Random Distributions"',
                color_key => 'Z',
                'set.options' => 'marker = "v"'
                , # arguments to ax.scatter: there's only 1 set, so "set.options" is a scalar
                text        => [ '100, 100, "text1"', '100, 100, "text2"', ],
                'plot.type' => 'scatter',
            },
            {     # multiple-set scatter, labels are "X" and "Y"
                data => {
                    X => {    # 1st data set; label is "X"
                        A => generate_normal_dist( 100, 15, 210 ),    # x-axis
                        B => generate_normal_dist( 100, 15, 210 ),    # y-axis
                    },
                    W => {    # 2nd data set; label is "Y"
                        A => generate_normal_dist( 100, 15, 210 ),    # x-axis
                        B => generate_normal_dist( 100, 15, 210 ),    # y-axis
                    }
                },
                'plot.type'   => 'scatter',
                title         => 'Multiple Set Scatterplot',
                'set.options' =>
                  {    # arguments to ax.scatter, for each set in data
                    X => 'marker = ".", color = "red"',
                    W => 'marker = "d", color = "green"'
                  },
            },
            {          # multiple-set scatter, labels are "X" and "Y"
                data => {    # 8th plot,
                    X => {    # 1st data set; label is "X"
                        A => generate_normal_dist( 100, 15, 210 ),    # x-axis
                        B => generate_normal_dist( 100, 15, 210 ),    # y-axis
                        C => generate_normal_dist( 100, 15, 210 ),    # color
                    },
                    Y => {    # 2nd data set; label is "Y"
                        A => generate_normal_dist( 100, 15, 210 ),    # x-axis
                        B => generate_normal_dist( 100, 15, 210 ),    # y-axis
                        C => generate_normal_dist( 100, 15, 210 ),    # color
                    },
                },
                'plot.type'   => 'scatter',
                title         => 'Multiple Set Scatter w/ colorbar',
                'set.options' =>
                  {    # arguments to ax.scatter, for each set in data
                    X => 'marker = "."',    # diamond
                    Y => 'marker = "d"'     # diamond
                  },
                color_key => 'Z',
            }
        ]
    }
);
plot(
    {
        plots => [
            {
                data => {
                    X => generate_normal_dist( 100, 15, 210 ),    # x-axis
                    Y => generate_normal_dist( 100, 15, 210 ),    # y-axis
                },
                'plot.type' => 'hist2d',
                title       => 'Simple hist2d',
                suptitle    => 'Types of hist2d plots'
            },
            {
                data => {
                    X => generate_normal_dist( 100, 15, 210 ),    # x-axis
                    Y => generate_normal_dist( 100, 15, 210 ),    # y-axis
                },
                'plot.type' => 'hist2d',
                title       => 'different cmap',
                cmap        => 'terrain'
            },
            {
                cmap => 'ocean',
                data => {
                    X => generate_normal_dist( 100, 15, 210 ),    # x-axis
                    Y => generate_normal_dist( 100, 15, 210 ),    # y-axis
                },
                'plot.type' => 'hist2d',
                title => 'cmap = ocean and set colorbar range with vmin/vmax',
                set_figwidth => 15,
                vmin         => -2,
                vmax         => 14
            },
            {
                data => {
                    X => generate_normal_dist( 100, 15, 210 ),    # x-axis
                    Y => generate_normal_dist( 100, 15, 210 ),    # y-axis
                },
                'plot.type' => 'hist2d',
                title       => 'density = True',
                cmap        => 'terrain',
                density     => 'True'
            },
            {
                data => {
                    X => generate_normal_dist( 100, 15, 210 ),    # x-axis
                    Y => generate_normal_dist( 100, 15, 210 ),    # y-axis
                },
                'plot.type' => 'hist2d',
                title       => 'key.order flips axes',
                cmap        => 'terrain',
                'key.order' => [ 'Y', 'X' ]
            },
        ],
        'input.file'      => $tmp_filename,
        'output.filename' => 'output.images/hist2d.png',
        execute           => 1,
        nrows             => 2,
        ncols             => 3,
    }
);

