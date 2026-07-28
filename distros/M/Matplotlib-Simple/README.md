# NAME

Matplotlib::Simple - Access Matplotlib from Perl; providing consistent user interface between different plot types

# Synopsis

Take a data structure in Perl, and automatically write a Python3 script using matplotlib to generate an image.  The Python3 script is saved in `/tmp`, to be edited at the user's discretion.
Depends on python3 and matplotlib.

My aim is to simplify the most common tasks as much as possible.  In my opinion, using this module is much easier than matplotlib itself.

# Single Plots
Simplest use case:

    use Matplotlib::Simple;
    bar(
	   'output.file'     => '/tmp/gospel.word.counts.png',
	   data              => {
		  Matthew => 18345,
		  Mark    => 11304,
		  Luke    => 19482,
		  John    => 15635,
	   }
    );

A more complete (and slightly faster execution):

    use Matplotlib::Simple;
    plt(
	   'output.file'     => '/tmp/gospel.word.counts.png',
	   'plot.type'       => 'bar',
	   data              => {
		  Matthew => 18345,
		  Mark    => 11304,
		  Luke    => 19482,
		  John    => 15635,
	   }
    );

<img width="651" height="491" alt="gospel word counts" src="https://github.com/user-attachments/assets/a008dece-2e34-47bf-af0f-8603709f7d52" />

# Multiple Plots

Having a `plots` argument as an array lets the module know to create subplots:

    use Matplotlib::Simple 'plt';
    plt(
    	'output.file'	=> 'svg/pies.png',
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
    );

which produces the following subplots image:

<img width="651" height="424" alt="pies" src="https://github.com/user-attachments/assets/49d3e28b-f897-4b01-9e72-38afa12fa538" />

`bar`, `barh`, `boxplot`, `hexbin`, `hist`, `hist2d`, `imshow`, `pie`, `plot`, `scatter`, and `violinplot` all match the methods in matplotlib itself.  `venn_proportional_area` additionally wraps the [`matplotlib_venn`](https://pypi.org/project/matplotlib-venn/) library (see [its section below](#venn_proportional_area)).

## The `p` argument

`p` is a single, uniform way to describe one *or* many subplots, so you no
longer need a top-level `plot.type` (or the older `plots` array). Each plot is a
hash, exactly like a single-plot call, and `p` collects the subplots into one
array.

The rule is simple: **one element of `p` is one subplot.**

- A **hash** element is a subplot containing a single plot.
- An **array of hashes** element is a single subplot whose plots are drawn on
  the **same** axes: the first hash is the base plot and the rest are
  *additions* (overlays), exactly like `add`.

The two forms may be **mixed freely** in the same `p`. The first (or only) hash
of a subplot supplies that subplot's axes-level options (`title`, `xlabel`,
`ylabel`, `legend`, …).

If you don't give a grid, the subplots are laid out automatically on a
near-square grid. Give `ncol`/`nrow` (aliases for `ncols`/`nrows`) to control
it; supplying only one dimension derives the other (so `ncols => 1` stacks the
subplots in a single column), and supplying both is honored as given.

`p` cannot be combined with `plot.type`, `data`, `plots`, or `add`.

> Arguments are now passed as a plain list — `plt( ... )` — though the older
> `plt({ ... })` form still works.

### One subplot, several plots overlaid

Wrap the plots in an inner array and they all land on a single subplot (the
first is the base plot, the rest are additions):

    plt(
        p => [
            [
                {
                    data => {
                        E => [ 55, @{$x}, 160 ],
                        B => [ @{$y}, 140 ],
                    },
                    'plot.type' => 'boxplot',
                    title       => 'Single Box Plot: Specified Colors',
                    colors      => { E => 'yellow', B => 'purple' },
                },
                {
                    data => {
                        A => [ 55, @{$z} ],
                        E => [ @{$y} ],
                        B => [ 122, @{$z} ],
                    },
                    'plot.type' => 'violinplot',
                    title       => 'Single Violin Plot: Specified Colors',
                    colors      => { E => 'yellow', B => 'purple', A => 'green' },
                },
            ],
        ],
        'output.file' => '1plot.svg',    # note: no `plot.type` needed
    );

### Multiple subplots

Give each subplot as its own element. A bare hash is a one-plot subplot, so two
hashes make two subplots; with `ncol => 2` they sit side by side:

    plt(
        p => [
            {
                data => {
                    E => [ 55, @{$x}, 160 ],
                    B => [ @{$y}, 140 ],
                },
                'plot.type' => 'boxplot',
                title       => 'Box Plot: Specified Colors',
                colors      => { E => 'yellow', B => 'purple' },
            },
            {
                data => {
                    A => [ 55, @{$z} ],
                    E => [ @{$y} ],
                    B => [ 122, @{$z} ],
                },
                'plot.type' => 'violinplot',
                title       => 'Violin Plot: Specified Colors',
                colors      => { E => 'yellow', B => 'purple', A => 'green' },
            },
        ],
        ncol          => 2,
        'output.file' => '2plots.svg',
    );

To overlay extra plots on any one subplot, make that element an array of hashes
instead of a bare hash (the first is the plot, the rest are additions). Bare
hashes and inner arrays may be intermixed in the same `p`, for example
`p => [ \%single, [ \%base, \%overlay ], \%another ]`.

## Options

`sharex` and `sharey` are both implemented at the plot, rather than subplot, level.  See Matplotlib's documentation for more clarity.

### Quoting text: commas and apostrophes

`title`, `suptitle`, `xlabel`, `ylabel`, `set_title`, `set_xlabel` and
`set_ylabel` are quoted for you — but only when the text contains no comma, no
apostrophe and no double quote.  Anything else is passed through to Python
untouched, on the assumption that you are supplying Python syntax of your own,
which is what makes a raw string such as

    xlabel => 'r"$\it{anno}$ $\it{domini}$"',    # italics, via mathtext

possible in the first place.  The practical consequence is that a plain-English
label with a comma or an apostrophe in it has to carry its own quotes:

    title => 'Two groups: mean and s.d.',     # fine, no comma
    title => '"Two groups, mean and s.d."',   # comma: quote it yourself
    title => '"war\'s end"',                  # apostrophe: likewise

Without those quotes the generated Python is a syntax error rather than a
mislabelled plot, so the mistake is loud.

Use **double** quotes when quoting text yourself.  `suptitle` in particular is
emitted twice — once for the subplot and once for the figure — and the second
pass runs its own quoting rules over the text, which turns single-quoted text
into `plt.suptitle(''a, b'')`.  Double quotes survive both passes.

Every other option is passed through as written, so text inside `legend`, `text`
and friends is Python syntax throughout: `legend => 'loc = "upper left"'`.

# Color Bars (colorbars)

Colarbar args attempt to match matplotlib closely

| Option | Description | Example |
| -------- | ------- | ------- 
|`cbdrawedges` | Whether to draw lines at color boundaries | `cbdrawedges => 1`|
|`cblabel`      | The label on the colorbar's long axis | `cblabel => 1` |
|`cblocation`   |  of the colorbar None or {'left', 'right', 'top', 'bottom'} | |
|`cborientation` | # None or {`vertical`, `horizontal`} |
|`cbpad`        | pad : float, default: 0.05 if vertical, 0.15 if horizontal; Fraction of original Axes between colorbar and new image Axes
|`cb_logscale`  | Perl true (anything but 0) or false (0)| |
|`shared.colorbar` | share colorbar between different plots: specify plot indices | `'shared.colorbar' => [0,1]`|

# Size/Dimensions of output file

| Option | Description | Example |
| -------- | ------- | ------- |
|`scale`  | scale/multiply the size of the output figure | `scale => 2.4`|
|`scalex` | scale/multiply the x-axis only | `scalex => 2.4` |
|`scaley` | scale/multiply the y-axis only | `scalex => 1.4` |

# Examples/Plot Types

Every plot type can be called two ways: through `plt` with `'plot.type' => 'bar'`,
or through the same-named helper subroutine, `bar( ... )`, which is a thin wrapper
that fills in `'plot.type'` and calls `plt` for you.  Everything documented for a
plot type therefore works in either form, and works identically whether the plot
is alone or one panel of a `plots` grid.

## Which helper takes which data?

The fastest way to pick a plot type is to start from the shape of the data you
already have in Perl:

| `data` you have | Helpers that take it | Notes |
| -------- | ------- | ------- |
|hash of numbers, `A => 1`|`bar`, `barh`, `pie`|one bar/wedge per key|
|hash of array refs, `A => [1,2,3]`|`boxplot`, `violin`, `hist`, `hexbin`, `hist2d`, `scatter`, `venn_proportional_area`|one distribution/series per key; `hexbin` and `hist2d` need exactly 2 keys (x and y), `scatter` 2 or 3, `venn_proportional_area` 2 or 3|
|hash of hashes, `A => { X => 1 }`|`bar`, `barh`, `colored_table`|grouped/stacked bars, or a matrix|
|hash of `[ \@x, \@y ]` pairs|`plot`|one labelled line per key|
|hash of arrays of `[ \@x, \@y ]` pairs|`wide`|repeated runs of the same curve, summarised|
|hash of hashes of array refs|`scatter`|several labelled sets, each with its own x/y (and colour)|
|a single array ref|`hist`, `boxplot`, `violin`|the one-series shorthand|
|array of `[ \@x, \@y ]` pairs|`plot`, `wide`|unlabelled lines|
|2-D array (array of array refs)|`imshow`|a raster/heatmap; strings allowed via `stringmap`|

A few conventions hold across all of them:

- Keys are used in **sorted order** unless you say otherwise.  `key.order` is
  accepted by `bar`, `barh`, `boxplot`, `violin`, `hexbin`, `hist2d`, `plot` and
  `venn_proportional_area`; `scatter` spells the same idea `keys`; and
  `colored_table` uses `row.labels`/`col.labels`.  `pie`, `hist` and `wide` take
  no ordering option at all, and `imshow` has no keys to order.
- `title`, `xlabel`, `ylabel`, `suptitle`, `set_xlim`, `legend` and the rest of
  Matplotlib's `ax`/`fig`/`plt` methods are accepted by every plot type; see
  [Options](#options).
- Anything that is not recognised is reported as an error listing the arguments
  that *are* accepted, rather than being silently ignored.

Consider the following helper subroutines to generate data to plot:

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

## Barplot/bar/barh

Plot a hash, a hash of arrays, or a hash of hashes as a bar chart.  `bar` draws
vertical bars, `barh` horizontal ones; every option below applies to both.

### Entering data

`data` accepts three shapes, and the shape alone decides whether you get one
bar per key or a group of bars per key:

**1. One bar per key (hash of numbers).** The simplest case — the key is the
tick label:

    bar(
    	'output.file' => '/tmp/simple.svg',
    	data          => { Mon => 73, Tue => 93, Wed => 77 },
    );

**2. Groups of bars (hash of array refs).** Each key becomes a group; index `i`
of every array is one series, so `color` and `label` are arrays indexed the same
way:

    bar(
    	'output.file' => '/tmp/grouped.svg',
    	data          => {
    		1941 => [ 6.6, 6.2 ],    # UK, US
    		1942 => [ 7.6, 26.4 ],
    	},
    	color         => [ 'blue', 'gray' ],    # index 0, index 1
    	label         => [ 'UK',   'US'   ],    # legend entries
    );

**3. Groups of bars (hash of hashes).** The same picture as (2), but the series
are named by the inner keys rather than by position, so no `label` is needed:

    bar(
    	'output.file' => '/tmp/grouped.hoh.svg',
    	data          => {
    		1941 => { UK => 6.6, US => 6.2 },
    		1942 => { UK => 7.6, US => 26.4 },
    	},
    );

Both grouped forms accept `stacked => 1` to pile the series on top of one
another instead of placing them side by side.

### Error bars

`yerr` (natural for `bar`) and `xerr` (natural for `barh`) take either one
number for every bar, or a hash keyed by the data keys.  A two-element array
gives asymmetric `[ lower, upper ]` errors:

    bar(
    	'output.file' => '/tmp/warheads.svg',
    	data          => { USA => 5277, Russia => 5449 },
    	yerr          => {
    		USA    => [ 15,  29   ],    # -15, +29
    		Russia => [ 199, 1000 ],
    	},
    	log           => 'True',
    	ylabel        => '# of Nuclear Warheads',
    );

### Options

| Option | Description | Example |
| -------- | ------- | ------- 
|color| :mpltype:`color` or list of :mpltype:`color`, optional; The colors of the bar faces. This is an alias for *facecolor*. If both are given, *facecolor* takes precedence # if entering multiple colors, quoting isn't needed; as of version 0.23, colors can be given as a hash |`color => ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'fuchsia'],` or a single color for all bars `color => 'red'`, or as of version 0.23 `color => {A => 'red', B => 'green'}`
|edgecolor| :mpltype:`color` or list of :mpltype:`color`, optional; The colors of the bar edges|`edgecolor		=> 'black'`
|key.order|  define the keys in an order (an array reference)|`'key.order'		=> ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],`
|label| an array of legend labels for grouped bar plots, indexed like the data arrays; only meaningful for the hash-of-arrays form, since the hash-of-hashes form takes its labels from the inner keys|`label => ['North', 'South'],`
|linewidth| float or array, optional; Width of the bar edge(s). If 0, don't draw edges. Only does anything with defined `edgecolor`|`linewidth => 2,`
|log| bool, default: False; If *True*, set the y-axis to be log scale.|`log = 'True',`
|logscale| a synonym for `log` taking a Perl true/false value rather than Python's `'True'`/`'False'`.  Unlike the `logscale` of `boxplot`, `hist`, `hist2d`, `plot`, `scatter` and `violin`, this one is a scalar and not an array of axis names|`logscale => 1,`
|stacked| stack the groups on top of one another; default 0 = off|`stacked	=> 1,`
|width| float only, default: 0.8; The width(s) of the bars.  `width` will be deactivated with grouped, non-stacked bar plots |`width => 0.4,`
|xerr| float or array-like of shape(N,) or shape(2, N), optional. If not *None*, add horizontal / vertical errorbars to the bar tips. The values are +/- sizes relative to the data:        - scalar: symmetric +/- values for all bars #        - shape(N,): symmetric +/- values for each bar #        - shape(2, N): Separate - and + values for each bar. First row #          contains the lower errors, the second row contains the upper #          errors. #        - *None*: No errorbar. (Default)|`yerr						=> {'USA'				=> [15,29],	'Russia'			=> [199,1000],}`
|yerr|same as xerr, but better with bar|

an example of multiple plots, showing many options:

### single, simple plot

    use Matplotlib::Simple 'plt';
    plt(
	    'output.file'			=> 'output.images/single.barplot.png',
	    data	=> { # simple hash
		    Fri => 76, Mon	=> 73, Sat => 26, Sun => 11, Thu	=> 94, Tue	=> 93, Wed	=> 77
	    },
	    'plot.type'	=> 'bar',
	    xlabel		=> '# of Days',
	    ylabel		=> 'Count',
	    title		=> 'Customer Calls by Days'
    );

where `xlabel`, `ylabel`, `title`, etc. are axis methods in matplotlib itself. `plot.type`, `data`, `fh` are all specific to `MatPlotLib::Simple`.
<img width="651" height="491" alt="single barplot" src="https://github.com/user-attachments/assets/eae009a8-5571-4608-abdb-1016e3cff5fd" />

### multiple plots

    plt(
	    fh                  => $fh,
	    execute				   => 0,
	    'output.file'	=> 'output.images/barplots.png',
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
		    		   UK       => 6.6,
	    			   US       => 6.2,
    				   USSR     => 17.8,
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
    );

which produces the plot:

<img width="2678" height="849" alt="barplots" src="https://github.com/user-attachments/assets/6d87d13b-dabd-485d-92f7-1418f4acc65b" />

### colors for each hash key defined by hash

    plt(
    	plots => [
    		{
    			color        => {
    				A => 'red', B => 'green', C => 'blue'
    			},
    			data => {
    				A => 1, B => 2, C => 3
    			},
    			'plot.type'   => 'bar'
    		},
    		{
    			color        => {
    				A => 'red', B => 'green', C => 'blue'
    			},
    			data => {
    				A => 1, B => 2, C => 3
    			},
    			'plot.type'   => 'barh'
    		},
    	],
    	ncols         => 2,
    	'output.file' => '/tmp/key.colors.bar.svg',
    );

which produces the plot

<img width="651" height="491" alt="key colors bar" src="https://github.com/user-attachments/assets/0eab9c75-7e87-4297-b45d-86e5d7ffc550" />

## boxplot

Plot a hash of arrays as a series of boxplots: one box per key, labelled with
the key and the number of points it holds.

### Entering data

Ordinarily `data` is a hash of array refs, one array per box:

    boxplot(
    	'output.file' => '/tmp/boxes.svg',
    	data          => { A => \@a, B => \@b, C => \@c },
    );

A bare array ref is the one-box shorthand; the box gets an empty label:

    boxplot(
    	'output.file' => '/tmp/one.box.svg',
    	data          => \@a,
    );

Undefined values are dropped rather than fatal, so a column read out of a
spreadsheet with blank cells can be handed over as-is; a value that is present
but not a number is an error naming the offending key.  ([`violin`](#violin)
takes exactly these two shapes as well — swapping `'plot.type' => 'boxplot'`
for `'plot.type' => 'violinplot'` is a one-word change — but it drops
non-numeric values silently instead of dying.)

### options

| Option | Description | Example |
| -------- | ------- | ------- |
|`color` | a single color for all boxes | `color => 'pink'`|
|`colors`| a hash pairing each data key with its own color.  Every key in `data` must appear, otherwise the call dies naming the keys that have no color |`colors => { A => 'orange', E => 'yellow', B => 'purple' },`|
| `key.order`| order that the keys in the entry hash will be plotted | `'key.order' => ['A', 'E', 'B']` |
|`logscale`| an array of the axes to put on a log scale; only `x` and `y` are accepted | `logscale => ['y']` |
|`notch`| draw a notched box (`'True'`) instead of a rectangular one | `notch => 'True'` |
| `orientation`| orientation of the plot, by default `vertical`| `orientation => 'horizontal'` |
|`showcaps`| Show the caps on the ends of whiskers; default `True` | `showcaps => 'False',` |
| `showfliers` |Show the outliers beyond the caps; default `True` | `showfliers  => 'False'` |
|`showmeans` | show means; default = `True` | `showmeans   => 'False'` |

`showcaps`, `showfliers`, `showmeans` and `notch` are passed straight through to
Matplotlib, so they take Python's `'True'`/`'False'` rather than a Perl boolean.
The `whiskers` switch belongs to [`violin`](#violin), not to `boxplot`.

### single, simple plot

    my $x = generate_normal_dist( 100, 15, 3 * 10 );
    my $y = generate_normal_dist( 85,  15, 3 * 10 );
    my $z = generate_normal_dist( 106, 15, 3 * 10 );

single plots are simple

    use Matplotlib::Simple 'barplot';
    boxplot(
    	'output.file' => 'output.images/single.boxplot.png',
    	data              => {                                     # simple hash
    		E => [ 55,    @{$x}, 160 ],
    		B => [ @{$y}, 140 ],

    		#		A => @a
    	},
    	title        => 'Single Box Plot: Specified Colors',
    	colors       => { E => 'yellow', B => 'purple' },
    	fh           => $fh,
    	execute      => 0,
    );

which makes the following image:

<img width="651" height="491" alt="single boxplot" src="https://github.com/user-attachments/assets/19870fa2-fe36-4513-8cbb-23da3a0cf686" />

### multiple plots

    plt(
    	'output.file' => 'output.images/boxplot.png',
    	execute           => 0,
    	fh                => $fh,
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
    );

which makes the following plot:

<img width="1230" height="1211" alt="boxplot" src="https://github.com/user-attachments/assets/7e32e394-86fc-49e7-ad97-f48fd82fc8b0" />

## Colored Table

Plot a hash of hashes as a matrix, coloring each cell by its value.

### Entering data

`data` is a hash of hashes: the outer key is the row, the inner key is the
column, and the value is the number that picks the cell's color.

    colored_table(
    	'output.file' => '/tmp/matrix.svg',
    	data          => {
    		H => { H => 432, Cl => 427, Br => 363 },
    		C => { H => 413, Cl => 339, Br => 276 },
    	},
    );

The matrix does not have to be complete.  Cells with no value are left out of
the color scale and drawn in `undef.color` (gray by default), and a table that
only fills one triangle — the usual shape of a pairwise-comparison table — can
be completed by reflecting it across the diagonal with `mirror => 1`, so that
`$data{A}{B}` also supplies `$data{B}{A}`.

Rows and columns are otherwise taken in sorted order.  `col.labels` chooses
which keys are drawn and in what order, which is how the bond-dissociation
example below shows the halogens only out of a larger table; `row.labels`
supplies the text down the left-hand side, so it should list the same keys in
the same order.

### options

| Option | Description | Example |
| -------- | ------- | ------- |
|`cb_logscale`| color the cells on a log scale | `cb_logscale => 1` |
|`cb_min`, `cb_max`| clamp the ends of the color scale instead of taking them from the data, so several tables can be compared directly | `cb_min => 100, cb_max => 500` |
|`cblabel`| the label on the colorbar | `cblabel => 'kJ/mol'` |
|`cmap`| the colormap used for coloring the cells | `cmap => 'viridis'` |
|`col.labels`| array ref: which keys to draw, in order — this selects the rows and the columns of the matrix, not just the heading text | `'col.labels' => ['H', 'F', 'Cl', 'Br', 'I']` |
|`colorbar.on`| draw the colorbar; on by default, `0` turns it off.  Passing `cblabel` draws it regardless | `'colorbar.on' => 0` |
|`mirror`| treat the table as symmetric: `$data{A}{B}` also fills `$data{B}{A}` | `mirror => 1` |
|`row.labels`| array ref of the labels printed down the left side; give it the same keys, in the same order, as `col.labels` | `'row.labels' => ['H', 'F', 'Cl', 'Br', 'I']` |
|`show.numbers`| print each cell's value in the cell; off by default | `'show.numbers' => 1` |
|`undef.color`| the color for cells that have no value; gray by default | `'undef.color' => 'white'` |

The colorbar options in [Color Bars](#color-bars-colorbars) — `cbdrawedges`,
`cblocation`, `cborientation`, `cbpad` — work here too.

### Single, simple plot

the bond dissociation energy table can be plotted:

    # https://labs.chem.ucsb.edu/zakarian/armen/11---bonddissociationenergy.pdf and https://chem.libretexts.org/Bookshelves/Physical_and_Theoretical_Chemistry_Textbook_Maps/Supplemental_Modules_(Physical_and_Theoretical_Chemistry)/Chemical_Bonding/Fundamentals_of_Chemical_Bonding/Bond_Energies
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

and the plot itself:

    colored_table(
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
    );

which makes the following image:

<img width="584" height="491" alt="single tab" src="https://github.com/user-attachments/assets/d890830b-a502-4d51-b118-20aeae0473e8" />

### Multiple Plots

    plt(
    	'output.file' => 'output.images/tab.multiple.png',
    	execute       => 0,
    	fh            => $fh,
    	plots         => [
    		{
    			data          => \%bond_dissociation,
    			'output.file' => '/tmp/single.bonds.svg',
    			'plot.type'   => 'colored_table',
    			set_title     => 'No other options'
    		},
    		{
    			data          => \%bond_dissociation,
    			cblabel       => 'Average Dissociation Energy (kJ/mol)',
    			'col.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
    			mirror        => 1,
    			'output.file' => '/tmp/single.bonds.svg',
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
    			'output.file' => '/tmp/single.bonds.svg',
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
    );

which makes the following plot:

<img width="1410" height="491" alt="tab multiple" src="https://github.com/user-attachments/assets/be836742-cc5b-4618-a0c8-a0ee57856eb1" />

## hexbin

Plot a hash of arrays as a hexbin
see https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.hexbin.html

A hexbin answers the question a scatterplot stops answering once there are tens
of thousands of points: instead of drawing every point and letting them pile up
into an indistinguishable blob, the plane is tiled with hexagons and each one is
colored by how many points fell inside it.

### Entering data

`data` is a hash of exactly **two** array refs of equal length — the first key
(sorted) is the x-axis, the second is the y-axis, and both become the axis
labels.  Use `key.order` to say which is which rather than relying on the sort:

    hexbin(
    	'output.file' => '/tmp/hex.svg',
    	data          => { Height => \@heights, Weight => \@weights },
    	'key.order'   => [ 'Weight', 'Height' ],    # Weight on x
    	cblabel       => 'people per cell',
    );

### options

| Option | Description | Example |
| -------- | ------- | ------- 
| cb_logscale | colorbar log scale `from matplotlib.colors import LogNorm` | default 0, any value > 0 enables |
| cblabel | the label on the colorbar, i.e. what the cell counts mean; `Density` if not given | `cblabel => 'observations'` |
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

`cb_logscale` cannot be combined with `vmin`/`vmax`.  The log-scaled colorbar is
drawn by handing Matplotlib a `LogNorm`, and an explicit range on top of that
makes the generated Python fail; use one or the other.

### single, simple plot

    plt(
    	data	=> {
    		E	=> generate_normal_dist(100, 15, 3*210),
    		B	=> generate_normal_dist(85, 15, 3*210)
    	},
    	'output.file'	=> 'output.images/single.hexbin.png',
    	'plot.type'	=> 'hexbin',
    	set_figwidth => 12,
    	title			=> 'Simple Hexbin',
    );

which makes the following plot:
<img width="1208" height="491" alt="single hexbin" src="https://github.com/user-attachments/assets/129c41cd-2d7d-43de-978a-2b9c441b8939" />
### multiple plots

    plt(
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
    );

which produces the following image:
<img width="2409" height="3211" alt="hexbin" src="https://github.com/user-attachments/assets/0b23a0cb-8f9a-43fb-8da1-0debee13d540" />

## hist

Plot a hash of arrays as a series of histograms, one per key, drawn over each
other in the same axes — `alpha` defaults to 0.5 so that the overlaps stay
readable.  A single array ref is the one-set shorthand.  Values must be numeric:
unlike `boxplot` and `violin`, a non-numeric value here is an error.

Each set is binned separately, so with `bins => 50` two sets covering different
ranges get 50 bins each over their own range rather than a common set of edges.
When the sets must line up exactly — which is what makes the bar heights
comparable — pass the edges themselves rather than a count:

    hist(
    	'output.file' => '/tmp/hist.svg',
    	data          => { E => \@e, B => \@b },
    	bins          => [ map { 10 * $_ } 0 .. 20 ],    # shared edges, 0..200
    );

`bins` and `color` also accept a **hash keyed by set**, for when one
distribution wants different treatment from the others:

    	bins  => { E => 50, B => 20 },
    	color => { E => 'orange', B => 'black' },

The legend is on by default when there is more than one set and off when there is
only one; `show.legend` overrides that either way.

### options

| Option | Description | Example |
| -------- | ------- | ------- |
|`alpha` | opacity of the bars, default 0.5; the same value is used for all sets| `alpha => 0.25` |
|`bins` | int or sequence or str, default: :rc:`hist.bins`.  If *bins* is an integer, it defines the number of equal-width bins in the range. If *bins* is a sequence, it defines the bin edges, including the left edge of the first bin and the right edge of the last bin; in this case, bins may be unequally spaced.  All but the last  (righthand-most) bin is half-open.  May also be a hash keyed by set | `bins => 50` |
|`color` | either one color for every set, or a hash pairing each data key with its own color | `color => { X => 'blue', Y => 'orange' }` |
|`logscale`| an array of the axes to put on a log scale, useful when one set is orders of magnitude rarer than another.  It must be an array reference — `logscale => 1` is an error | `logscale => ['y']` |
|`orientation`| {'vertical', 'horizontal'}, default: 'vertical'| `orientation => 'horizontal'` |
|`show.legend`| on when `data` holds more than one set, off when it holds one; set it explicitly to override | `'show.legend' => 0` |

### single, simple plot

as of version 0.26, single arrays can be given to `hist` instead of a hash, simplifying the call:

    hist(
     	data          => [0..9],
    	'output.file' => '/tmp/hist.arr.svg',
    );

for slightly more complex data sets, hashes are taken:

    use Matplotlib::Simple 'hist';
	
    my @e = generate_normal_dist( 100, 15, 3 * 200 );
    my @b = generate_normal_dist( 85,  15, 3 * 200 );
    my @a = generate_normal_dist( 105, 15, 3 * 200 );

    hist(
    	fh => $fh,
    	execute           => 0,
    	'output.file' => 'output.images/single.hist.png',
    	data              => {
	    	E => @e,
	    	B => @b,
	    	A => @a,
    	}
    );

which makes the following simple plot:

<img width="651" height="491" alt="single hist" src="https://github.com/user-attachments/assets/fafcf787-6c4f-4998-88c4-77a15d878fa6" />

### multiple plots

    plt(
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
    );

<img width="1511" height="491" alt="histogram" src="https://github.com/user-attachments/assets/b13b4cc8-6e64-40b0-913d-6a5886cee0db" />

## hist2d

Make a 2-D histogram from a hash of arrays: like [`hexbin`](#hexbin), `data` is
a hash of exactly **two** equal-length array refs, the first (sorted) key giving
the x-axis and the second the y-axis, and the plane is divided into rectangular
cells colored by how many points landed in each.  `hexbin` and `hist2d` are
interchangeable on the same data — hexagons tile the plane without the visual
grid artefacts of squares, while square bins are easier to read off against the
axes.

### single, simple plot
    plt(
    	'output.file' => 'output.images/single.hist2d.png',
    	data              => {
    		E => @e,
    		B => @b
    	},
    	'plot.type'  => 'hist2d',
    	title        => 'title',
    	execute      => 0,
    	fh => $fh,
    );
makes the following image:

<img width="650" height="491" alt="single hist2d" src="https://github.com/user-attachments/assets/86480c77-7b8f-4bfa-b5d8-71f82830260f" />

the range for the density min and max is reported to stdout

### options

| Option | Description | Example |
| -------- | ------- | ------- |
|`cb_logscale`| make the colorbar log-scale | `cb_logscale => 1` |
|`cblabel`| the label on the colorbar, i.e. what the cell counts mean; `Density` if not given | `cblabel => 'observations'` |
|`cmap`| color map for coloring # "gist_rainbow" by default |  |
|'cmax', `cmin`| All bins that has count < *cmin* or > *cmax* will not be displayed.  `cmin => 1` is the usual way to leave empty cells blank instead of coloring them as zero|`cmin => 1`|
|  'density'|  density : bool, default: False; normalise the counts so the plot shows a probability density instead of raw counts, which is what makes two plots of different-sized samples comparable|`density => 'True'`|
|  'key.order'|  define the keys in an order (an array reference), i.e. which key is the x-axis|`'key.order' => ['Y', 'X']`|
| 'logscale' |    an array of the axes that will get a log scale|`logscale => ['x']`|
|'show.colorbar'| self-evident, 0 or 1; this, and not `colorbar.on`, is what suppresses a `hist2d` colorbar | `show.colorbar` => 0|
|'vmax'| When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover |
|'vmin' | # When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover |
|'xbins'| # default 15
|'xmin', 'xmax',|
|'ymin', 'ymax',|
|'ybins' |  default 15 | 

### multiple plots
    plt(
    	fh => $fh,
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
    );
makes the following image:

<img width="1510" height="491" alt="hist2d" src="https://github.com/user-attachments/assets/3d6becd3-44f3-4511-8b0f-eae39bc325fa" />

## imshow

Plot 2D array of numbers as an image

### Entering data

`data` is a 2-D array — an array of array refs — and nothing else; a hash is an
error.  The generated call leaves Matplotlib's `origin` at its default, so row
`0` is drawn at the **top**; use `invert_yaxis` if your first row is meant to be
the bottom of the picture:

    my @grid;
    foreach my $i (0 .. 360) {
    	foreach my $j (0 .. 360) {
    		push @{ $grid[$i] }, sin($i * $pi/180) * cos($j * $pi/180);
    	}
    }
    imshow(
    	'output.file' => '/tmp/grid.svg',
    	data          => \@grid,
    	cblabel       => 'sin(x) * cos(x)',
    );

The cells may hold **strings** instead of numbers, as long as `stringmap` gives
the meaning of each one — without it, non-numeric data is an error.  Each string
is assigned an integer, the image is drawn with one discrete color per string,
and the colorbar's ticks are labelled with the names from `stringmap` rather than
with numbers.  (`cmap` is dropped, with a warning, when strings are in play,
since the palette has to be a discrete one.)  This is what makes `imshow` usable
for categorical rasters — sequence annotation, land cover, state-over-time
diagrams — and there is a worked example under
[Secondary Structure Prediction (DSSP)](#secondary-structure-prediction-dssp).

Because `imshow` produces a colorbar per subplot, `shared.colorbar` is often
worth setting when several panels show the same quantity: it gives them one
colorbar, and hence one color scale, so the panels can be compared.

### options

| Option | Description | Example |
| -------- | ------- | ------- 
|`cblabel`| colorbar label | `cblabel => 'sin(x) * cos(x)',`
|`cbdrawedges` |draw edges for colorbar | |
|`cblocation` | 'left', 'right', 'top', 'bottom'| `cblocation => 'left',`|
|`cborientation`|  None, or 'vertical', 'horizontal' | 
|`cbpad`| fraction of the original axes between the image and the colorbar; the default 0.05 is often too big for a short, wide image | `cbpad => 0.01,`|
|`cmap`| # The Colormap instance or registered colormap name used to map scalar data to colors.|
|`colorbar.on`| draw the colorbar; on by default, `0` turns it off|`'colorbar.on' => 0`|
|`shared.colorbar`| 0-based indices of the subplots that should share one colorbar, and therefore one color scale|`'shared.colorbar' => [0,1]`|
|`stringmap`| a hash giving the meaning of each string used in `data`, which also makes string data legal|`stringmap => { H => 'Alpha helix' }`|
|`vmax`| float |
|`vmin`| float | 

### single, simple plot

    my @imshow_data;
    foreach my $i (0..360) {
    	foreach my $j (0..360) {
    		push @{ $imshow_data[$i] }, sin($i * $pi/180)*cos($j * $pi/180);
    	}
    }
    plt(
    	data              => \@imshow_data,
    	execute           => 0,
       fh => $fh,
    	'output.file' => 'output.images/imshow.single.png',
    	'plot.type'       => 'imshow',
    	set_xlim          => '0, ' . scalar @imshow_data,
    	set_ylim          => '0, ' . scalar @imshow_data,
    );

which makes the following image:

<img width="599" height="491" alt="imshow single" src="https://github.com/user-attachments/assets/3fa4ffe6-4817-4133-9c91-b68099400377" />

### multiple plots

    plt(
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
    );

which makes the following image:

<img width="2416" height="1811" alt="imshow multiple" src="https://github.com/user-attachments/assets/091acccb-151c-47ca-82cc-99c19d2bff91" />

### Secondary Structure Prediction (DSSP)

Sometimes strings instead of numbers can be entered into a 2-D array, one example is protein secondary structure.
Protein secondary structure can be plotted thus, with a key in `stringmap` to show which strings become which integers in a minimal working example:

    plt(
    	cbpad       => 0.01,          # default 0.05 is too big
    	data        => [              # imshow gets a 2D array
    		[' ', ' ', ' ', ' ', 'G'], # bottom
    		['S', 'I', 'T', 'E', 'H'], # top
    	],
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
    );

<img width="1547" height="491" alt="dssp single" src="https://github.com/user-attachments/assets/712f6199-4a41-4d8f-953e-19df9dacc447" />

or for multiple plots, where the colorbar can be spread across multiple plots now:

    plt(
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
    	nrows             => 2,
    	'output.file'     => 'output.images/dssp.multiple.png',
    	scalex            => 2.4,
    	'shared.colorbar' => [0,1], # plots 0 and 1 share a colorbar
    	suptitle          => 'Dictionary of Secondary Structure in Proteins (DSSP)',
    );

which makes the following plot:

<img width="1547" height="491" alt="dssp multiple" src="https://github.com/user-attachments/assets/d88e295e-1d1e-4e2a-bd5b-48029c46f5b0" />

## pie

Plot a hash of numbers as a pie chart: one wedge per key, sized by its share of
the total.  `data` is the same simple hash that `bar` takes, so the two are
interchangeable — reach for `pie` when the reader should see parts of a whole,
and for `bar` when they should compare the parts with each other.

Wedges are laid out in sorted key order and that order cannot be overridden:
`key.order` is not among the options `pie` accepts.  Nor is a legend added — the
wedges carry their own labels — so `show.legend` is not accepted either.

### options

| Option | Description | Example |
| -------- | ------- | ------- |
|`autopct`| a Python format string for the share printed inside each wedge; omit it and no numbers are drawn | `autopct => '%1.1f%%'` |
|`labeldistance`| where the key label sits, as a fraction of the radius: `0` is the centre, `1` the edge, above `1` outside the pie | `labeldistance => 0.6` |
|`pctdistance`| the same scale, for the `autopct` text.  Swapping the two — labels in, percentages out — is a readable arrangement when the labels are long | `pctdistance => 1.25` |

### single, simple plot

    plt(
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
    	'plot.type'  => 'pie',
    	title        => 'Single Simple Pie',
    	fh           => $fh,
    	execute      => 0,
    );

which makes the image:

<img width="469" height="491" alt="single pie" src="https://github.com/user-attachments/assets/a0bc3212-d013-463a-9be6-f96829ac7dba" />

### multiple plots

    plt(
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
    );

<img width="1210" height="444" alt="pie" src="https://github.com/user-attachments/assets/4c44d300-fd84-49bc-9a32-b73af54286cf" />

## plot

A line plot of one or more series of `(x, y)` points. Each series needs an
x array and a y array of **equal length**.

### Entering data

`data` accepts three shapes:

**1. Labeled series (hash).** Use this when you want a legend — each key
becomes a line label. The value is a `[ \@x, \@y ]` pair:

    {
        'plot.type' => 'plot',
        data        => {
            A => [ [5..9], [5..9] ],
            B => [ [5..9], [1..5] ],
        },
    }

**2. Several unlabeled series (array of pairs).** A list of `[ \@x, \@y ]`
pairs, one per line, with no legend labels:

    {
        'plot.type' => 'plot',
        data        => [
            [ [5..9], [5..9] ],
            [ [5..9], [1..5] ],
        ],
    }

**3. A single unlabeled series (two bare arrays).** The simplest form: just
the x array and the y array, with no enclosing pair-array and no key:

    {
        'plot.type' => 'plot',
        data        => [
            [5..9],
            [5..9],
        ],
    }

Form 3 is shorthand for form 2 with a single line — it is promoted internally
to `[ [ \@x, \@y ] ]`. Because there is no key, the line is **unlabeled**; if
you need a legend entry, use the hash form (1).

> How the forms are told apart: in the multi-line form (2) `data->[0]` is itself
> a `[ \@x, \@y ]` pair, so `data->[0][0]` is an array ref; in the single-line
> form (3) `data->[0]` is the x array, so `data->[0][0]` is a number. A 2-element
> `data` whose first element starts with a number is therefore always read as a
> single line.

### Setting line options with `set.options`

`set.options` is passed straight through to Matplotlib's `.plot(x, y, ...)`,
so anything `plot` accepts works (`color`, `linewidth`, `linestyle`, `marker`,
`alpha`, …). How you supply it depends on the data shape:

**A scalar applies to every line.** This is the natural partner of the
single-line data form — the one option string is used for the only series:

    {
        'plot.type'   => 'plot',
        'show.legend' => 0,
        data          => [
            [ min(vals($df, 'experiment')) .. max(vals($df, 'experiment')) ],
            [ min(vals($df, 'experiment')) .. max(vals($df, 'experiment')) ],
        ],
        'set.options' => 'color = "red"',
    }

The same scalar also works with the multi-line array form, where it is applied
to **all** lines at once:

    {
        'plot.type'   => 'plot',
        data          => [
            [ [5..9], [5..9] ],
            [ [5..9], [1..5] ],
        ],
        'set.options' => 'linewidth = 2',    # both lines
    }

**An array sets options per line (positional).** With array data, give one
string per line; entry `i` styles line `i`. You may supply fewer entries than
lines, but not more:

    {
        'plot.type'   => 'plot',
        data          => [
            [ [5..9], [5..9] ],
            [ [5..9], [1..5] ],
        ],
        'set.options' => [
            'color = "red"',
            'color = "blue", linestyle = "--"',
        ],
    }

**A hash sets options per key.** With hash data, key the options by the same
data keys (any key may be omitted):

    {
        'plot.type'   => 'plot',
        data          => {
            A => [ [5..9], [5..9] ],
            B => [ [5..9], [1..5] ],
        },
        'set.options' => {
            A => 'color = "red"',
            B => 'color = "blue", marker = "o"',
        },
    }

Note the pairing rule: a scalar `set.options` goes with **any** data shape; an
**array** `set.options` goes with **array** data; a **hash** `set.options` goes
with **hash** data. Mismatches (for example a hash of options with array data)
are rejected with an explanatory error.

### Other options

- `show.legend` — on by default (`1`); set to `0` to suppress labels. Only the
  hash form produces labels in the first place.
- `key.order` — array of keys (hash form) fixing the draw/legend order; defaults
  to the keys sorted alphabetically.
- `logscale` — array of axes to put on a log scale, e.g. `[ 'x', 'y' ]`.
- `twinx` — draw selected series against a secondary y-axis.
  - hash data: a single key, or a hash whose keys are the series to twin;
  - array data: an integer index, or an array of indices.
- `twinx.args` — a hash keyed by data key (hash form) or index (array form);
  each value is a hash of axis options (e.g. `ylabel`, `set_ylim`) applied to
  that twin axis.

Common axes options such as `title`, `xlabel`, `ylabel`, and `legend` are
accepted here too, exactly as for the other plot types.

### Two y-axes with `twinx`

Series measured in different units, or on wildly different scales, flatten each
other when they share a y-axis.  `twinx` moves the named series onto a second
y-axis on the right, and `twinx.args` labels it:

    plt(
    	'output.file' => '/tmp/twinx.svg',
    	'plot.type'   => 'plot',
    	data          => {
    		Temperature => [ [@t], [@celsius] ],
    		Pressure    => [ [@t], [@hPa]     ],
    	},
    	twinx         => 'Pressure',                        # onto the right axis
    	'twinx.args'  => { Pressure => { ylabel => 'hPa' } },
    	ylabel        => 'degrees C',                       # the left axis
    	xlabel        => 'hour',
    );

`twinx => 'Pressure'` is shorthand for the single-series case.  To twin more than
one series, pass a hash whose keys are the series to move:

    twinx => { Pressure => 1, Humidity => 1 },

With array data the same options are given by index instead of by key:

    plt(
    	'output.file' => '/tmp/twinx.arr.svg',
    	'plot.type'   => 'plot',
    	data          => [
    		[ [@t], [@celsius] ],    # index 0, left axis
    		[ [@t], [@hPa]     ],    # index 1
    	],
    	twinx         => 1,                              # index 1 goes right
    	'twinx.args'  => { 1 => { ylabel => 'hPa' } },
    );

A `plot` spec is an ordinary plot hash, so it can be dropped straight into the
[`p`](#the-p-argument) argument — on its own for a single subplot, or alongside
other hashes to overlay or to fill a grid of subplots.

### single, simple

data can be given as a hash, where the hash key is the label:

    plt(
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
    );

or as an array of arrays:

    plt(
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
    );

both of which make the following "plot" plot:

<img width="651" height="491" alt="plot single" src="https://github.com/user-attachments/assets/6cbd6aad-c464-4703-b962-b420ec08bb66" />

### multiple sub-plots

which makes

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
    mkdir 'svg' unless -d 'svg';
    my $xticks = "[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
    		. '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']';
    my ($min, $max) = (-9,9);
    plt(
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
    );

<img width="811" height="491" alt="plots" src="https://github.com/user-attachments/assets/0bdd0744-c1bb-4c4a-9482-b3de3f2d4fc2" />

## scatter

Plot points from a hash of arrays.  Beyond x and y, a scatterplot can carry a
third number per point as **color**, which is where most of `scatter`'s options
go.

### Entering data

`data` takes two shapes, and which one you passed is worked out from whether the
values are arrays or hashes.

**1. One set (hash of 2 or 3 array refs).** All the arrays must be the same
length.  Keys are taken in case-insensitive sorted order: the first is x, the
second y, and a third — if present — is the value each point is colored by, which
also gets a colorbar.  Exactly 2 or 3 keys are allowed; anything else is an
error.  The keys become the axis labels, so naming them for the quantity they
hold pays off:

    scatter(
    	'output.file' => '/tmp/scatter.svg',
    	data          => {
    		Height => \@height,    # x
    		Weight => \@weight,    # y
    		Age    => \@age,       # colour + colorbar
    	},
    	color_key     => 'Age',    # say so rather than relying on the sort
    	cmap          => 'viridis',
    );

Sorted order is convenient but fragile — rename a key and the axes swap.  Use
`keys` to fix the roles positionally, or `color_key` to name the color column
explicitly, as above:

    	keys => [ 'Weight', 'Height', 'Age' ],    # x, y, colour

**2. Several labelled sets (hash of hashes of array refs).** The outer key is
the set's legend label; each inner hash is a set of 2 or 3 arrays read exactly as
in form 1.  This is the form to use for "the same measurement, split by group":

    scatter(
    	'output.file' => '/tmp/by.group.svg',
    	data          => {
    		Male   => { Height => \@mh, Weight => \@mw },
    		Female => { Height => \@fh, Weight => \@fw },
    	},
    	'set.options' => {
    		Male   => 'marker = "v", color = "blue"',
    		Female => 'marker = "o", color = "red"',
    	},
    );

With three inner keys, every set is colored by its own third column and the
figure gets a single colorbar, drawn from the last set plotted — so read the
colors across sets only when the color columns cover comparable ranges.
`color_key` then names an **inner** key, and it must exist in every set: naming a
key that is not there is an error rather than being quietly ignored.

### options

| Option | Description | Example |
| -------- | ------- | ------- |
|`cmap`| the colormap used when a third key colors the points; `gist_rainbow` by default | `cmap => 'viridis'` |
|`color_key`| which key of `data` holds the color values, rather than letting the sort decide.  For the multi-set form this is an inner key, and it must be present in every set | `color_key => 'Age'` |
|`keys`| array ref fixing the roles of the keys positionally: x, y, then color | `keys => ['Weight', 'Height', 'Age']` |
|`logscale`| an array of the axes to put on a log scale | `logscale => ['x', 'y']` |
|`set.options`| arguments passed straight to Matplotlib's `ax.scatter`: `marker`, `color`, `alpha`, `s`, …  A **scalar** for the single-set form; a **hash keyed by set name** for the multi-set form.  Options for a set that has no data are an error | `'set.options' => 'marker = "v", alpha = 0.4'` |

`xlabel` and `ylabel` default to the names of the keys used for x and y; set them
explicitly to override.  The colorbar is labelled with the name of the color key
itself, and takes `cbdrawedges` and `cbpad` from
[Color Bars](#color-bars-colorbars).

### single, simple plot
    scatter(
    	fh            => $fh,
    	data          => {
    		X => [@x],
    		Y => [map {sin($_)} @x]
    	},
    	execute       => 0,
    	'output.file' => 'output.images/single.scatter.png',
    );

makes the following image:

<img width="651" height="491" alt="single scatter" src="https://github.com/user-attachments/assets/c45d9922-23e0-4f85-8306-aa7fca400328" />

### options



### multiple plots

    plt(
    	fh => $fh,
    	'output.file' => 'output.images/scatterplots.png',
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
    				X => 'marker = "."',    # point
    				Y => 'marker = "d"'     # diamond
    			},
    			color_key => 'C', # an inner key, present in both sets
    		}
    	]
    );

which makes the following figure:

<img width="1610" height="461" alt="scatterplots" src="https://github.com/user-attachments/assets/b8a90f9f-acb3-4cf2-a423-6ad18686ab8c" />

## venn_proportional_area

Draw an area-proportional Venn diagram, where the size of each region is scaled
to the number of elements it contains.  This plot type wraps the
[`matplotlib_venn`](https://pypi.org/project/matplotlib-venn/) library, so that
library must be installed in addition to `matplotlib`:

    python3 -m pip install matplotlib-venn

`data` is a hash of array references; each key is a **set** and its array is the
set's members (duplicates within a set are collapsed, exactly like a
mathematical set).  Because `matplotlib_venn` only draws proportional-area
diagrams for two or three sets, `data` must contain either **2 or 3** keys.  By
default the sets are labelled and ordered alphabetically by key; use `key.order`
to override that.

### options

| Option | Description | Example |
| -------- | ------- | ------- |
|`alpha`| opacity of the set regions, `0`–`1` (default `0.4`) | `alpha => 0.5`|
|`key.order`| array ref giving the order (and hence label positions) of the sets | `'key.order' => ['Right','Left']`|
|`set_colors`| array ref of colors, one per set | `set_colors => [qw(skyblue lightgreen salmon)]`|
|`title`| the subplot title | `title => 'Gospels vs. Synoptics'`|

### single, simple plot

`venn_proportional_area` is a single-plot wrapper around `plt`, so it can be
called directly:

    venn_proportional_area(
    	'output.file' => 'output.images/single.venn.png',
    	title         => 'Gospels vs. Synoptics',
    	data          => {
    		Gospels  => [qw(Matthew Mark Luke John)],
    		Synoptic => [qw(Matthew Mark Luke)],
    	},
    );

which makes the image:

<img alt="single venn" src="output.images/single.venn.png" />

### multiple plots

Like every other plot type, it can also be one panel among several via `plt`
and the `plots` array; here a two-set diagram sits beside a colored three-set
diagram:

    plt(
    	'output.file' => 'output.images/venn.png',
    	ncols         => 2,
    	suptitle      => 'Proportional-area Venn diagrams',
    	plots => [
    		{
    			'plot.type' => 'venn_proportional_area',
    			title       => 'Two sets',
    			data        => {
    				Perl   => [qw(regex hashes CPAN sigils)],
    				Python => [qw(regex hashes pip indentation)],
    			},
    		},
    		{
    			'plot.type'  => 'venn_proportional_area',
    			title        => 'Three sets with colors',
    			set_colors   => [qw(skyblue lightgreen salmon)],
    			alpha        => 0.5,
    			data         => {
    				Mammals => [qw(bat whale dog cat human platypus)],
    				Aquatic => [qw(whale shark octopus platypus)],
    				Legged  => [qw(dog cat human bat platypus shark)],
    			},
    		},
    	],
    );

which makes the following figure:

<img alt="venn diagrams" src="output.images/venn.png" />

## violin

Plot a hash of array refs as violins: one kernel-density silhouette per key, with
the quartile box, the whiskers and a red dot at the mean drawn over it.  Where a
boxplot summarises a distribution in five numbers, a violin shows its shape, so
bimodal data that a boxplot would hide is visible.

`violin` and `violinplot` are the same subroutine under two names, and both
accept the two data shapes described under [boxplot](#boxplot) — a hash of array
refs, or a bare array ref for a single violin.  Non-numeric and undefined values
are dropped silently.  Each x-axis label carries the number of points that went
into it, so a violin drawn from very few points announces itself.

### options

| Option | Description | Example |
| -------- | ------- | -------
|`color`| a single color for every violin |`color => 'red'`|
|`colors`| a hash pairing each data key with its own color; every key in `data` must appear | `colors       => { E => 'yellow', B => 'purple', A => 'green' }`|
|`key.order`| determine key order display on x-axis|`'key.order' => ['B', 'A', 'E']`|
|`logscale`| an array of the axes to put on a log scale; only `x` and `y` are accepted.  Note this is an array reference, not the `log => 1` scalar that `bar` takes |`logscale => ['y']`|
|`orientation`|'vertical', 'horizontal'}, default: 'vertical'|`orientation => 'horizontal'`|
|`whiskers`| draw the quartile bar and whiskers over the silhouette; on by default, `0` leaves the bare violin |`whiskers => 0`|

### single, simple plot

    plt(
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
    );

which makes:

<img width="651" height="491" alt="single violinplot" src="https://github.com/user-attachments/assets/989650fd-c947-45b0-91c8-c7f71c075cf3" />

### multiple plots

    plt(
    	fh                => $fh,
    	execute           => 0,
    	'output.file'     => 'output.images/violin.png',
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
    );

<img width="1211" height="491" alt="violin" src="https://github.com/user-attachments/assets/248df5e4-fd57-45d6-96da-956af0a7dbfb" />

## wide

Summarise **several runs of the same curve**.  Every run is drawn as a faint
line, the mean of the runs as a solid one, and one standard deviation either side
of the mean as a translucent ribbon.  This is the plot for repeated measurements
— replicate experiments, repeated simulations, one trace per subject — where a
`plot` of every line on top of the others would be an unreadable thicket and a
`plot` of the mean alone would hide how much the runs disagree.

The runs do not have to share an x grid: each group's runs are interpolated onto
101 evenly spaced points spanning that group's own x range before the mean and
the standard deviation are taken, so runs of different lengths, or sampled at
different x values, can be summarised together.

### Entering data

**1. Labelled groups (hash).** Each key is a group and becomes the legend label;
its value is an array of runs, and each run is a `[ \@x, \@y ]` pair — the same
pair [`plot`](#plot) uses:

    my @x = 0 .. 100;
    my %runs;
    foreach my $group ('Clinical', 'HGI') {
    	my $shift = $group eq 'HGI' ? 1 : 0;
    	foreach my $replicate (1 .. 3) {
    		push @{ $runs{$group} }, [
    			[@x],                                                       # x
    			[ map { $shift + sin($_/10) + rand_between(-0.2, 0.2) } @x ] # y
    		];
    	}
    }
    wide(
    	'output.file' => 'output.images/single.wide.png',
    	data          => \%runs,
    	color         => {          # one color per group
    		Clinical => 'blue',
    		HGI      => 'green',
    	},
    	title         => 'Visualization of similar lines plotted together',
    	xlabel        => 'time',
    	ylabel        => 'signal',
    );

**2. One unlabelled group (array).** Drop the enclosing hash and pass one group's
array of runs directly; `color` is then a single color rather than a hash:

    wide(
    	'output.file' => 'output.images/single.array.png',
    	data          => $runs{Clinical},
    	color         => 'red',
    );

A group with a single run is legal — it just produces a line with a
zero-width ribbon — which is convenient when one group has replicates and
another does not.

### options

| Option | Description | Example |
| -------- | ------- | ------- |
|`color`| for hash data, a hash of one color per group; for array data, a single color.  Groups with no entry fall back to Matplotlib's `b` (blue), so a partial hash is allowed | `color => { Clinical => 'blue', HGI => 'green' }` |
|`show.legend`| on by default, and only the hash form has labels to show; `0` suppresses it | `'show.legend' => 0` |

`wide` accepts the usual axes options — `title`, `xlabel`, `ylabel`, `set_xlim`
and the rest — but **not** `logscale` or `key.order`.  For a log axis use
Matplotlib's own `set_yscale => '"log"'`.  Since there is no `key.order`, the
groups are drawn in Perl's hash order, which is arbitrary and differs between
runs: give each group an explicit `color` if you need the same picture twice.

### single, simple plot

Both calls above go through the `wide` wrapper; naming the type explicitly to
`plt` is equivalent and takes exactly the same options:

    plt(
    	'output.file' => 'output.images/single.wide.png',
    	'plot.type'   => 'wide',
    	data          => \%runs,
    	color         => { Clinical => 'blue', HGI => 'green' },
    );

### multiple plots

As an element of `plots`, a `wide` panel is just another plot hash — here the
labelled groups sit beside one group on its own:

    plt(
    	'output.file' => 'output.images/wide.png',
    	ncols         => 2,
    	suptitle      => 'Replicate runs, summarised',
    	plots         => [
    		{
    			'plot.type' => 'wide',
    			data        => \%runs,               # hash of groups of runs
    			color       => { Clinical => 'blue', HGI => 'green' },
    			title       => '"Two groups, mean +/- 1 s.d."', # comma: quoted
    			xlabel      => 'time',
    			ylabel      => 'signal',
    		},
    		{
    			'plot.type'   => 'wide',
    			data          => $runs{Clinical},    # just the runs, unlabelled
    			color         => 'red',
    			'show.legend' => 0,
    			title         => 'One group with no legend',
    		},
    	],
    );

Because a `wide` panel collapses many lines into one summary, it also composes
well with a plot type that shows the same data another way.  Here the runs are
summarised on the left and the distribution of their final values is drawn beside
them:

    my %endpoints;
    foreach my $group (keys %runs) {
    	@{ $endpoints{$group} } = map { $_->[1][-1] } @{ $runs{$group} };
    }
    plt(
    	'output.file' => 'output.images/wide.and.violin.png',
    	ncols         => 2,
    	plots         => [
    		{
    			'plot.type' => 'wide',
    			data        => \%runs,
    			color       => { Clinical => 'blue', HGI => 'green' },
    			title       => 'Runs over time',
    		},
    		{
    			'plot.type' => 'violinplot',
    			data        => \%endpoints,    # hash of arrays, same keys
    			colors      => { Clinical => 'blue', HGI => 'green' },
    			title       => 'Final values',
    		},
    	],
    );

# Advanced
## Notes in Files

all files that can have notes with them, give notes about how the file was written.  For example, SVG files have the following:

    <dc:title>made/written by /mnt/ceph/dcondon/ui/gromacs/tut/dup.2puy/1.plot.gromacs.pl called using "plot" in /mnt/ceph/dcondon/perl5/perlbrew/perls/perl-5.42.0/lib/site_perl/5.42.0/x86_64-linux/Matplotlib/Simple.pm</dc:title>`

## Speed
To improve speed, all data can be written into a single temp python3 file thus:

    use File::Temp;
    my $fh = File::Temp->new( DIR => '/tmp', SUFFIX => '.py', UNLINK => 0 );
	
all files will be written to `$fh->filename`; be sure to put `execute => 0` unless you want the file to be run, which is the last step.

    plt(
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
    );
    # the last plot should have `execute => 1`
    plt(
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
        fh                => $fh,
        execute           => 1,
    );

# Changes

## 0.311 2026-07-27 CDT

Improved README and testing, bug fixes

Back-compatible to Perl-5.10, which the 0.31 broke

## 0.31 2026-07-25 CDT

Removed `Term::ANSIColor` as dependency

added `venn_proportional_area` as a plot helper

## 0.301

Fixes for changes introduced in 0.30 for CPAN testers: https://www.cpantesters.org/cpan/report/143e86c6-77fa-11f1-b73a-21df6d8775ea

Removed files from build directory to shrink tarball

## 0.30

non-ASCII key names (e.g. `ρ`, `τ`) no longer crash the writer. The generated-Python filehandle is now given a UTF-8 encoding layer, fixing a fatal "Wide character in say" that occurred under the module's strict-fatal warnings; the layer is added only when not already present, so a caller-supplied filehandle is never double-encoded.

`p` option: a flat array of subplots where **one element is one subplot** — a hash is a single-plot subplot, and an array of hashes is one subplot with the plots overlaid on the same axes (first hash is the base plot, the rest are additions). The two forms may be mixed in the same `p`. When no grid is given the subplots are laid out on an auto-sized near-square grid; giving only `ncol`/`nrow` (or `ncols`/`nrows`) derives the other dimension.

## 0.29

addition of the `p` option

removal of SHA testing; changes in Matplotlib version 3.11 mean that SHA sums aren't compatible across different versions of Matplotlib

arguments can now be given as a flat hash

## 0.28

colorbar options now work better in `scatter`.

Better warning when color key isn't defined for `scatter`

When giving two hash of hashes for a barplot, if one second key is defined in one subplot, but not the other, that subkey is initialized to 0.

### Cross-platform support

The module now should run on Windows in addition to Linux and macOS.

The generated Python script is written to the system temporary directory (via `File::Spec->tmpdir()`) instead of a hard-coded `/tmp`, which does not exist on Windows.

The Python interpreter is now discovered automatically by probing, in order, `python3`, `python`, and the Windows `py` launcher, accepting the first that reports Python 3. This fixes Windows, where the interpreter is typically named `python` (not `python3`), and correctly rejects the Microsoft Store `python3` stub and any Python 2. Set the `MPLS_PYTHON` (or `PYTHON`) environment variable to override the interpreter with a specific name or full path.

The Python script is now executed with the list form of `system` rather than a single shell string, so script paths containing spaces (common on Windows, e.g. `C:\Users\First Last\AppData\Local\Temp`) no longer break execution.

The `Creator` metadata embedded in the output file is now passed through `write_data` (base64), so Windows paths containing backslashes no longer produce invalid escape sequences (e.g. `\U` in `C:\Users`) in the generated Python string literal.

On Windows, `Win32::Console::ANSI` is loaded if available (it is optional, not a hard dependency) so colored status messages render on legacy consoles.

### Crashes / generated-code fixes

`violinplot` is now a callable wrapper; it was exported and dispatched but never defined, so calling it died with "Undefined subroutine".

`hist` with an array of `bins` no longer emits a stray double-quote (e.g. `[0,2,4"]`) that caused a Python `SyntaxError`.

`hexbin` and `hist2d` no longer pass `cblabel` twice (once inside the option string and again as `label => ...`), which previously caused a duplicate-keyword `SyntaxError`.

`scatter` with a scalar `set.options` no longer emits a doubled comma (`scatter(x, y, , ...)`), which was a `SyntaxError`.

Stacked `barh` now uses the `left` keyword for stacking instead of `bottom`, which collided with `barh`'s own `bottom` (y-position) parameter and raised "got multiple values for keyword argument 'bottom'".

`colored_table` with `cb_logscale` together with `cb_min`/`cb_max` no longer emits `LogNorm(, vmin=...)` with a leading comma (a `SyntaxError`).

`plot` with a hash of data and a scalar `set.options` no longer crashes by dereferencing a string as a hash under `strict refs`.

`plot` with a hash of data now accepts a scalar `twinx` naming a data key (e.g. `twinx => 'pressure'`); previously the value was wrongly required to be a digit string, making key-named `twinx` impossible.

Grouped bar plots with a single scalar `color` (e.g. `color => 'green'`) no longer crash trying to dereference the string as an array; the color is applied to all series.

### Incorrect-output fixes

`colored_table` no longer clobbers asymmetric data: filling undefined cells with `np.nan` previously also overwrote the mirror cell, destroying defined values (if `A->B` was defined but `B->A` was not, both became `NaN`).

`colored_table` now honors `cb_min` and `cb_max`; they were read from the wrong hash (`$args` instead of the plot options) and so were silently ignored.

`colored_table` now honors the `cmap` option; the color map and `set_bad` color were hard-coded to `gist_rainbow` regardless of the `cmap` given. The colormap is copied before calling `set_bad`, as registered colormaps are immutable in current matplotlib.

`colored_table` default row labels now mirror the column labels, matching the matrix that is actually built; with asymmetric data the old default could produce a row-label count mismatch ("'rowLabels' must be of length N").

`scatter` (single set, three keys) now honors the `cmap` option instead of always using `gist_rainbow`.

`scatter` now validates undefined values in *both* coordinate keys; the undefined-data check previously inspected only the first key.

Grouped, non-stacked bar widths are now divided by the number of bar series (plus one), not by a constant; the old divisor came from a hash that always held exactly one key, so groups with more than a few series overlapped their neighbors.

The `wide` plot no longer clamps the upper standard-deviation band at `1`; that clamp assumed data in the range `[0, 1]` and clipped ordinary data (the documented example reaches roughly `1.9`).

Numeric arguments to `plt` methods (e.g. `margins => 0.2`) are no longer quoted into strings; `print_type` now recognizes numbers.

`plt.show()` is now emitted after `plt.savefig()` (and only once), so using `show` no longer writes the file only after the interactive window is closed; `output.file` is no longer required when `show` is requested.

The `add` overlay's `plot.type` now correctly falls back to the parent plot's type when omitted, in both single- and multi-plot calls; the fallback was previously unreachable dead code, and an undefined type could be dispatched on.

### Cleanups

Removed corrupted entries from the method whitelists (`'set_mouseover( '` and a leading-space `' FixedFormatter'`) that made those options unusable.

Removed a stray default applied to the wrong hash in `violin`, two empty dead `if` blocks, and a duplicated `die`.

## 0.27

Better warnings for undefined data in `scatter`

`color_key` didn't work properly for multiple sets of data in `scatter`, which has now been fixed

## 0.26

`ncol` & `nrow` are synonymous with `ncols` and `nrows` respectively; testing now reflects these two specifically numeric options

no longer exports Data::Printer and Devel::Confess with the module, but is still used inside the module

'show.legend' option added to "hist", which is automatically turned off if there is only 1 group

"add" group is no longer deleted

"boxplot", "hist", and "violin" can take a single array, simplifying calls without requiring useless single keys when calling a single distribution

`cb_min` and `cb_max` now work for colored_table

"write_data" is no longer used in hist, as it prints numbers as strings (python3's types are a headache)

Instead, all values are checked in hist for being numeric before being sent to "write_data"

re-use undefined error array in hist_helper (slightly less RAM use)

## 0.25

re-used error array in scatter_helper

better warnings for undefined values in multiple-set scatterplots

fixed bug in scatterplot, where different sets would have the same label

"logscale" now available with "boxplot, "hist", "plot", "scatter"

$VERSION now prints with metadata for SVG output files, which required minor changes to testing

slightly better warnings in plot_helper

removed duplicate check from hist2d_helper

better warnings if wrong data types are given to "add"

Fixed bug in scatterplot, where color key could repeat on axes

colorbar can now be in logscale for colored_table
---
## 0.24
---
Newlines are now possible in key names for barplot and pie; other characters may be fixed too

@prop_cycle is only now taking RAM/valid where it's needed

new dependencies in JSON::MaybeXS and MIME::Base64 to prevent errors in key names

slight improvement in violinplot: "print" changed to "say" (1 less concatenation)

dynamic method wrappers are used, which save ~120 lines of code

re-used error array in "plt" to save RAM

better warning for non-File::Temp objects

more tests for wrapper subroutines

duplicate check removed from hexbin_helper

removed whiskers option from boxplot_helper, which didn't work the way that I thought that it did

removed shebang, which isn't necessary in .pm files

hist2d was missing an option for logscale on the axes, which it now has
---
## 0.23
---
colors for bar plots can be defined by hashes; e.g. colors => {A => 'red', B => 'green'}, etc
---
## 0.22
---
minor under-the-hood changes; "execute" subroutine, which was only called once, is now built into "plt" to save a function call; execution should be slightly faster/more efficient
---
## 0.21
---
"show" now works; files are still output if specified
---
## 0.20
---
better warnings for incomplete data in "plot"
"plot" can plot with "twinx" when data is given in array or hash form
"tick_params" is removed from plt methods
fewer "my" for error arrays, using empty arrays from earlier; should increase efficiency slightly
added tests for twinx in plot for both array and hash variants

# COPYRIGHT AND LICENSE

This software is free.  It is licensed under the same terms as Perl itself
