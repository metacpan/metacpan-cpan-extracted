# Toby Thurston -- 09 Jun 2017 
# Plot a nice picture of a series of maps

use strict;
use warnings;

use Geo::Coordinates::OSGB       qw(ll_to_grid_helmert);
use Geo::Coordinates::OSGB::Grid qw(format_grid);
use Geo::Coordinates::OSGB::Maps qw(%maps %name_for_map_series);

use Getopt::Long;
use Pod::Usage;
use File::Temp;
use File::Spec;
use Carp;

our $VERSION = '2.17';

=pod

=head1 NAME

plot_maps - make a nice index sheet for a map series

This programme shows off several features of L<Geo::Coordinates::OSGB>.
If you have a working TeXLive installation with GhostScript installed,
you can use it to produce PDF index maps of the various map series
provided by L<Geo::Coordinates::OSGB::Maps>.

=head1 SYNOPSIS

  perl plot_maps.pl --series A --paper A3 --outfile some.pdf 
                    --[no]grid --[no]graticule --[no]towns 
                    --[no]ostn --[no]coast

=head1 OPTIONS

=over 4 

=item --series [ABC...]

Print the outlines of one of more map series.  The argument
should be one of the keys of the map series defined 
by L<Geo::Coordinates::OSGB::Maps>.  Currently: A=Landranger, 
B=Explorer, C=One-inch, H=Harvey Mountain Maps, J=Harvey Superwalker.

You can combine keys to get a concordance but the result may not be easy to read.

Default is none - no map outlines are printed.

=item --paper A[01234]

The preferred paper size for the output. Default is A3.

=item --outfile some.pdf

The output file name. Default depends on the choice of C<--series>.
With no series selected the name will be C<National_grid.pdf>.  Otherwise
it will be C<Index_for_map_series_X.pdf> where C<X> is the chosen series.

=item --[no]grid

Show the grid lines and squares. Turn off with C<--nogrid>. Default is on.

=item --[no]graticule

Show lines of latitude and longitude.  Turn off with C<--nograt>.  Default on.

=item --[no]towns

Show a few major cities in the background.  Turn off with C<--notowns>.

=item --[no]ostn

Show the boundaries of the OSTN02 transformation dataset.  Default is off.

=item --[no]coast

Plot the coast line found in C<gb-coastline.shapes>.  This input is an ESRI
shape dump file with longitude and latitude pairs on each line, and each shape
separated by a line with a leading # character.  The code below shows you how to 
read it and convert it to grid coordinates.
Default is to show the coast lines.  Turn off with C<--nocoast>.

=item --usage, help, man

Show increasing amounts of help text, and exit.

=item --version

Print version and exit.

=back

=head1 DESCRIPTION

This section describes how L<Geo::Coordinates::OSGB> functions are used.

=head2 Converting longitude and latitude to grid

Since the output consists of the whole country formatted for an A4 or A3 page
a thin line on the page will represent a distance of at least 500 m on the
ground so the C<ll_to_grid_helmert> routine gives all the accuracy we need.

The coast line shapes also include points outside the OSTN02 area; this is another reason 
to stick to C<ll_to_grid_helmert> directly.  

Shape files usually have the coordinates given with longitude before latitude; be sure 
to swap them round for C<ll_to_grid_helmert>.

=head2 Getting the scale right

The usual grid area is 700km by 1250km, but to allow for some room round the map
the scale is worked out by allowing for 1000km to be printed horizontally across
the page.  For A3 the page width is 297mm, so the scale is 297 mm : 1000 km or about 
1:3,360,000, but in the current example the units of measure are PostScript points
so the width of the page is 842 pt and the scale factor is 1000000/842 = 1188.  

If you don't care about the page size, it's convenient to use a scale factor of
1000 and represent 1km on the ground by 1 PostScript point.  This is a scale of
about 1:2,835,000.  If you are printing small areas you might like to use the conventional 
scales favoured by the OS:
   
   Scale                Factor to use
   ----------------------------------
   1:250,000            88.194
   1:50,000             17.6388
   1:25,000              8.8194

Once you have set your scale, you can apply it by passing the output from C<ll_to_grid>
through C< ... map { $_/$scale } ... >.

=head2 Working with the map data

The implementation of C<Geo::Coordinates::OSGB::Maps> is experimental and may change 
significantly in future releases.  Possibly the hash exports will be replaced
by a more sophisticated object-oriented interface.
In the mean while, this programme shows how to use the current map data.

To plot a map, it's best to join up the points returned by C<< $maps{$k}->{polygon} >>
rather than make any assumption about the size of the sheets.  This is because most of the 
sheets are not regular rectangles.  The polygon data includes all the marginal extensions
as well as insets.  To find the centre of the map, the simple approach is to find the 
average of the lower left and upper right corners given in C<< $maps{$k}->{bbox} >>.
This is OK for most sheets, but not so good for the odd shaped insets.

You can distinguish an inset from a main sheet with the C<{parent}> key.  If C<$k> is one
of the keys from C<%maps> then C<$maps{$k}> is an inset if C<< $k ne $maps{$k}->{parent} >>.
The parent key links to the parent sheet for the inset.

=head1 DIAGNOSTICS 

If you get the options wrong or you supply any arguments you will get the usage message.

Otherwise you'll get a short pause while we create a Metapost file.

When that's done, we try to run C<mpost>.  If you don't have Metapost installed you 
will get an OS error and the programme will die with the message "Metapost call failed".

If Metapost runs ok, then we try to run C<epstopdf> to turn the PostScript output
produced by Metapost into a PDF.  If this doesn't work, the programme will die with 
the message "epstopdf call failed".

If everything works ok, then the programme tries to clean up the 
temporary files that Metapost will have created.  If this does not work you will
get a message saying "Failed to delete temporary file:...".  

Finally if all has worked, you will get a message telling you that the programme has created a PDF file.

=head1 DEPENDENCIES

You need a working copy of C<mpost> and C<epstopdf> to get the PDF output.  The simplest way 
to install them is to install a complete TeXLive distribution, including GhostScript.  
This is easy on OSX or Linux. On Windows these functions are also provided by MikTeX.

=head1 AUTHOR

Toby Thurston -- 14 Feb 2016 

toby@cpan.org

=cut

my $series_wanted;
my $paper_size      = 'A3'; 
my $show_grid       = 1;    
my $show_graticule  = 1;
my $show_towns      = 1;
my $show_ostn02     = 0;
my $show_coast      = 1;
my $call_MP         = 1;
my $pdf_filename;

my $options_ok = GetOptions(
    'series=s'    => \$series_wanted,                               
    'paper=s'     => \$paper_size,                                  
    'grid!'       => \$show_grid,                                   
    'graticule!'  => \$show_graticule,                              
    'towns!'      => \$show_towns,
    'ostn!'       => \$show_ostn02,
    'outfile=s'   => \$pdf_filename,
    'coast!'      => \$show_coast,
    'mpost!'      => \$call_MP,
    
    'version'     => sub { warn "$0, version: $VERSION\n"; exit 0; }, 
    'usage'       => sub { pod2usage(-verbose => 0, -exitstatus => 0) },                         
    'help'        => sub { pod2usage(-verbose => 1, -exitstatus => 0) },                         
    'man'         => sub { pod2usage(-verbose => 2, -exitstatus => 0) },

);
die pod2usage() if @ARGV || ! $options_ok;

if ( ! $pdf_filename ) {
    if ( $series_wanted ) { 
        $pdf_filename = "Index_for_map_series_$series_wanted.pdf"
    }
    else {
        $pdf_filename = "National_grid.pdf"
    }
}

$paper_size = uc $paper_size;
my $scale = $paper_size eq 'A4' ? 1680
          : $paper_size eq 'A3' ? 1189
          : $paper_size eq 'A2' ?  840
          : $paper_size eq 'A1' ?  597
          : $paper_size eq 'A0' ?  420
          : 1000;

sub does_not_overlap_parent {
    my $k = shift;
    my $m = $maps{$k};
    my $p = $maps{$m->{parent}};
    return $m->{bbox}[0][0] > $p->{bbox}[1][0] 
        || $m->{bbox}[1][0] < $p->{bbox}[0][0] 
        || $m->{bbox}[1][1] < $p->{bbox}[0][1] 
        || $m->{bbox}[0][1] > $p->{bbox}[1][1];
}

# filter out the series we don't want, save a MP path for each sheet that we do want
# and group the sheet keys into sides and insets
my %path_for = ();
my @sides;
my @insets;
if ( $series_wanted ) {
    for my $k ( keys %maps ) {
        next if -1 == index($series_wanted, substr($k,0,1) );

        my @points = @{$maps{$k}->{polygon}};
        pop @points; # remove last, so we can replace it with cycle

        $path_for{$k} = join('--', 
            map { sprintf "(%.1f,%.1f)", $_->[0]/$scale, $_->[1]/$scale }
            @points) . '--cycle';

        if ($k eq $maps{$k}->{parent}) {
            push @sides, $k
        }
        else {
            push @insets, $k
        }
    }
}

my %color_for = (
    A => '(224/255,36/255,114/255)', # Landranger pink
    B => '(221/255,61/255, 31/255)', # Explorer orange
    C => '(228/255, 0, 28/255)',     # Seventh series red
    H => '(128/255, 4/255, 36/255)', # Harvey dark red
    J => '(128/255, 4/255, 36/255)', # Harvey dark red
);

# open a tempory file for MP
my $plotter = File::Temp->new( TEMPLATE => 'plot_maps_XXXXX', DIR => '.', SUFFIX => '.mp' );
my $epsfile = $plotter->filename; $epsfile =~ s/\.mp\Z/.eps/;
my $logfile = $plotter->filename; $logfile =~ s/\.mp\Z/.log/;

print $plotter 'prologues := 3; outputtemplate := "%j.eps"; beginfig(1); defaultfont := "phvr8r";', "\n";

for my $k ( @sides, @insets ) {
    print $plotter "fill $path_for{$k} withcolor ( 0.98, 0.906, 0.71);\n";
}

if ($show_graticule) {
    print $plotter "drawoptions(withpen pencircle scaled 0.4);\n";
    for my $lon (-10..2) {
        my @points = ();
        for my $lat (496..612) {
            push @points, sprintf '(%.1f,%.1f)', map { $_/$scale } ll_to_grid_helmert($lat/10,$lon);
        }
        print $plotter 'draw ', join('--', @points), ' withcolor .7[.5 green,white];';
        print $plotter sprintf 'label.bot("%s" & char 176, %s) withcolor .4 green;', $lon, $points[0];
    }
    for my $lat (50..61) {
        my @points = ();
        for my $lon (-102..22) {
            push @points, sprintf '(%.1f,%.1f)', map { $_/$scale } ll_to_grid_helmert($lat,$lon/10);
        }
        print $plotter 'draw ', join('..', @points), ' withcolor .7[.5 green,white];';
        print $plotter sprintf 'label.lft("%s" & char 176, %s) withcolor .4 green;', $lat, $points[0];
    }
} 

if ($show_grid) {
    print $plotter 'drawoptions(withcolor .7 white);';
    print $plotter sprintf 'z0=(%g,%g);', 700000/$scale, 1200000/$scale;
    print $plotter 'label.llft("0",origin) withcolor .5 white;',"\n";

    my ($e, $n);
    for my $i (0..7) {
        $e = $i*100_000; 
        print $plotter sprintf 't:=%g;draw (t,0) -- (t,y0);', $e/$scale;
        print $plotter sprintf 'label.bot("%d", (t,0)) withcolor .5 white;', $i*100 if $i>0;
        for my $j (0..12) {
            $n = $j*100_000; 
            if ($i==0) {
                print $plotter sprintf 't:=%g;draw (0,t) -- (x0,t);', $n/$scale;
                print $plotter sprintf 'label.lft("%d", (0,t)) withcolor .5 white;', $j*100 if $j>0;
            }
            if ($i < 7 && $j < 12 ) {
                my $sq = format_grid($e, $n, { form => 'SS' });
                print $plotter sprintf 'label("%s" infont "phvr8r" scaled 3, (%d,%d)) withcolor .8 white;', 
                                              $sq, map { (50000+$_)/$scale } $e, $n;
            }
        }
    }
}

my $coast_shapes = File::Spec->catpath((File::Spec->splitpath($0))[0,1], 'gb-coastline.shapes');
if ( $show_coast && -f $coast_shapes && open my $coast, '<', $coast_shapes ) {
    print $plotter "drawoptions(withpen pencircle scaled 0.2 withcolor (0, 172/255, 226/255));\n";
    my @poly_path = ();
    LINE: while ( <$coast> ) {
        if ( /^#/ ) {
            printf $plotter "draw %s;\n", join('--', @poly_path);
            @poly_path = ();
            next LINE;
        }
        push @poly_path, sprintf "(%g,%g)", map {$_/$scale} ll_to_grid_helmert(reverse split);
    }
    close $coast;
}

if ($show_towns ) {
    my %towns = (
        Aberdeen       => [ 392500, 806500 ], 
        Birmingham     => [ 409500, 287500 ], 
        Bristol        => [ 360500, 175500 ], 
        Cambridge      => [ 546500, 258500 ], 
        Canterbury     => [ 614500, 157500 ], 
        Cardiff        => [ 318500, 176500 ], 
        Carlisle       => [ 339500, 555500 ], 
        Edinburgh      => [ 327500, 673500 ], 
        Glasgow        => [ 259500, 665500 ], 
        Inverness      => [ 266500, 845500 ], 
        Leeds          => [ 430500, 434500 ], 
        Liverpool      => [ 337500, 391500 ], 
        London         => [ 531500, 181500 ], 
        Manchester     => [ 383500, 398500 ], 
        Newcastle      => [ 425500, 564500 ], 
        Oxford         => [ 451500, 206500 ], 
        Plymouth       => [ 247500, 56500 ], 
        Portsmouth     => [ 465500, 101500 ], 
        Salisbury      => [ 414500, 130500 ], 
        Sheffield      => [ 435500, 387500 ], 
        Worcester      => [ 385500, 255500 ], 
    );

    print $plotter "drawoptions(withcolor .7 white);defaultscale := 1/2;\n";
    for my $t (keys %towns) {
        print $plotter sprintf "dotlabel.top(\"$t\", (%g,%g));\n", map {$_/$scale} @{$towns{$t}};     
    }
}

if ( $series_wanted && @sides ) { # sides will be empty if none of the maps matched series_wanted

    print $plotter "drawoptions(withpen pencircle scaled 0.2);defaultscale:=0.71;\n";

    for my $k ( @sides ) {
        my $series = substr($k,0,1);
        my $map_color = exists $color_for{$series} ? $color_for{$series} : 'black';
        print $plotter "draw $path_for{$k} withcolor $map_color;\n";
        my $label = $maps{$k}->{number};
        my ($x, $y) = map { $_/$scale } ($maps{$k}->{bbox}[1][0]+$maps{$k}->{bbox}[0][0])/2,
                                        ($maps{$k}->{bbox}[1][1]+$maps{$k}->{bbox}[0][1])/2;
       
        if (my ($old, $new) = $label =~ m{\A(\d+)/(OL\d+)\Z} ) {
            print $plotter "label(\"$old\", ($x, $y+3)) withcolor .76[white,$map_color];\n";
            print $plotter "label(\"$new\", ($x, $y-3)) withcolor .76[white,(.5,.5,1)];\n";
        }
        else {
            $map_color = '(.5,.5,1)' if ( substr($label,0,2) eq 'OL' );                                 
            print $plotter "label(\"$label\", ($x, $y)) withcolor .76[white,$map_color];\n";
        }
    }
    print $plotter 'path p,q;';
    for my $k ( @insets ) {
        my $series = substr($k,0,1);
        my $map_color = exists $color_for{$series} ? $color_for{$series} : 'black';
        print $plotter "p:=$path_for{$k};\n";
        if ( does_not_overlap_parent($k) ) {
            print $plotter sprintf 'q:=%s;', $path_for{$maps{$k}->{parent}};
            print $plotter "draw center p -- center q cutbefore p cutafter q dashed evenly scaled 1/3 withcolor $map_color;\n";
        }
        print $plotter "draw p withcolor $map_color;\n";
    }

    my $y = 1300000/$scale;
    for my $s ( split '', $series_wanted ) {
        print $plotter sprintf "label.rt(\"%s sheet index\" infont defaultfont scaled 2, (0,%g)) withcolor %s;\n",
                               $name_for_map_series{$s}, $y,
                               exists $color_for{$s} ? $color_for{$s} : 'black';
        $y -= 24;
    }

    # add sheet names for Harvey maps
    if ( $series_wanted eq 'H' or $series_wanted eq 'J' ) {
        print $plotter "defaultscale:=0.9;\n";
        my $x = 510000/$scale;
        my $y = 515000/$scale;
        printf $plotter 'fill unitsquare xscaled %g yscaled %g shifted (%g,%g) withcolor background;',
                        200000/$scale, 12*@sides+4, $x-5, $y;
        for my $k ( reverse sort @sides ) {
            my $label = "$maps{$k}->{number} $maps{$k}->{title}";
            print $plotter "draw \"$label\" infont defaultfont shifted ($x,$y);\n";
            $y += 12;
        }
    }

}

my $obp_file = File::Spec->catpath((File::Spec->splitpath($0))[0,1], 'ostn-boundary-polygons.wkt');
if ($show_ostn02) {
    if (-f $obp_file && open my $obp, '<', $obp_file) {
        # Add OSTN02 boundary
        printf $plotter 'drawoptions(withcolor (.6,.64,.84));';
        while ( <$obp> ) {
            if ( my ($p) = $_ =~ m{\A POLYGON \s+ \(\((.*)\)\)\s*\Z}iosmx ) {
                printf $plotter "draw %s;\n", 
                join '--', 
                map { sprintf '(%g, %g)', $_->[0]*1000/$scale, $_->[1]*1000/$scale }
                map { [ split ' ' ] } split ',', $p;
            }
        }
        printf $plotter 'drawoptions();';
    }
    else {
        carp "No OSTN boundary shown, can't find or open $obp_file\n"
    }
}

# Add a margin
print $plotter 'z1 = center currentpicture;';
print $plotter 'setbounds currentpicture to bbox currentpicture shifted -z1 scaled 1.05 shifted z1;';
print $plotter "endfig;end.\n";
close $plotter;

if ( $call_MP ) {
    system('mpost', $plotter->filename)               == 0 or croak "Metapost call failed";
    system('epstopdf', "-o=$pdf_filename", $epsfile)  == 0 or croak "epstopdf call failed";

    unlink($epsfile) or carp "Failed to delete temporary file: $epsfile, $!";
    unlink($logfile) or carp "Failed to delete temporary file: $logfile, $!";

    print "$0: Created $pdf_filename\n";
}
