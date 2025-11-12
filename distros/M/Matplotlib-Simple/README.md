# Synopsis

Take a data structure in Perl, and automatically write a Python3 script using matplotlib to generate an image.  The Python3 script is saved in `/tmp`, to be edited at the user's discretion.
Requires python3 and matplotlib installations.

## Single Plots
Simplest use case:
```
use Matplotlib::Simple 'plot';
plot({
	'output.filename' => '/tmp/gospel.word.counts.png',
	'plot.type'       => 'bar',
	data              => {
		Matthew => 18345,
		Mark    => 11304,
		Luke    => 19482,
		John    => 15635,
	}
});
```
where `xlabel`, `ylabel`, `title`, etc. are axis methods in matplotlib itself. `plot.type`, `data`, `input.file` are all specific to `MatPlotLib::Simple`.

<img width="651" height="491" alt="gospel word counts" src="https://github.com/user-attachments/assets/a008dece-2e34-47bf-af0f-8603709f7d52" />

## Multiple Plots

Having a `plots` argument as an array lets the module know to create subplots:
```
use Matplotlib::Simple 'plot';
plot({
	'output.filename'	=> 'svg/pies.png',
	plots             => [
		{
			data	=> {
			 Russian => 106_000_000,  # Primarily European Russia
			 German => 95_000_000,    # Germany, Austria, Switzerland, etc.
			},
			'plot.type'	=> 'pie',
			title       => 'Top Languages in Europe',
			suptitle    => 'Pie in subplots',
		},
		{
			data	=> {
			 Russian => 106_000_000,  # Primarily European Russia
			 German => 95_000_000,    # Germany, Austria, Switzerland, etc.
			},
			'plot.type'	=> 'pie',
			title       => 'Top Languages in Europe',
		},
	],
	ncols    => 2,
});
```
which produces the following subplots image:

<img width="651" height="424" alt="pies" src="https://github.com/user-attachments/assets/49d3e28b-f897-4b01-9e72-38afa12fa538" />

`bar`, `barh`, `boxplot`, `hexbin`, `hist`, `hist2d`, `imshow`, `pie`, `plot`, `scatter`, and `violinplot` all match the methods in matplotlib itself.
# Examples/Plot Types
Consider the following helper subroutines to generate data to plot:

```
sub linspace { # mostly written by Grok
	my ($start, $stop, $num, $endpoint) = @_; # endpoint means include $stop
	$num = defined $num ? int($num) : 50; # Default to 50 points
	$endpoint = defined $endpoint ? $endpoint : 1; # Default to include endpoint
	return () if $num < 0; # Return empty array for invalid num
	return ($start) if $num == 1; # Return single value if num is 1
	my (@result, $step);

	if ($endpoint) {
	  $step = ($stop - $start) / ($num - 1) if $num > 1;
	  for my $i (0 .. $num - 1) {
		   $result[$i] = $start + $i * $step;
	  }
	} else {
	  $step = ($stop - $start) / $num;
	  for my $i (0 .. $num - 1) {
		   $result[$i] = $start + $i * $step;
	  }
	}
	return @result;
}

sub generate_normal_dist {
	my ($mean, $std_dev, $size) = @_;
	$size = defined $size ? int $size : 100; # default to 100 points
	my @numbers;
	for (1 .. int($size / 2) + 1) {# Box-Muller transform
		my $u1 = rand();
		my $u2 = rand();
		my $z0 = sqrt(-2.0 * log($u1)) * cos(2.0 * 3.141592653589793 * $u2);
		my $z1 = sqrt(-2.0 * log($u1)) * sin(2.0 * 3.141592653589793 * $u2); # Scale and shift to match mean and std_dev
		push @numbers, ($z0 * $std_dev + $mean, $z1 * $std_dev + $mean);
	} # Trim to exact size if needed
	@numbers = @numbers[0 .. $size - 1] if @numbers > $size;
	@numbers = map {sprintf '%.1f', $_} @numbers;
	return \@numbers;
}
sub rand_between {
	my ($min, $max) = @_;
	return $min + rand($max - $min)
}
```
## Barplot/bar/barh

Plot a hash or a hash of arrays as a boxplot

### Options

| Option | Description | Example |
| -------- | ------- | ------- 
|color| :mpltype:`color` or list of :mpltype:`color`, optional; The colors of the bar faces. This is an alias for *facecolor*. If both are given, *facecolor* takes precedence # if entering multiple colors, quoting isn't needed|`color => ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'fuchsia'],` or a single color for all bars `color => 'red'`
|edgecolor| :mpltype:`color` or list of :mpltype:`color`, optional; The colors of the bar edges|`edgecolor		=> 'black'`
|key.order|  define the keys in an order (an array reference)|`'key.order'		=> ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],`
|linewidth| float or array, optional; Width of the bar edge(s). If 0, don't draw edges. Only does anything with defined `edgecolor`|`linewidth => 2,`
|log| bool, default: False; If *True*, set the y-axis to be log scale.|`log = 'True',`
|stacked| stack the groups on top of one another; default 0 = off|`stacked	=> 1,`
|width| float only, default: 0.8; The width(s) of the bars.  `width` will be deactivated with grouped, non-stacked bar plots |`width => 0.4,`
|xerr| float or array-like of shape(N,) or shape(2, N), optional. If not *None*, add horizontal / vertical errorbars to the bar tips. The values are +/- sizes relative to the data:        - scalar: symmetric +/- values for all bars #        - shape(N,): symmetric +/- values for each bar #        - shape(2, N): Separate - and + values for each bar. First row #          contains the lower errors, the second row contains the upper #          errors. #        - *None*: No errorbar. (Default)|`yerr						=> {'USA'				=> [15,29],	'Russia'			=> [199,1000],}`
|yerr|same as xerr, but better with bar|

an example of multiple plots, showing many options:

### single, simple plot

```
use Matplotlib::Simple 'plot';
plot({
	'output.filename'			=> 'output.images/single.barplot.png',
	data	=> { # simple hash
		Fri => 76, Mon	=> 73, Sat => 26, Sun => 11, Thu	=> 94, Tue	=> 93, Wed	=> 77
	},
	'plot.type'	=> 'bar',
	xlabel		=> '# of Days',
	ylabel		=> 'Count',
	title		=> 'Customer Calls by Days'
});
```

where `xlabel`, `ylabel`, `title`, etc. are axis methods in matplotlib itself. `plot.type`, `data`, `input.file` are all specific to `MatPlotLib::Simple`.
<img width="651" height="491" alt="single barplot" src="https://github.com/user-attachments/assets/eae009a8-5571-4608-abdb-1016e3cff5fd" />

### multiple plots
```
plot({
	'input.file'		=> $tmp_filename,
	execute				=> 0,
	'output.filename'	=> 'output.images/barplots.png',
	plots					=> [
		{ # simple plot
			data	=> { # simple hash
				Fri => 76, Mon	=> 73, Sat => 26, Sun => 11, Thu	=> 94, Tue	=> 93, Wed	=> 77
			},
			'plot.type'	=> 'bar',
			'key.order'		=> ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],
			suptitle			=> 'Types of Plots', # applies to all
			color				=> ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'fuchsia'],
			edgecolor		=> 'black',
			set_figwidth	=> 40/1.5, # applies to all plots
			set_figheight	=> 30/2, # applies to all plots
			title				=> 'bar: Rejections During Job Search',
			xlabel			=> 'Day of the Week',
			ylabel			=> 'No. of Rejections'
		},
		{ # grouped bar plot
			'plot.type'	=> 'bar',
			data	=> {
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
				  Germany => 11.2 #Rapid decrease due to war's end	
				},
			},
			stacked	=> 0,
			title		=> 'Hash of Hash Grouped Unstacked Barplot',
			width		=> 0.23,
			xlabel	=> 'r"$\it{anno}$ $\it{domini}$"', # italic
			ylabel	=> 'Military Expenditure (Billions of $)'
		},
		{ # grouped bar plot
			'plot.type'	=> 'bar',
			data	=> {
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
				  Germany => 11.2 #Rapid decrease due to war's end	
				},
			},
			stacked	=> 1,
			title		=> 'Hash of Hash Grouped Stacked Barplot',
			xlabel	=> 'r"$\it{anno}$ $\it{domini}$"', # italic
			ylabel	=> 'Military Expenditure (Billions of $)'
		},
		{# grouped barplot: arrays indicate Union, Confederate which must be specified in options hash
			data					=> { # 4th plot: arrays indicate Union, Confederate which must be specified in options hash
			 'Antietam'				=> [ 12400, 10300 ],
			 'Gettysburg'			=> [ 23000, 28000 ],
			 'Chickamauga'			=> [ 16000, 18000 ],
			 'Chancellorsville'	=> [ 17000, 13000 ],
			 'Wilderness'			=> [ 17500, 11000 ],
			 'Spotsylvania'		=> [ 18000, 12000 ],
			 'Cold Harbor'			=> [ 12000, 5000  ],
			 'Shiloh'				=> [ 13000, 10700 ],
			 'Second Bull Run'	=> [ 10000, 8000  ],
			 'Fredericksburg'		=> [ 12600, 5300  ],
			},
			'plot.type'	=> 'barh',
			color		=>	['blue', 'gray'], # colors match indices of data arrays
			label		=> ['North', 'South'], # colors match indices of data arrays
			xlabel	=> 'Casualties',
			ylabel	=> 'Battle',
			title		=> 'barh: hash of array'
		},
		{ # 5th plot: barplot with groups
			data	=> {
				1942 => [ 109867,  310000, 7700000 ], # US, Japan, USSR
				1943 => [ 221111,  440000, 9000000 ],
				1944 => [ 318584,  610000, 7000000 ],
				1945 => [ 318929, 1060000, 3000000 ],
			},
			color		=> ['blue', 'pink', 'red'], # colors match indices of data arrays
			label		=> ['USA', 'Japan', 'USSR'], # colors match indices of data arrays
			'log'		=> 1,
			title		=> 'grouped bar: Casualties in WWII',
			ylabel	=> 'Casualties',
			'plot.type'	=> 'bar'
		},	
		{ # nuclear weapons barplot
			'plot.type'		=> 'bar',
			data => {
				'USA'				=> 5277, # FAS Estimate
				'Russia'			=> 5449, # FAS Estimate
				'UK'				=> 225, # Consistent estimate
				'France'			=> 290, # Consistent estimate
				'China'			=> 600, # FAS Estimate
				'India'			=> 180, # FAS Estimate
				'Pakistan'		=> 130, # FAS Estimate
				'Israel'			=> 90, # FAS Estimate
				'North Korea'	=> 50, # FAS Estimate
			},
			title		=> 'Simple hash for barchart with yerr',
			xlabel	=> 'Country',
			yerr						=> {
				'USA'				=> [15,29],
				'Russia'			=> [199,1000],
				'UK'				=> [15,19],
				'France'			=> [19,29],
				'China'			=> [200,159],
				'India'			=> [15,25],
				'Pakistan'		=> [15,49],
				'Israel'			=> [90,50],
				'North Korea'	=> [10,20],
			},
			ylabel	=> '# of Nuclear Warheads',
			'log'						=> 'True', #	linewidth				=> 1,
		}
	],
	ncols	=> 3,
	nrows	=> 4
});
```
which produces the plot:

<img width="2678" height="849" alt="barplots" src="https://github.com/user-attachments/assets/6d87d13b-dabd-485d-92f7-1418f4acc65b" />

## boxplot

Plot a hash of arrays as a series of boxplots

### options

| Option | Description | Example |
| -------- | ------- | ------- |
|`color` | a single color for all plots | `color => 'pink'`|
|`colors`| a hash, where each data point and color is a hash pair |`colors => { A => 'orange', E => 'yellow', B => 'purple' },`|
| `key.order`| order that the keys in the entry hash will be plotted | `key.order = ['A', 'E', 'B']` |
| `orientation`| orientation of the plot, by default `vertical`| `orientation = 'horizontal'` |
|`showcaps`| Show the caps on the ends of whiskers; default `True` | `showcaps => 'False',` |
| `showfliers` |Show the outliers beyond the caps; default `True` | `showfliers  => 'False'` |
|`showmeans` | show means; default = `True` | `showmeans   => 'False'` |
|`whiskers`| show whiskers, default = 1| ` whiskers    => 0,`|
				
### single, simple plot
```
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
```
which makes the following image:

<img width="651" height="491" alt="single boxplot" src="https://github.com/user-attachments/assets/19870fa2-fe36-4513-8cbb-23da3a0cf686" />

### multiple plots
```
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
```
which makes the following plot:

<img width="1230" height="1211" alt="boxplot" src="https://github.com/user-attachments/assets/7e32e394-86fc-49e7-ad97-f48fd82fc8b0" />

## hexbin

Plot a hash of arrays as a hexbin
see https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.hexbin.html

### options

| Option | Description | Example |
| -------- | ------- | ------- 
| cb_logscale | colorbar log scale `from matplotlib.colors import LogNorm` | default 0, any value > 0 enables |
|cmap| The Colormap instance or registered colormap name used to map scalar data to colors | default `gist_rainbow` |
|key.order|  define the keys in an order (an array reference)|`'key.order' => ['X-rays', 'Yak Butter'],`
| marginals | integer, by default off = 0 | `marginals => 1` |
| mincnt | int >= 0, default: None; If not None, only display cells with at least mincnt number of points in the cell. |  `mincnt => 2`|
| vmax  | The normalization method used to scale scalar data to the [0, 1] range before mapping to colors using cmap | `'asinh', 'function', 'functionlog', 'linear', 'log', 'logit', 'symlog'` default `linear` |
| vmin  | The normalization method used to scale scalar data to the [0, 1] range before mapping to colors using cmap | `'asinh', 'function', 'functionlog', 'linear', 'log', 'logit', 'symlog'` default `linear` |
| xbins | integer that accesses horizontal gridsize | default is 15 |
| xscale.hexbin | 'linear', 'log'}, default: 'linear': Use a linear or log10 scale on the horizontal axis | `'xscale.hexbin' => 'log'`|
| ybins | integer that accesses vertical gridsize | default is 15 |
| yscale.hexbin | 'linear', 'log'}, default: 'linear': Use a linear or log10 scale on the vertical axis | `'yscale.hexbin' => 'log'`|

### single, simple plot
```
plot({
	data	=> {
		E	=> generate_normal_dist(100, 15, 3*210),
		B	=> generate_normal_dist(85, 15, 3*210)
	},
	'output.filename'	=> 'output.images/single.hexbin.png',
	'plot.type'	=> 'hexbin',
	set_figwidth => 12,
	title			=> 'Simple Hexbin',
});
```
which makes the following plot:
<img width="1208" height="491" alt="single hexbin" src="https://github.com/user-attachments/assets/129c41cd-2d7d-43de-978a-2b9c441b8939" />
### multiple plots

```
plot(
    {
        'input.file'      => $tmp_filename,
        execute           => 0,
        'output.filename' => 'output.images/hexbin.png',
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
        ],
        ncols => 2
    }
);
```
which produces the following image:
<img width="2010" height="1511" alt="hexbin" src="https://github.com/user-attachments/assets/71412ab1-e869-4913-a8cf-e39df15c9590" />
## hist

Plot a hash of arrays as a series of histograms

### options


| Option | Description | Example |
| -------- | ------- | ------- |
|`alpha` | default 0.5; same for all sets| |
|`bins` | # nt or sequence or str, default: :rc:`hist.bins`If *bins* is an integer, it defines the number of equal-width bins in the range. If *bins* is a sequence, it defines the bin edges, including the left edge of the first bin and the right edge of the last bin; in this case, bins may be unequally spaced.  All but the last  (righthand-most) bin is half-open|
|`color` | a hash, where keys are the keys in data, and values are colors | `X => 'blue'`|
|`log`| if set to > 1, the y-axis will be logarithmic | 
|`orientation`| {'vertical', 'horizontal'}, default: 'vertical'|

### single, simple plot

```
my @e = generate_normal_dist( 100, 15, 3 * 200 );
my @b = generate_normal_dist( 85,  15, 3 * 200 );
my @a = generate_normal_dist( 105, 15, 3 * 200 );

plot({
	'input.file'      => $tmp_filename,
	execute           => 0,
	'output.filename' => 'output.images/single.hist.png',
	data              => {
		E => @e,
		B => @b,
		A => @a,
	},
	'plot.type'       => 'hist'
});
```
<img width="651" height="491" alt="single hist" src="https://github.com/user-attachments/assets/fafcf787-6c4f-4998-88c4-77a15d878fa6" />

### multiple plots

```
plot({
	'input.file'      => $tmp_filename,
	execute           => 0,
	'output.filename' => 'output.images/histogram.png',
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
		        B => 'Black',
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
```
<img width="1511" height="491" alt="histogram" src="https://github.com/user-attachments/assets/b13b4cc8-6e64-40b0-913d-6a5886cee0db" />

## hist2d
### options
### single, simple plot
### multiple plots
## imshow

Plot 2D array of numbers as an image

### options
| Option | Description | Example |
| -------- | ------- | ------- 
|`cblabel`| colorbar label | `cblabel => 'sin(x) * cos(x)',`
|`cbdrawedges` |draw edges for colorbar | |
|`cblocation` | 'left', 'right', 'top', 'bottom'| `cblocation => 'left',`|
|`cborientation`|  None, or 'vertical', 'horizontal' | 
|`cmap`| # The Colormap instance or registered colormap name used to map scalar data to colors.|
|`vmax`| float |
|`vmin`| float | 

### single, simple plot

```
my @imshow_data;
foreach my $i (0..360) {
	foreach my $j (0..360) {
		push @{ $imshow_data[$i] }, sin($i * $pi/180)*cos($j * $pi/180);
	}
}
plot({
	data              => \@imshow_data,
	execute           => 0,
   'input.file'      => $tmp_filename,
	'output.filename' => 'output.images/imshow.single.png',
	'plot.type'       => 'imshow',
	set_xlim          => '0, ' . scalar @imshow_data,
	set_ylim          => '0, ' . scalar @imshow_data,
});
```
<img width="599" height="491" alt="imshow single" src="https://github.com/user-attachments/assets/3fa4ffe6-4817-4133-9c91-b68099400377" />

### multiple plots

## pie

### options

### single, simple plot

### multiple plots

## plot

### single, simple

```
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
```

which makes the following "plot" plot: <img width="651" height="491" alt="plot single" src="https://github.com/user-attachments/assets/6cbd6aad-c464-4703-b962-b420ec08bb66" />

### multiple sub-plots

```
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
```
which makes <img width="1211" height="491" alt="plot" src="https://github.com/user-attachments/assets/a8312147-e13d-4aa9-9997-49430bb5c74a" />
## scatter
### options
### single, simple plot
### multiple plots
## violin
### options
### single, simple plot
### multiple plots
## wide
### options
### single, simple plot
### multiple plots
# Advanced
## Notes in Files
all files that can have notes with them, give notes about how the file was written.  For example, SVG files have the following:
`<dc:title>made/written by /mnt/ceph/dcondon/ui/gromacs/tut/dup.2puy/1.plot.gromacs.pl called using "plot" in /mnt/ceph/dcondon/perl5/perlbrew/perls/perl-5.42.0/lib/site_perl/5.42.0/x86_64-linux/Matplotlib/Simple.pm</dc:title>`
## Speed
To improve speed, all data can be written into a single temp python3 file thus:
```
use File::Temp 'tempfile';

my ( $fh, $tmp_filename ) =  tempfile( DIR => '/tmp', SUFFIX => '.py', UNLINK => 0 );
close $fh;
# all files will be written to $tmp_filename; be sure to put `execute => 0`
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
# the last plot should have `execute => 1`
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
        execute           => 1,
    }
);
```
