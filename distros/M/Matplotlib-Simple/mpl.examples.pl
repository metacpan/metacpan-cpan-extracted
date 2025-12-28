#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use autodie ':all';
use feature 'say';
use File::Temp 'tempfile';
use Matplotlib::Simple;
# Λέγω οὖν, μὴ ἀπώσατο ὁ θεὸς
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
	} else {
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
my $pi = atan2( 0, -1 );
my $x = generate_normal_dist( 100, 15, 3 * 10 );
my $y = generate_normal_dist( 85,  15, 3 * 10 );
my $z = generate_normal_dist( 106, 15, 3 * 10 );
my @x  = linspace( -2 * $pi, 2 * $pi, 100, 1 );
my $fh = File::Temp->new( DIR => '/tmp', SUFFIX => '.py', UNLINK => 0 );
plt({
	'output.file' => 'output.images/add.single.png',
	'plot.type'       => 'plot',
	data              => {
		'sin(2x)'       => [
			[@x],
			[map {sin(2*$_)} @x]
		]
	},
	title             => 'Multiple plots',
	'set.options'     => {
		'sin(2x)' => 'color = "green"'
	},
	add               => [
		{
			data              => {
				'sin(x)'       => [
					[@x],
					[map {sin($_)} @x]
				]
			},
			'plot.type' => 'plot',
			'set.options' => {
				'sin(x)'	=>  'color = "red", linestyle = "dashed"'
			}
		},
		{
			data              => {
				'cos(x)'       => [
					[@x],
					[map {cos($_)} @x]
				]
			},
			'plot.type' => 'plot',
			'set.options' => {
				'cos(x)'	=>  'color = "blue", linestyle = "dashed"'
			}
		},
	],
	fh => $fh,
	execute      => 0,
});
plt({
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
	'output.file' => 'output.images/single.wide.png',
	'plot.type'       => 'wide',
	color             => {
		Clinical => 'blue',
		HGI      => 'green'
	},
	title        => 'Visualization of similar lines plotted together',
	fh => $fh,
	execute      => 0,
});
plt({
	data => [
		[
		    [@xw],    # x
		    [@y]      # y
		],
		[ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ],
		[ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ]
	],
	'output.file' => 'output.images/single.array.png',
	'plot.type'       => 'wide',
	color             => 'red',
	title             => 'Visualization of similar lines plotted together',
	fh => $fh,
	execute           => 0,
});
plt({
	plots => [
		{ # start first plot
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
	'output.file' => 'output.images/wide.subplots.png',
	suptitle          => 'SubPlots',
	fh => $fh,
	execute           => 0,
});
pie({
	'output.file' => 'output.images/single.pie.png',
	data              => {                                 # simple hash
		Fri => 76,
		Mon => 73,
		Sat => 26,
		Sun => 11,
		Thu => 94,
		Tue => 93,
		Wed => 77
	},
	title        => 'Single Simple Pie',
	fh => $fh,
	execute      => 0,
});
plt({
	'output.file' => 'output.images/pie.png',
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
		    autopct       => '%1.1f%%',
		    pctdistance   => 1.25,
		    labeldistance => 0.6,
		}
	],
	fh => $fh,
	execute      => 0,
   set_figwidth  => 12,
	ncols        => 3,
});

# single plots are simple
plt({
        'output.file' => 'output.images/single.boxplot.png',
        data              => {                                     # simple hash
            E => [ 55,    @{$x}, 160 ],
            B => [ @{$y}, 140 ],

            #		A => @a
        },
        'plot.type'  => 'boxplot',
        title        => 'Single Box Plot: Specified Colors',
        colors       => { E => 'yellow', B => 'purple' },
        fh => $fh,
        execute      => 0,
});
plt({
	'output.file' => 'output.images/boxplot.png',
	execute           => 0,
	fh => $fh,
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
		},
	],
	ncols => 3,
	nrows => 3,
   set_figheight => 12,
   set_figwidth => 12
});
plt({
	'output.file' => 'output.images/single.violinplot.png',
	data              => {                                     # simple hash
		A => [ 55, @{$z} ],
		E => [ @{$y} ],
		B => [ 122, @{$z} ],
	},
	'plot.type'  => 'violinplot',
	title        => 'Single Violin Plot: Specified Colors',
	colors       => { E => 'yellow', B => 'purple', A => 'green' },
	fh => $fh,
	execute      => 0,
});
my @e = generate_normal_dist( 100, 15, 3 * 200 );
my @b = generate_normal_dist( 85,  15, 3 * 200 );
my @a = generate_normal_dist( 105, 15, 3 * 200 );
plt({
	fh => $fh,
	execute           => 0,
	'output.file' => 'output.images/violin.png',
	plots             => [
		{
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type'  => 'violinplot',
		    title        => 'Basic',
		    xlabel       => 'xlabel',
		    set_figwidth => 12,
		    suptitle     => 'Violinplot'
		},
		{
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type' => 'violinplot',
		    color       => 'red',
		    title       => 'Set Same Color for All',
		},
		{
		    data => {
		        E => @e,
		        B => @b
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
		        E => @e,
		        B => @b
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
		        E => @e,
		        B => @b
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
});
plt({
	data              => { # simple hash
		Fri => 76,
		Mon => 73,
		Sat => 26,
		Sun => 11,
		Thu => 94,
		Tue => 93,
		Wed => 77
	},
	execute      => 0,
	fh           => $fh,
	'output.file' => 'output.images/single.barplot.png',
	'plot.type'  => 'bar',
	title        => 'Customer Calls by Days',
	xlabel       => '# of Days',
	ylabel       => 'Count',
});
plt({
	data => {
		E => @e,
		B => @b,
	},
	execute           => 0,
	fh => $fh,
	'output.file' => 'output.images/single.hexbin.png',
	'plot.type'       => 'hexbin',
	set_figwidth      => 12,
	title             => 'Simple Hexbin',
});
plt({
	'output.file' => 'output.images/single.hist2d.png',
	data              => {
		E => @e,
		B => @b
	},
	'plot.type'  => 'hist2d',
	title        => 'title',
	execute      => 0,
	fh => $fh,
});
plt({
	fh => $fh,
	execute           => 0,
	'output.file' => 'output.images/hexbin.png',
	plots             => [
		{
			data => {
			E => @e,
			B => @b
			},
			'plot.type'  => 'hexbin',
			title        => 'Simple Hexbin',
		},
		{
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type' => 'hexbin',
		    title       => 'colorbar logscale',
		    cb_logscale => 1
		},
		{
		    cmap => 'jet',
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type'  => 'hexbin',
		    title        => 'cmap is jet',
		    xlabel       => 'xlabel',
		},
		 {
		    data => {
		        E => @e,
		        B => @b
		    },
		    'key.order'  => ['E', 'B'],
		    'plot.type'  => 'hexbin',
		    title        => 'Switch axes with key.order',
		},
		 {
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type'  => 'hexbin',
		    title        => 'vmax set to 25',
		    vmax         => 25
		},
		 {
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type'  => 'hexbin',
		    title        => 'vmin set to -4',
		    vmin         => -4
		},
		{
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type'  => 'hexbin',
		    title        => 'mincnt set to 7',
		    mincnt       => 7
		},
		{
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type'  => 'hexbin',
		    title        => 'xbins set to 9',
		    xbins        => 9
		},
		{
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type'  => 'hexbin',
		    title        => 'ybins set to 9',
		    ybins        => 9
		},
		{
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type'  => 'hexbin',
		    title        => 'marginals = 1',
		    marginals    => 1
		},
		{
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type'  => 'hexbin',
		    title        => 'xscale.hexbin = 1',
		    'xscale.hexbin' => 'log'
		},
		{
		    data => {
		        E => @e,
		        B => @b
		    },
		    'plot.type'  => 'hexbin',
		    title        => 'yscale.hexbin = 1',
		    'yscale.hexbin' => 'log'
		},
	],
	ncols        => 4,
	nrows        => 3,
	scale        => 5,
	suptitle     => 'Various Changes to Standard Hexbin: All data is the same'
});
my $epsilon = 10**-7;
my (%set_opt, %d);
my $i = 0;
foreach my $interval (
	[-2*$pi, -$pi],
	[-$pi, 0],
	[0, $pi],
	[$pi, 2*$pi]
) {
	my @th = linspace($interval->[0] + $epsilon, $interval->[1] - $epsilon, 99, 0);
	@{ $d{csc}{$i}[0] } = @th;
	@{ $d{csc}{$i}[1] } = map { 1/sin($_) } @th;
	@{ $d{cot}{$i}[0] } = @th;
	@{ $d{cot}{$i}[1] } = map { cos($_)/sin($_) } @th;
	if ($i == 0) {
		$set_opt{csc}{$i} = 'color = "red", label = "csc(θ)"';
		$set_opt{cot}{$i} = 'color = "violet", label = "cot(θ)"';
	} else {
		$set_opt{csc}{$i} = 'color = "red"';
		$set_opt{cot}{$i} = 'color = "violet"';
	}
	$i++;
}
$i = 0;
foreach my $interval (
	[-2 * $pi, -1.5 * $pi],
	[-1.5*$pi, -0.5*$pi],
	[-0.5*$pi, 0.5 * $pi],
	[0.5 * $pi, 1.5 * $pi],
	[1.5 * $pi, 2 * $pi]
) {
	my @th = linspace($interval->[0] + $epsilon, $interval->[1] - $epsilon, 99, 0);
	@{ $d{sec}{$i}[0] } = @th;
	@{ $d{sec}{$i}[1] } = map { 1/cos($_) } @th;
	if ($i == 0) {
		$set_opt{sec}{$i} = 'color = "blue", label = "sec(θ)"';
		$set_opt{tan}{$i} = 'color = "green", label = "tan(θ)"';
	} else {
		$set_opt{sec}{$i} = 'color = "blue"';
		$set_opt{tan}{$i} = 'color = "green"';
	}
	@{ $d{tan}{$i}[0] } = @th;
	@{ $d{tan}{$i}[1] } = map { sin($_)/cos($_) } @th;
	$i++;
}
mkdir 'output.images' unless -d 'output.images';
my $xticks = "[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
		. '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']';
my ($min, $max) = (-9,9);
plt({
	fh => $fh,
	execute           => 0,
	'output.file' => 'output.images/plots.png',
	plots         => [
	{ # sin
		data          => {
			'sin(θ)' => [
				[@x],
				[map {sin($_)} @x]
			]
		},
		'plot.type'   => 'plot',
		'set.options' => {
			'sin(θ)' => 'color = "orange"'
		},
		set_xticks    => $xticks,
		set_xlim      => "-2*$pi, 2*$pi",
		xlabel        => 'θ',
		ylabel        => 'sin(θ)',
	},
	{ # sin
		data          => {
			'cos(θ)' => [
				[@x],
				[map {cos($_)} @x]
			]
		},
		'plot.type'   => 'plot',
		'set.options' => {
			'cos(θ)' => 'color = "black"'
		},
		set_xticks    => $xticks,
		set_xlim      => "-2*$pi, 2*$pi",
		xlabel        => 'θ',
		ylabel        => 'cos(θ)',
	},
	{ # csc
		data          => $d{csc},
		'plot.type'   => 'plot',
		'set.options' => $set_opt{csc},
		set_xticks    => $xticks,
		set_xlim      => "-2*$pi, 2*$pi",
		set_ylim      => "$min,$max",
		'show.legend' => 0,
		vlines        => [ # asymptotes
			"-2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			"-$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			"0, $min, $max, color = 'gray', linestyle = 'dashed'",
			"$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			"2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
		],
		xlabel        => 'θ',
		ylabel        => 'csc(θ)',
	},
	{ # sec
		data          => $d{sec},
		'plot.type'   => 'plot',
		'set.options' => $set_opt{sec},
		set_xticks    => $xticks,
		set_xlim      => "-2*$pi, 2*$pi",
		set_ylim      => "$min,$max",
		'show.legend' => 0,
		vlines        => [ # asymptotes
			"-1.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			"-.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			".5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			"1.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
#			"2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
		],
		xlabel        => 'θ',
		ylabel        => 'sec(θ)',
	},
		{ # csc
		data          => $d{cot},
		'plot.type'   => 'plot',
		'set.options' => $set_opt{cot},
		set_xticks    => $xticks,
		set_xlim      => "-2*$pi, 2*$pi",
		set_ylim      => "$min,$max",
		'show.legend' => 0,
		vlines        => [ # asymptotes
			"-2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			"-$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			"0, $min, $max, color = 'gray', linestyle = 'dashed'",
			"$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			"2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
		],
		xlabel        => 'θ',
		ylabel        => 'cot(θ)',
	},
	{ # sec
		data          => $d{tan},
		'plot.type'   => 'plot',
		'set.options' => $set_opt{tan},
		set_xticks    => $xticks,
		set_xlim      => "-2*$pi, 2*$pi",
		set_ylim      => "$min,$max",
		'show.legend' => 0,
		vlines        => [ # asymptotes
			"-1.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			"-.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			".5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
			"1.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
#			"2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
		],
		xlabel        => 'θ',
		ylabel        => 'tan(θ)',
	},
	], # end
	ncols        => 2,
	nrows        => 3,
	set_figwidth => 8,
	suptitle     => 'Basic Trigonometric Functions'
});
plt({
	fh => $fh,
	execute           => 0,
	'output.file' => 'output.images/plot.single.png',
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
});
plt({
	fh => $fh,
	execute           => 0,
	'output.file' => 'output.images/plot.single.arr.png',
	data              => [
		[
			[@x],                     # x
			[ map { sin($_) } @x ]    # y
		],
		[
		 	[@x],                     # x
		 	[ map { cos($_) } @x ]    # y
		],
	],
	'plot.type' => 'plot',
	title       => 'simple plot',
	set_xticks  =>
	"[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
	 . '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']',
	'set.options' => [    # set options overrides global settings; indices match data array
		'color="blue", linewidth=2, label = "sin(x)"', # labels aren't added automatically when using array here
		'color="red",  linewidth=2, label = "cos(x)"'
	],
});
plt({
	fh => $fh,
	execute           => 0,
	'output.file' => 'output.images/barplots.png',
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
});
plt({
	fh => $fh,
	execute           => 0,
	'output.file' => 'output.images/single.hist.png',
	data              => {
		E => @e,
		B => @b,
		A => @a,
	},
	'plot.type'       => 'hist'
});
plt({
	fh => $fh,
	execute           => 0,
	'output.file' => 'output.images/histogram.png',
   set_figwidth => 15,
   suptitle          => 'hist Examples',
	plots             => [
		{ # 1st subplot
		    data => {
		        E => @e,
		        B => @b,
		        A => @a,
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
		      . join( ',', 22 .. 44 ) . '],['  # x coords
		      . join( ',', 22 .. 44 )          # y coords
		      . '], label = "scatter"',
		    xlabel   => 'Value',
		    ylabel   => 'Frequency',
		},
		{ # 2nd subplot
		    data => {
				E => @e,
				B => @b,
				A => @a,
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
		},
		{ # 3rd subplot
			add               => [ # add secondary plots/graphs/methods
			{ # 1st additional plot/graph
				data              => {
					'Gaussian'       => [
						[40..150],
						[map {150 * exp(-0.5*($_-100)**2)} 40..150]
					]
				},
				'plot.type' => 'plot',
				'set.options' => {
					'Gaussian' =>  'color = "red", linestyle = "dashed"'
				}
			}
			],
		   data => {
		        E => @e,
		        B => @b,
		        A => @a,
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
		},
		{# 4th subplot
		    data => {
		        E => @e,
		        B => @b,
		        A => @a,
		    },
		    'plot.type' => 'hist',
		    alpha       => 0.75,
		    color       => {
		        B  => 'Black',
		        E => 'Orange',
		        A => 'Yellow',
		    },
		    orientation  => 'horizontal',    # assign x and y labels smartly
		    title        => 'Horizontal orientation',
		    ylabel       => 'Value',
		    xlabel       => 'Frequency',                #				'log'					=> 1,
		},
	],
	ncols => 3,
	nrows => 2,
});
scatter({
	fh            => $fh,
	data          => {
		X => [@x],
		Y => [map {sin($_)} @x]
	},
	execute       => 0,
	'output.file' => 'output.images/single.scatter.png',
});
plt({
	fh                => $fh,
	'output.file'     => 'output.images/scatterplots.png',
	execute           => 0,
	nrows             => 2,
	ncols             => 3,
	set_figheight     => 8,
	set_figwidth      => 16,
	suptitle          => 'Scatterplot Examples',            # applies to all
	plots             => [
		{    # single-set scatter; no label
			data => {
				X => @e,    # x-axis
				Y => @b,    # y-axis
				Z => @a     # color
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
					A => @a,    # x-axis
					B => @b,    # y-axis
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
					A => @e,    # x-axis
					B => @b,    # y-axis
					C => @a,    # color
				},
				Y => {    # 2nd data set; label is "Y"
					A => generate_normal_dist( 100, 15, 210 ),    # x-axis
					B => generate_normal_dist( 100, 15, 210 ),    # y-axis
					C => generate_normal_dist( 100, 15, 210 ),    # color
				},
			},
			'plot.type'   => 'scatter',
			title         => 'Multiple Set Scatter w/ colorbar',
			'set.options' => {    # arguments to ax.scatter, for each set in data
				X => 'marker = "."',
				Y => 'marker = "d"'     # diamond
			},
			color_key => 'Z',
		},
		{ # multiple-set scatter, labels are "X" and "Y"
			data => {    # 8th plot,
				X => {    # 1st data set; label is "X"
					A => @e,    # x-axis
					B => @b,    # y-axis
				},
				Y => {    # 2nd data set; label is "Y"
					A => generate_normal_dist( 100, 15, 210 ),    # x-axis
					B => generate_normal_dist( 100, 15, 210 ),    # y-axis
				},
			},
			'plot.type'   => 'scatter',
			title         => 'Multiple Set Scatter w/ colorbar',
			'set.options' => {    # arguments to ax.scatter, for each set in data
				X => 'marker = "."',
				Y => 'marker = "d"'     # diamond
			},
		}
	]
});
my @imshow_data;
foreach my $i (0..360) {
	foreach my $j (0..360) {
		push @{ $imshow_data[$i] }, sin($i * $pi/180)*cos($j * $pi/180);
	}
}
imshow({
	data          => \@imshow_data,
	execute       => 0,
   fh            => $fh,
	'output.file' => 'output.images/imshow.single.png',
	set_xlim      => '0, ' . scalar @imshow_data,
	set_ylim      => '0, ' . scalar @imshow_data,
});
plt({
	plots  => [
		{
			data => \@imshow_data,
			'plot.type'       => 'imshow',
			set_xlim          => '0, ' . scalar @imshow_data,
			set_ylim          => '0, ' . scalar @imshow_data,
			title             => 'basic',
		},
		{
			cblabel           => 'sin(x) * cos(x)',
			data => \@imshow_data,
			'plot.type'       => 'imshow',
			set_xlim          => '0, ' . scalar @imshow_data,
			set_ylim          => '0, ' . scalar @imshow_data,
			title             => 'cblabel',
		},
		{
			cblabel           => 'sin(x) * cos(x)',
			cblocation        => 'left',
			data              => \@imshow_data,
			'plot.type'       => 'imshow',
			set_xlim          => '0, ' . scalar @imshow_data,
			set_ylim          => '0, ' . scalar @imshow_data,
			title             => 'cblocation = left',
		},
		{
			cblabel           => 'sin(x) * cos(x)',
			data              => \@imshow_data,
			add               => [ # add secondary plots
			{ # 1st additional plot
				data              => {
					'sin(x)'       => [
						[0..360],
						[map {180 + 180*sin($_ * $pi/180)} 0..360]
					],
					'cos(x)'       => [
						[0..360],
						[map {180 + 180*cos($_ * $pi/180)} 0..360]
					],
				},
				'plot.type' => 'plot',
				'set.options' => {
					'sin(x)'	=>  'color = "red", linestyle = "dashed"',
					'cos(x)'	=>  'color = "blue", linestyle = "dashed"',
				}
			}
			],
			'plot.type'       => 'imshow',
			set_xlim          => '0, ' . scalar @imshow_data,
			set_ylim          => '0, ' . scalar @imshow_data,
			title             => 'auxiliary plots',
		},
	],
	execute         => 0,
   fh              => $fh,
	'output.file'   => 'output.images/imshow.multiple.png',
	ncols           => 2,
	nrows           => 2,
	set_figheight   => 6*3,# 4.8
	set_figwidth    => 6*4 # 6.4
});
# https://labs.chem.ucsb.edu/zakarian/armen/11---bonddissociationenergy.pdf
my %bond_dissociation = (
	Br =>  {
	  Br =>  193
	},
	C  =>  {
		Br =>  276,	C  =>  347,	Cl =>  339,	F   => 485,	H  =>  413,	I  =>  240,
		N  =>  305,	O  =>  358,	S  =>  259
	},
	Cl =>  {
		Br =>  218,	Cl =>  239
	},
	F =>   {
		I => 280, Br =>  237, Cl  => 253, F   => 154
	},
	H  =>  {
		Br =>  363,	Cl =>  427,	F  =>  565,	H   => 432,	I   => 295
	},
	I  =>  {
		Br  => 175,	Cl =>  208,	I  =>  149
	},
	N  =>  {
		Br =>  243,	Cl  => 200,	F   => 272,	H  =>  391,	N  =>  160, O  =>  201
	},
	O =>   {
		Cl =>  203, F  =>  190,	H  =>  467,	I  =>  234,	O  =>  146
	},
	S  =>  {
		Br => 218,	Cl => 253,	F  => 327,	H  => 347,	S  => 266
	},
	Si => {
		C  => 360, H  => 393, O  => 452,	Si => 340
	}
);
colored_table({
	'cblabel'     => 'kJ/mol',
	'col.labels'  => ['H', 'F', 'Cl', 'Br', 'I'],
	data          => \%bond_dissociation,
	execute       => 0,
	fh            => $fh,
	mirror        => 1,
	'output.file' => 'output.images/single.tab.png',
	'row.labels'  => ['H', 'F', 'Cl', 'Br', 'I'],
	'show.numbers'=> 1,
	set_title     => 'Bond Dissociation Energy'
});
plt({
	execute       => 0,
	fh            => $fh,
	'output.file' => 'output.images/single.bonds.png',
	plots         => [
		{
			data          => \%bond_dissociation,
			'plot.type'   => 'colored_table',
			set_title     => 'No other options'
		},
		{
			data          => \%bond_dissociation,
			cblabel       => 'Average Dissociation Energy (kJ/mol)',
			'col.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
			mirror        => 1,
			'plot.type'   => 'colored_table',
			'row.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
			'show.numbers'=> 1,
			set_title     => 'Showing numbers and mirror with defined order'
		},
		{
			data          => \%bond_dissociation,
			cblabel       => 'Average Dissociation Energy (kJ/mol)',
			'col.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
			mirror        => 1,
			'plot.type'   => 'colored_table',
			'row.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
			'show.numbers'=> 1,
			set_title     => 'Set undefined color to white',
			'undef.color' => 'white'
		}
	],
	ncols         => 3,
	set_figwidth  => 14,
	suptitle      => 'Colored Table options'
});
plt({
	'plot.type'   => 'plot',
	data          => {
		'expo' => [
			[@x],
			[map { 1 + 1 / ( $_**2 + 1) } @x]
		]
	},
	execute       => 0,
	fh            => $fh,
	hlines        => "1,$x[0],$x[-1], linestyles = 'dashed'",
	'output.file' => 'output.images/hlines.png',
	set_xlim      => "$x[0],$x[-1]",
	'show.legend' => 0
});
plt({
	cbpad       => 0.01,          # default 0.05 is too big
	data        => [              # imshow gets a 2D array
		[' ', ' ', ' ', ' ', 'G'], # bottom
		['S', 'I', 'T', 'E', 'H'], # top
	],
	execute     => 0,
	fh          => $fh,
	'plot.type' => 'imshow',
	stringmap   => {
		'H' => 'Alpha helix',
		'B' => 'Residue in isolated β-bridge',
		'E' => 'Extended strand, participates in β ladder',
		'G' => '3-helix (3/10 helix)',
		'I' => '5 helix (pi helix)',
		'T' => 'hydrogen bonded turn',
		'S' => 'bend',
		' ' => 'Loops and irregular elements'
	},
	'output.file' => 'output.images/dssp.single.png',
	scalex        => 2.4,
	set_ylim      => '0, 1',
	title         => 'Dictionary of Secondary Structure in Proteins (DSSP)',
	xlabel        => 'xlabel',
	ylabel        => 'ylabel'
});
plt({
	cbpad       => 0.01,          # default 0.05 is too big
	plots       => [
		{ # 1st plot
			data 	=> [
				[' ', ' ', ' ', ' ', 'G'], # bottom
				['S', 'I', 'T', 'E', 'H'], # top
			],
			'plot.type' => 'imshow',
			set_xticklabels=> '[]', # remove x-axis labels
			set_ylim    => '0, 1',
			stringmap   => {
				'H' => 'Alpha helix',
				'B' => 'Residue in isolated β-bridge',
				'E' => 'Extended strand, participates in β ladder',
				'G' => '3-helix (3/10 helix)',
				'I' => '5 helix (pi helix)',
				'T' => 'hydrogen bonded turn',
				'S' => 'bend',
				' ' => 'Loops and irregular elements'
			},
			title         => 'top plot',
			ylabel        => 'ylabel'
		},
		{ # 2nd plot
			data 	=> [
				[' ', ' ', ' ', ' ', 'G'], # bottom
				['S', 'I', 'T', 'E', 'H'], # top
			],
			'plot.type' => 'imshow',
			set_ylim    => '0, 1',
			stringmap   => {
				'H' => 'Alpha helix',
				'B' => 'Residue in isolated β-bridge',
				'E' => 'Extended strand, participates in β ladder',
				'G' => '3-helix (3/10 helix)',
				'I' => '5 helix (pi helix)',
				'T' => 'hydrogen bonded turn',
				'S' => 'bend',
				' ' => 'Loops and irregular elements'
			},
			title         => 'bottom plot',
			xlabel        => 'xlabel',
			ylabel        => 'ylabel'
		}
	],
	execute           => 0,
	fh                => $fh,
	nrows             => 2,
	'output.file'     => 'output.images/dssp.multiple.png',
	scalex            => 2.4,
	'shared.colorbar' => [0,1], # plots 0 and 1 share a colorbar
	suptitle          => 'Dictionary of Secondary Structure in Proteins (DSSP)',
});
plt({
	fh                => $fh,
	execute           => 1,
	ncols             => 3,
	nrows             => 3,
	suptitle          => 'Types of hist2d plots: all of the data is identical',
	plots => [
		{
			data => {
			X => $x,    # x-axis
			Y => $y,    # y-axis
			},
			'plot.type' => 'hist2d',
			title       => 'Simple hist2d',
		},
		{
			data => {
				X => $x,    # x-axis
				Y => $y,    # y-axis
			},
			'plot.type' => 'hist2d',
			title       => 'cmap = terrain',
			cmap        => 'terrain'
		},
		{
			cmap => 'ocean',
			data => {
				X => $x,    # x-axis
				Y => $y,    # y-axis
			},
			'plot.type' => 'hist2d',
			title => 'cmap = ocean and set colorbar range with vmin/vmax',
			set_figwidth => 15,
			vmin         => -2,
			vmax         => 14
		},
		{
			data => {
				X => $x,    # x-axis
				Y => $y,    # y-axis
			},
			'plot.type' => 'hist2d',
			title       => 'density = True',
			cmap        => 'terrain',
			density     => 'True'
		},
		{
			data => {
				X => $x,    # x-axis
				Y => $y,    # y-axis
			},
			'plot.type' => 'hist2d',
			title       => 'key.order flips axes',
			cmap        => 'terrain',
			'key.order' => [ 'Y', 'X' ]
		},
		{
			cb_logscale => 1,
			data => {
				X => $x,    # x-axis
				Y => $y,    # y-axis
			},
			'plot.type' => 'hist2d',
			title       => 'cb_logscale = 1',
		},
		{
			cb_logscale => 1,
			data => {
				X => $x,    # x-axis
				Y => $y,    # y-axis
			},
			'plot.type' => 'hist2d',
			title       => 'cb_logscale = 1 with vmax set',
			vmax        => 2.1,
			vmin        => 1
		},
		{
			data => {
				X => $x,    # x-axis
				Y => $y,    # y-axis
			},
			'plot.type'     => 'hist2d',
			'show.colorbar' => 0,
			title           => 'no colorbar',
		},
		{
			data => {
				X => $x,    # x-axis
				Y => $y,    # y-axis
			},
			'plot.type'     => 'hist2d',
			title           => 'xbins = 9',
			xbins           => 9
		},
	],
	'output.file' => 'output.images/hist2d.png',
});
