#==========================================================================
#              Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph.pm
#
#   Description:
#       Module to create graphs from a data set drawing on a GD::Image
#       object
#
#       Package of a number of graph types:
#       GD::Graph::bars
#       GD::Graph::hbars
#       GD::Graph::lines
#       GD::Graph::points
#       GD::Graph::linespoints
#       GD::Graph::area
#       GD::Graph::pie
#       GD::Graph::mixed
#
# $Id: Graph.pm,v 1.55 2007/04/26 04:12:47 ben Exp $
#
#==========================================================================

#
# GD::Graph
#
# Parent class containing data all graphs have in common.
#

package GD::Graph;

($GD::Graph::prog_version) = '$Revision: 1.55 $' =~ /\s([\d.]+)/;
$GD::Graph::VERSION = '1.54';

use strict;
use GD;
use GD::Text::Align;
use GD::Graph::Data;
use GD::Graph::Error;
use Carp;

@GD::Graph::ISA = qw(GD::Graph::Error);

# Some tools and utils
use GD::Graph::colour qw(:colours);

my %GDsize = ( 
    'x' => 400, 
    'y' => 300 
);

my %Defaults = (

    # Set the top, bottom, left and right margin for the chart. These 
    # margins will be left empty.
    t_margin      => 0,
    b_margin      => 0,
    l_margin      => 0,
    r_margin      => 0,

    # Set the factor with which to resize the logo in the chart (need to
    # automatically compute something nice for this, really), set the 
    # default logo file name, and set the logo position (UR, BR, UL, BL)
    logo          => undef,
    logo_resize   => 1.0,
    logo_position => 'LR',

    # Do we want a transparent background?
    transparent   => 1,

    # Do we want interlacing?
    interlaced    => 1,

    # Set the background colour, the default foreground colour (used 
    # for axes etc), the textcolour, the colour for labels, the colour 
    # for numbers on the axes, the colour for accents (extra lines, tick
    # marks, etc..)
    bgclr         => 'white',   # background colour
    fgclr         => 'dblue',   # Axes and grid
    boxclr        => undef,     # Fill colour for box axes, default: not used
    accentclr     => 'gray',    # bar, area and pie outlines.

    labelclr      => 'dblue',   # labels on axes
    axislabelclr  => 'dblue',   # values on axes
    legendclr     => 'dblue',   # Text for the legend
    textclr       => 'dblue',   # All text, apart from the following 2

    valuesclr     => 'dblue',   # values printed above the points
    
    # data set colours
    dclrs => [qw(lred lgreen lblue lyellow lpurple cyan lorange)], 

    # number of pixels to use as text spacing
    text_space    => 4,

    # These have undefined values, but are here so that the set method
    # knows about them:
    title       => undef,
);

sub _has_default { 
    my $self = shift;
    my $attr = shift || return;
    exists $Defaults{$attr} 
}

#
# PUBLIC methods, documented in pod.
#
sub new  # ( width, height ) optional;
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    if (@_) 
    {
        # If there are any parameters, they should be the size
        return GD::Graph->_set_error(
            "Usage: GD::Graph::<type>::new(width, height)") unless @_ >= 2;

        $self->{width} = shift;
        $self->{height} = shift;
    } 
    else 
    {
        # There were obviously no parameters, so use defaults
        $self->{width} = $GDsize{'x'};
        $self->{height} = $GDsize{'y'};
    }

    # Initialise all relevant parameters to defaults
    # These are defined in the subclasses. See there.
    $self->initialise() or return;

    return $self;
}

sub get
{
    my $self = shift;
    my @wanted = map $self->{$_}, @_;
    wantarray ? @wanted : $wanted[0];
}

sub set
{
    my $self = shift;
    my %args = @_;
    my $w = 0;

    foreach (keys %args) 
    { 
        # Enforce read-only attributes.
        /^width$/ || /^height$/ and do 
        {
            $self->_set_warning("Read-only attribute '$_' not set");
            $w++;
            next;
        };

        $self->{$_} = $args{$_}, next if $self->_has_default($_); 

        $w++;
        $self->_set_warning("No attribute '$_'");
    }

    return $w ? undef : "No problems";
}

# Generic routine to instantiate GD::Text::Align objects for text
# attributes
sub _set_font
{
    my $self = shift;
    my $name = shift;

    if (! exists $self->{$name})
    {
        $self->{$name} = GD::Text::Align->new($self->{graph}, 
            valign => 'top',
            halign => 'center',
        ) or return $self->_set_error("Couldn't set font");
    }

    $self->{$name}->set_font(@_);
}

sub set_title_font # (fontname, size)
{
    my $self = shift;
    $self->_set_font('gdta_title', @_);
}

sub set_text_clr # (colour name)
{
    my $self = shift;
    my $clr  = shift;

    $self->set(
        textclr       => $clr,
        labelclr      => $clr,
        axislabelclr  => $clr,
        valuesclr     => $clr,
    );
}

sub plot
{
    # ABSTRACT
    my $self = shift;
    $self->die_abstract("sub plot missing,");
}

# Set defaults that apply to all graph/chart types. 
# This is called by the default initialise methods 
# from the objects further down the tree.

sub initialise
{
    my $self = shift;

    foreach (keys %Defaults) 
    {
        $self->set($_ => $Defaults{$_});
    }

    $self->open_graph()                     or return;
    $self->set_title_font(GD::Font->Large)  or return;
}


# Check the integrity of the submitted data
#
# Checks are done to assure that every input array 
# has the same number of data points, it sets the variables
# that store the number of sets and the number of points
# per set, and kills the process if there are no datapoints
# in the sets, or if there are no data sets.

sub check_data # \@data
{
    my $self = shift;
    my $data = shift;

    $self->{_data} = GD::Graph::Data->new($data) 
        or return $self->_set_error(GD::Graph::Data->error);
    
    $self->{_data}->make_strict;

    $self->{_data}->num_sets > 0 && $self->{_data}->num_points > 0
        or return $self->_set_error('No data sets or points');
    
    if ($self->{show_values})
    {
        # If this isn't a GD::Graph::Data compatible structure, then
        # we'll just use the data structure.
        #
        # XXX We should probably check a few more things here, e.g.
        # similarity between _data and show_values.
        #
        my $ref = ref($self->{show_values});
        if (! $ref || ($ref ne 'GD::Graph::Data' && $ref ne 'ARRAY'))
        {
            $self->{show_values} = $self->{_data}
        }
        elsif ($ref eq 'ARRAY')
        {
            $self->{show_values} =
                GD::Graph::Data->new($self->{show_values})
                or return $self->_set_error(GD::Graph::Data->error);
        }
    }

    return $self;
}

# Open the graph output canvas by creating a new GD object.

sub open_graph
{
    my $self = shift;
    return $self->{graph} if exists $self->{graph};
    $self->{graph} = 2.0 <= $GD::VERSION 
        ?   GD::Image->newPalette($self->{width}, $self->{height})
        :   GD::Image->new($self->{width}, $self->{height});

}

# Initialise the graph output canvas, setting colours (and getting back
# index numbers for them) setting the graph to transparent, and 
# interlaced, putting a logo (if defined) on there.

sub init_graph
{
    my $self = shift;

    $self->{bgci} = $self->set_clr(_rgb($self->{bgclr}));
    $self->{fgci} = $self->set_clr(_rgb($self->{fgclr}));
    $self->{tci}  = $self->set_clr(_rgb($self->{textclr}));
    $self->{lci}  = $self->set_clr(_rgb($self->{labelclr}));
    $self->{alci} = $self->set_clr(_rgb($self->{axislabelclr}));
    $self->{acci} = $self->set_clr(_rgb($self->{accentclr}));
    $self->{valuesci} = $self->set_clr(_rgb($self->{valuesclr}));
    $self->{legendci} = $self->set_clr(_rgb($self->{legendclr}));
    $self->{boxci} = $self->set_clr(_rgb($self->{boxclr})) 
        if $self->{boxclr};

    $self->{graph}->transparent($self->{bgci}) if $self->{transparent};
    $self->{graph}->interlaced( $self->{interlaced} || undef ); # required by GD.pm

    # XXX yuck. This doesn't belong here.. or does it?
    $self->put_logo();

    return $self;
}

sub _read_logo_file
{
    my $self = shift;
    my $glogo;
    local (*LOGO);
    my $logo_path = $self->{logo};
    open(LOGO, $logo_path) 
        or do { carp "Unable to open logo file '$logo_path': $!";return};
    binmode(LOGO);
    # if the file has an extension, use that importer
    my $gdimport;
    my @tried;
    # possibly forward-compatible: just try whatever file extension
    if ( $logo_path =~ /\.(\w+)$/i) {
        my $fmt = lc $1;
        $fmt = "jpeg" if 'jpg' eq $fmt;
        push @tried, uc $fmt;
        if ($gdimport = GD::Image->can("newFrom\u$fmt")) {
            if ('xpm' ne $fmt) { $glogo = GD::Image->$gdimport(\*LOGO) }
            else { $glogo = GD::Image->$gdimport($logo_path) } # quirky special case
        }
    } 
    # if that didn't work, try using magic numbers
    if (!$glogo) {
        my $logodata;
        read LOGO,$logodata, -s LOGO;
        my %magic = (
            pack("H8",'ffd8ffe0') => "jpeg",
            'GIF8' => "gif",
            '.PNG' => "png",
            '/* X'=> "xpm", # technically '/* XPM */', but I'm hashing, here
        );
        if (my $match = $magic{ substr $logodata, 0, 4 }) {
            push @tried, $match;
            my $matchmethod = "newFrom\u$match";
            if ($gdimport = GD::Image->can($matchmethod . "Data")) {
                $glogo = GD::Image->$gdimport($logodata);
            } elsif ($gdimport = GD::Image->can($matchmethod)) {
                if ('xpm' eq $match) { 
                    $glogo = GD::Image->$gdimport($logo_path);
                } else {
                    seek LOGO,0,0;
                    $glogo = GD::Image->$gdimport(\*LOGO);
                }
            }
        # should this actually be "if (!$glogo), rather than an else?            
        } else { # Hail Mary, full of Grace!  Blessed art thou among women...
            push @tried, 'libgd best-guess';
            $glogo = GD::Image->new($logodata);
        }
    }
    close LOGO or croak "Unable to close logo file '$logo_path': $!";
    # XXX change to use warnings::enabled when we break 5.005 compatibility
    carp "Problems reading $logo_path (tried: @tried)" unless $glogo;
    return $glogo;
}

# read in the logo, and paste it on the graph canvas

sub put_logo
{
    my $self = shift;
    return unless defined $self->{logo};

    my $glogo = $self->_read_logo_file() or return;

    my ($x, $y);
    my $r = $self->{logo_resize};

    my $r_margin = (defined $self->{r_margin_abs}) ? 
        $self->{r_margin_abs} : $self->{r_margin};
    my $b_margin = (defined $self->{b_margin_abs}) ? 
        $self->{b_margin_abs} : $self->{b_margin};

    my ($w, $h) = $glogo->getBounds;
    LOGO: for ($self->{logo_position}) {
        /UL/i and do {
            $x = $self->{l_margin};
            $y = $self->{t_margin};
            last LOGO;
        };
        /UR/i and do {
            $x = $self->{width} - $r_margin - $w * $r;
            $y = $self->{t_margin};
            last LOGO;
        };
        /LL/i and do {
            $x = $self->{l_margin};
            $y = $self->{height} - $b_margin - $h * $r;
            last LOGO;
        };
        # default "LR"
        $x = $self->{width} - $r_margin - $r * $w;
        $y = $self->{height} - $b_margin - $r * $h;
        last LOGO;
    }
    $self->{graph}->copyResized($glogo, 
        $x, $y, 0, 0, $r * $w, $r * $h, $w, $h);
}

# Set a colour to work with on the canvas, by rgb value. 
# Return the colour index in the palette

sub set_clr # GD::Image, r, g, b
{
    my $self = shift; 
    return unless @_;
    my $gd = $self->{graph};

    # All of this could potentially be done by using colorResolve
    # The problem is that colorResolve doesn't return an error
    # condition (-1) if it can't allocate a color. Instead it always
    # returns 0.

    # Check if this colour already exists on the canvas
    my $i = $gd->colorExact(@_);
    # if not, allocate a new one, and return its index
    $i = $gd->colorAllocate(@_) if $i < 0;
    # if this fails, we should use colorClosest.
    $i = $gd->colorClosest(@_)  if $i < 0;

    # TODO Deal with antialiasing here?
    if (0 && $self->can("setAntiAliased"))
    {
        $self->setAntiAliased($i);
        eval "$i = gdAntiAliased";
    }

    return $i;
}

# Set a temporary colour that can be used with fillToBorder
sub _set_tmp_clr
{
    my $self = shift; 
    # XXX Error checks!
    $self->{graph}->colorAllocate(0,0,0);
}

# Remove the temporary colour
sub _rm_tmp_clr
{
    my $self = shift; 
    return unless @_;
    # XXX Error checks?
    $self->{graph}->colorDeallocate(shift);
}

# Set a colour, disregarding wether or not it already exists. This may
# be necessary where one wants the same colour to have a different
# index, as in pie slices of the same color as the edge.
# Note that this could be cleaned up after needed, but we won't do that.

sub set_clr_uniq # GD::Image, r, g, b
{
    my $self = shift; 
    return unless @_;
    $self->{graph}->colorAllocate(@_); 
}

# Return an array of rgb values for a colour number

sub pick_data_clr # number
{
    my $self = shift;
    _rgb($self->{dclrs}[$_[0] % @{$self->{dclrs}} - 1]);
}

# contrib "Bremford, Mike" <mike.bremford@gs.com>
sub pick_border_clr # number
{
    my $self = shift;

    ref $self->{borderclrs} ?
        _rgb($self->{borderclrs}[$_[0] % @{$self->{borderclrs}} - 1]) :
        _rgb($self->{accentclr});
}

sub gd 
{
    my $self = shift;
    return $self->{graph};
}

sub export_format
{
    my $proto = shift;
    my @f = grep { GD::Image->can($_) && 
                   do { 
                    my $g = GD::Image->new(5,5);
                    $g->colorAllocate(0,0,0);
                    $g->$_() 
                   };
            } qw(gif png jpeg xbm xpm gd gd2);
    wantarray ? @f : $f[0];
}

# The following method is undocumented, and will not be supported as
# part of the interface. There isn't really much reason to do so.
sub import_format
{
    my $proto = shift;
    # xpm now included despite bugginess--should document the problem, though
    my @f = grep { GD::Image->can("newFrom\u$_") }
        qw(gif png jpeg xbm xpm gd gd2);
    wantarray ? @f : $f[0];
}

sub can_do_ttf
{
    my $proto = shift;
    return GD::Text->can_do_ttf;
}

# DEBUGGING
# data_dump obsolete now, use Data::Dumper

sub die_abstract
{
    my $self = shift;
    my $msg = shift;
    # ABSTRACT
    confess
        "Subclass (" .
        ref($self) . 
        ") not implemented correctly: " .
        (defined($msg) ? $msg : "unknown error");
}

"Just another true value";

__END__

=head1 NAME

GD::Graph - Graph Plotting Module for Perl 5

=head1 SYNOPSIS

use GD::Graph::moduleName;

=head1 DESCRIPTION

B<GD::Graph> is a I<perl5> module to create charts using the GD module.
The following classes for graphs with axes are defined:

=over 4

=item C<GD::Graph::lines>

Create a line chart.

=item C<GD::Graph::bars> and C<GD::Graph::hbars>

Create a bar chart with vertical or horizontal bars.

=item C<GD::Graph::points>

Create an chart, displaying the data as points.

=item C<GD::Graph::linespoints>

Combination of lines and points.

=item C<GD::Graph::area>

Create a graph, representing the data as areas under a line.

=item C<GD::Graph::mixed>

Create a mixed type graph, any combination of the above. At the moment
this is fairly limited. Some of the options that can be used with some
of the individual graph types won't work very well. Bar graphs drawn 
after lines or points graphs may obscure the earlier data, and 
specifying bar_width will not produce the results you probably expected.

=back

Additional types:

=over 4

=item C<GD::Graph::pie>

Create a pie chart.

=back

=head1 DISTRIBUTION STATUS

Distribution has no releases since 2007. It has new maintainer starting
of 1.45 and my plan is to keep modules backwards compatible as much as
possible, fix bugs with test cases, apply patches and release new versions
to the CPAN.

I got repository from Martien without Benjamin's work, Benjamin couldn't
find his repository, so everything else is imported from CPAN and BackPAN.
Now it's all on github L<https://github.com/ruz/GDGraph>. May be at some
point Benjamin will find his VCS backup and we can restore full history.

Release 1.44_01 (development release) was released in 2007 by Benjamin,
but never made into production version. This dev version contains very
nice changes (truecolor, anti-aliasing and alpha support), but due to
nature of how GD and GD::Graph works authors had to add third optional
argument (truecolor) to all constructors in GD::Graph modules. I think
that this should be and can be adjusted to receive named arguments in
constructor and still be backwards compatible. If you were using that
dev release and want to fast forward inclusion of this work into production
release then contact ruz@cpan.org

Martien also has changes in his repository that were never published
to CPAN. These are smaller and well isolated, so I can merge them faster.

My goal at this moment is to merge existing versions together, get rid
of CVS reminders, do some repo cleanup, review existing tickets on
rt.cpan.org. Join if you want to help.

=head1 EXAMPLES

See the samples directory in the distribution, and read the Makefile
there.

=head1 USAGE

Fill an array of arrays with the x values and the values of the data
sets.  Make sure that every array is the same size, otherwise
I<GD::Graph> will complain and refuse to compile the graph.

  @data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
    [ sort { $a <=> $b } (1, 2, 5, 6, 3, 1.5, 1, 3, 4) ]
  );

If you don't have a value for a point in a certain dataset, you can
use B<undef>, and the point will be skipped.

Create a new I<GD::Graph> object by calling the I<new> method on the
graph type you want to create (I<chart> is I<bars>, I<hbars>,
I<lines>, I<points>, I<linespoints>, I<mixed> or I<pie>).

  my $graph = GD::Graph::chart->new(400, 300);

Set the graph options. 

  $graph->set( 
      x_label           => 'X Label',
      y_label           => 'Y label',
      title             => 'Some simple graph',
      y_max_value       => 8,
      y_tick_number     => 8,
      y_label_skip      => 2 
  ) or die $graph->error;

and plot the graph.

  my $gd = $graph->plot(\@data) or die $graph->error;

Then do whatever your current version of GD allows you to do to save the
file. For versions of GD older than 1.19 (or more recent than 2.15),
you'd do something like:

  open(IMG, '>file.gif') or die $!;
  binmode IMG;
  print IMG $gd->gif;
  close IMG;

and for newer versions (1.20 and up) you'd write

  open(IMG, '>file.png') or die $!;
  binmode IMG;
  print IMG $gd->png;

or

  open(IMG, '>file.gd2') or die $!;
  binmode IMG;
  print IMG $gd->gd2;

Then there's also of course the possibility of using a shorter
version (for each of the export functions that GD supports):

  print IMG $graph->plot(\@data)->gif;
  print IMG $graph->plot(\@data)->png;
  print IMG $graph->plot(\@data)->gd;
  print IMG $graph->plot(\@data)->gd2;

If you want to write something that doesn't require your code to 'know'
whether to use gif or png, you could do something like:

  if ($gd->can('png')) { # blabla }

or you can use the convenience method C<export_format>:

  my $format = $graph->export_format;
  open(IMG, ">file.$format") or die $!;
  binmode IMG;
  print IMG $graph->plot(\@data)->$format();
  close IMG;

or for CGI programs:

  use CGI qw(:standard);
  #...
  my $format = $graph->export_format;
  print header("image/$format");
  binmode STDOUT;
  print $graph->plot(\@data)->$format();

(the parentheses after $format are necessary, to help the compiler
decide that you mean a method name there)

See under L<"SEE ALSO"> for references to other documentation,
especially the FAQ.

=head1 METHODS

=head2 Methods for all graphs

=over 4

=item GD::Graph::chart-E<gt>new([width,height])

Create a new object $graph with optional width and height. 
Default width = 400, default height = 300. I<chart> is either
I<bars>, I<lines>, I<points>, I<linespoints>, I<area>, I<mixed> or
I<pie>.

=item $graph-E<gt>set_text_clr(I<colour name>)

Set the colour of the text. This will set the colour of the titles,
labels, and axis labels to I<colour name>. Also see the options
I<textclr>, I<labelclr> and I<axislabelclr>.

=item $graph-E<gt>set_title_font(font specification)

Set the font that will be used for the title of the chart.
See L<"FONTS">.

=item $graph-E<gt>plot(I<\@data>)

Plot the chart, and return the GD::Image object.

=item $graph-E<gt>set(attrib1 =E<gt> value1, attrib2 =E<gt> value2 ...)

Set chart options. See OPTIONS section.

=item $graph-E<gt>get(attrib1, attrib2)

Returns a list of the values of the attributes. In scalar context
returns the value of the first attribute only.

=item $graph-E<gt>gd()

Get the GD::Image object that is going to be used to draw on. You can do
this either before or after calling the plot method, to do your own
drawing.

B<Note:> as of the current version, this GD::Image object will always 
be palette-based, even if the installed version of GD supports
true-color images.

Note also that if you draw on the GD::Image object before calling the plot
method, you are responsible for making sure that the background
colour is correct and for setting transparency.

=item $graph-E<gt>export_format()

Query the export format of the GD library in use.  In scalar context, it
returns 'gif', 'png' or undefined, which is sufficient for most people's
use. In a list context, it returns a list of all the formats that are
supported by the current version of GD. It can be called as a class or
object method

=item $graph-E<gt>can_do_ttf()

Returns true if the current GD library supports TrueType fonts, False
otherwise. Can also be called as a class method or static method.

=back



=head2 Methods for Pie charts

=over 4

=item $graph-E<gt>set_label_font(font specification)

=item $graph-E<gt>set_value_font(font specification)

Set the font that will be used for the label of the pie or the 
values on the pie.
See L<"FONTS">.

=back


=head2 Methods for charts with axes.

=over 4

=item $graph-E<gt>set_x_label_font(font specification)

=item $graph-E<gt>set_y_label_font(font specification)

=item $graph-E<gt>set_x_axis_font(font specification)

=item $graph-E<gt>set_y_axis_font(font specification)

=item $graph-E<gt>set_values_font(font specification)

Set the font for the x and y axis label, the x and y axis
value labels, and for the values printed above the data points.
See L<"FONTS">.

=item $graph-E<gt>get_hotspot($dataset, $point)

B<Experimental>:
Return a coordinate specification for a point in a dataset. Returns a
list. If the point is not specified, returns a list of array references
for all points in the dataset. If the dataset is also not specified,
returns a list of array references for each data set. 
See L<"HOTSPOTS">.

=item $graph-E<gt>get_feature_coordinates($feature_name)

B<Experimental>:
Return a coordinate specification for a certain feature in the chart.
Currently, features that are defined are I<axes>, the coordinates of
the rectangle within the axes; I<x_label>, I<y1_label> and
I<y2_label>, the labels printed along the axes, with I<y_label>
provided as an alias for I<y1_label>; and I<title> which is the title
text box.
See L<"HOTSPOTS">.

=back


=head1 OPTIONS

=head2 Options for all graphs

=over 4

=item width, height

The width and height of the canvas in pixels
Default: 400 x 300.
B<NB> At the moment, these are read-only options. If you want to set
the size of a graph, you will have to do that with the I<new> method.

=item t_margin, b_margin, l_margin, r_margin

Top, bottom, left and right margin of the canvas. These margins will be
left blank.
Default: 0 for all.

=item logo

Name of a logo file. Generally, this should be the same format as your
version of GD exports images in.  Currently, this file may be in any 
format that GD can import, but please see L<GD> if you use an
XPM file and get unexpected results.

Default: no logo.

=item logo_resize, logo_position

Factor to resize the logo by, and the position on the canvas of the
logo. Possible values for logo_position are 'LL', 'LR', 'UL', and
'UR'.  (lower and upper left and right). 
Default: 'LR'.

=item transparent

If set to a true value, the produced image will have the background
colour marked as transparent (see also option I<bgclr>).  Default: 1.

=item interlaced

If set to a true value, the produced image will be interlaced.
Default: 1.

B<Note>: versions of GD higher than 2.0 (that is, since GIF support
was restored after being removed owing to patent issues) do not support
interlacing of GIF images.  Support for interlaced PNG and progressive
JPEG images remains available using this option.

=back

=head2 Colours

=over 4

=item bgclr, fgclr, boxclr, accentclr, shadowclr

Drawing colours used for the chart: background, foreground (axes and
grid), axis box fill colour, accents (bar, area and pie outlines), and
shadow (currently only for bars).

All colours should have a valid value as described in L<"COLOURS">,
except boxclr, which can be undefined, in which case the box will not be
filled. 

=item shadow_depth

Depth of a shadow, positive for right/down shadow, negative for left/up
shadow, 0 for no shadow (default).
Also see the C<shadowclr> and C<bar_spacing> options.

=item labelclr, axislabelclr, legendclr, valuesclr, textclr

Text Colours used for the chart: label (labels for the axes or pie),
axis label (misnomer: values printed along the axes, or on a pie slice),
legend text, shown values text, and all other text.

All colours should have a valid value as described in L<"COLOURS">.

=item dclrs (short for datacolours)

This controls the colours for the bars, lines, markers, or pie slices.
This should be a reference to an array of colour names as defined in
L<GD::Graph::colour> (S<C<perldoc GD::Graph::colour>> for the names available).

    $graph->set( dclrs => [ qw(green pink blue cyan) ] );

The first (fifth, ninth) data set will be green, the next pink, etc.

A colour can be C<undef>, in which case the data set will not be drawn.
This can be useful for cumulative bar sets where you want certain data
series (often the first one) not to show up, which can be used to
emulate error bars (see examples 1-7 and 6-3 in the distribution).

Default: [ qw(lred lgreen lblue lyellow lpurple cyan lorange) ] 

=item borderclrs

This controls the colours of the borders of the bars data sets. Like
dclrs, it is a reference to an array of colour names as defined in
L<GD::Graph::colour>.
Setting a border colour to C<undef> means the border will not be drawn.

=item cycle_clrs

If set to a true value, bars will not have a colour from C<dclrs> per
dataset, but per point. The colour sequence will be identical for each
dataset. Note that this may have a weird effect if you are drawing more
than one data set. If this is set to a value larger than 1 the border
colour of the bars will cycle through the colours in C<borderclrs>.

=item accent_treshold

Not really a colour, but it does control a visual aspect: Accents on
bars are only drawn when the width of a bar is larger than this number
of pixels. Accents inside areas are only drawn when the horizontal
distance between points is larger than this number.
Default 4

=back

=head2 Options for graphs with axes.

options for I<bars>, I<lines>, I<points>, I<linespoints>, I<mixed> and 
I<area> charts.

=over 4

=item x_label, y_label

The labels to be printed next to, or just below, the axes. Note that if
you use the two_axes option that you need to use y1_label and y2_label.

=item long_ticks, tick_length

If I<long_ticks> is a true value, ticks will be drawn the same length
as the axes.  Otherwise ticks will be drawn with length
I<tick_length>. if I<tick_length> is negative, the ticks will be drawn
outside the axes.  Default: long_ticks = 0, tick_length = 4.

These attributes can also be set for x and y axes separately with
x_long_ticks, y_long_ticks, x_tick_length and y_tick_length.

=item x_ticks

If I<x_ticks> is a true value, ticks will be drawn for the x axis.
These ticks are subject to the values of I<long_ticks> and
I<tick_length>.  Default: 1.

=item y_tick_number

Number of ticks to print for the Y axis. Use this, together with
I<y_label_skip> to control the look of ticks on the y axis.
Default: 5.

=item y_number_format

This can be either a string, or a reference to a subroutine. If it is
a string, it will be taken to be the first argument to a sprintf,
with the value as the second argument:

    $label = sprintf( $s->{y_number_format}, $value );

If it is a code reference, it will be executed with the value as the
argument:

    $label = &{$s->{y_number_format}}($value);

This can be useful, for example, if you want to reformat your values
in currency, with the - sign in the right spot. Something like:

    sub y_format
    {
        my $value = shift;
        my $ret;

        if ($value >= 0)
        {
            $ret = sprintf("\$%d", $value * $refit);
        }
        else
        {
            $ret = sprintf("-\$%d", abs($value) * $refit);
        }

        return $ret;
    }

    $graph->set( 'y_number_format' => \&y_format );

(Yes, I know this can be much shorter and more concise)

Default: undef.

=item y1_number_format, y2_number_format

As with I<y_number_format>, these can be either a string, or a reference
to a subroutine. These are used as formats for graphs with
two y-axis scales so that independent formats can be used.

For compatibility purposes, each of these will fall back on 
I<y_number_format> if not specified.

Default: undef for both.

=item x_label_skip, y_label_skip

Print every I<x_label_skip>th number under the tick on the x axis, and
every I<y_label_skip>th number next to the tick on the y axis.
Default: 1 for both.

=item x_last_label_skip

By default, when I<x_label_skip> is set to something higher than 1, the last
label on the axis will be printed, even when it doesn't belong to the
normal series that should be printed. Setting this to a true value
prevents that.

For example, when your X values are the months of the year (i.e. Jan -
Dec), and you set I<x_label_skip> to 3, the months printed on the axis
will be Jan, Apr, Jul, Oct and Dec; even though Dec does not really
belong to that sequence. If you do not like the last month to be
printed, set I<x_last_label_skip> to a true value.

This option has no effect in other circumstances. Also see
I<x_tick_offset> for another method to make this look better.
Default: 0 for both

=item x_tick_offset

When I<x_label_skip> is used, this will skip the first I<x_tick_offset>
values in the labels before starting to print. Let me give an example.
If you have a series of X labels like

  qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

and you set I<x_label_skip> to 3, you will see ticks on the X axis for Jan,
Apr, Jul, Oct and Dec. This is not always what is wanted. If you set
I<x_tick_offset> to 1, you get Feb, May, Aug, Nov and Dec, and if you set
it to 2, you get Mar, Jun Sep and Dec, and this last one definitely
looks better. A combination of 6 and 5 also works nice for months. 

Note that the value for I<x_tick_offset> is periodical. This means that it
will have the same effect for each integer n in I<x_tick_offset> + n *
I<x_label_skip>.

Also see I<x_last_label_skip> for another method to influence this.

=item x_all_ticks

Force a print of all the x ticks, even if x_label_skip is set to a value
Default: 0.

=item x_label_position

Controls the position of the X axis label (title). The value for this
should be between 0 and 1, where 0 means aligned to the left, 1 means
aligned to the right, and 1/2 means centered. 
Default: 3/4

=item y_label_position

Controls the position of both Y axis labels (titles). The value for
this should be between 0 and 1, where 0 means aligned to the bottom, 1
means aligned to the top, and 1/2 means centered. 
Default: 1/2

=item x_labels_vertical

If set to a true value, the X axis labels will be printed vertically.
This can be handy in case these labels get very long.
Default: 0.

=item x_plot_values, y_plot_values

If set to a true value, the values of the ticks on the x or y axes
will be plotted next to the tick. Also see I<x_label_skip,
y_label_skip>.  Default: 1 for both.

=item box_axis

Draw the axes as a box, if true.
Default: 1.

=item no_axes

Draw no axes at all. If this is set to undef, all axes are drawn. If
it is set to 0, the zero axis will be drawn, I<for bar charts only>.
If this is set to a true value, no axes will be drawn at all. Value
labels on the axes and ticks will also not be drawn, but axis lables
are drawn.
Default: undef.

=item two_axes

Use two separate axes for the first and second data set. The first
data set will be set against the left axis, the second against the
right axis.  If more than two data sets are being plotted, the use_axis
option should be used to specify which data sets use which axis.

Note that if you use this option, that you need to use y1_label and
y2_label, instead of just y_label, if you want the two axes to have
different labels. The same goes for some other options starting with the
letter 'y' and an underscore.

Default: 0.

=item use_axis

If two y-axes are in use and more than two datasets are specified, set
this option to an array reference containing a value of 1 or 2 (for
the left and right scales respectively) for each dataset being plotted.
That is, to plot three datasets with the second on a different scale than
the first and third, set this to C<[1,2,1]>.

Default: [1,2].

=item zero_axis

If set to a true value, the axis for y values of 0 will always be
drawn. This might be useful in case your graph contains negative
values, but you want it to be clear where the zero value is. (see also
I<zero_axis_only> and I<box_axes>).
Default: 0.

=item zero_axis_only

If set to a true value, the zero axis will be drawn (see
I<zero_axis>), and no axis at the bottom of the graph will be drawn.
The labels for X values will be placed on the zero axis.
Default: 0.

=item y_max_value, y_min_value

Maximum and minimum value displayed on the y axis.

The range (y_min_value..y_max_value) has to include all the values of
the data points, or I<GD::Graph> will die with a message.

For bar and area graphs, the range (y_min_value..y_max_value) has to
include 0. If it doesn't, the values will be adapted before attempting
to draw the graph.

Default: Computed from data sets.

=item y1_max_value, y1_min_value, y2_max_value, y2_min_value

Maximum and minimum values for left (y1) and right (y2) axes when
B<two_axes> is a true value. Take precedence over y_min_value
and y_max_value.

By default 0 of the left axis is aligned with 0 of the right axis,
it's not true if any of these options is defined.

Otherwise behaviour and default values are as with y_max_value and y_min_value.

=item y_min_range, y1_min_range, y2_min_range

Minimal range between min and max values on y axis that is used to adjust
computed y_min_value and y_max_value.

B<NOTE> that author of the feature implemented this for two_axes case only,
patches are wellcome to expand over one y axis.

If two_axes is a true value, then y1_min_range and y2_min_range take
precedence over y_min_range value.

Default: undef

=item axis_space

This space will be left blank between the axes and the tick value text.
Default: 4.

=item text_space

This space will be left open between text elements and the graph (text
elements are title and axis labels.

Default: 8.

=item cumulate

If this attribute is set to a true value, the data sets will be
cumulated. This means that they will be stacked on top of each other. A
side effect of this is that C<overwrite> will be set to a true value.

Notes: This only works for bar and area charts at the moment.

If you have negative values in your data sets, setting this option might
produce odd results. Of course, the graph itself would be quite
meaningless.

=item overwrite

If set to 0, bars of different data sets will be drawn next to each
other. If set to 1, they will be drawn in front of each other.
Default: 0.

Note: Setting overwrite to 2 to produce cumulative sets is deprecated,
and may disappear in future versions of GD::Graph.
Instead see the C<cumulate> attribute.

=item correct_width

If this is set to a true value and C<x_tick_number> is false, then the
width of the graph (or the height for rotated graphs like
C<GD::Graph::hbar>) will be recalculated to make sure that each data
point is exactly an integer number of pixels wide. You probably never
want to fiddle with this.

When this value is true, you will need to make sure that the number of
data points is smaller than the number of pixels in the plotting area of
the chart. If you get errors saying that your horizontal size if too
small, you may need to manually switch this off, or consider using
something else than a bar type for your chart.

Default: 1 for bar, calculated at runtime for mixed charts, 0 for others.

=back

=head2 Plotting data point values with the data point

Sometimes you will want to plot the value of a data point or bar above
the data point for clarity. GD::Graph allows you to control this in a
generic manner, or even down to the single point.

=over 4

=item show_values

Set this to 1 to display the value of each data point above the point or
bar itself. No effort is being made to ensure that there is enough space
for the text.

Set this to a GD::Graph::Data object, or an array reference of the same
shape, with the same dimensions as your data object that you pass in to
the plot method. The reason for this option is that it allows you to
make a copy of your data set, and selectively set points to C<undef> to
disable plotting of them.

  my $data = GD::Graph::Data->new( 
    [ [ 'A', 'B', 'C' ], [ 1, 2, 3 ], [ 11, 12, 13 ] ]);
  my $values = $data->copy;
  $values->set_y(1, 1, undef);
  $values->set_y(2, 0, undef);

  $graph->set(show_values => $values);
  $graph->plot($data);

Default: 0.

=item values_vertical

If set to a true value, the values will be printed vertically, instead
of horizontally. This can be handy if the values are long numbers.
Default: 0.

=item values_space

Space to insert between the data point and the value to print.
Default: 4.

=item values_format

How to format the values for display. See y_number_format for more
information.
Default: undef.

=item hide_overlapping_values

If set to a true value, the values that goes out of graph space are hidden.
Option is B<EXPERIMENTAL>, works only for bars, text still can overlap with
other bars and labels, most useful only with text in the same direction as
bars.
Default: undef

=back

=head2 Options for graphs with a numerical X axis

First of all: GD::Graph does B<not> support numerical x axis the way it
should. Data for X axes should be equally spaced. That understood:
There is some support to make the printing of graphs with numerical X
axis values a bit better, thanks to Scott Prahl. If the option
C<x_tick_number> is set to a defined value, GD::Graph will attempt to
treat the X data as numerical.

Extra options are:

=over 4

=item x_tick_number

If set to I<'auto'>, GD::Graph will attempt to format the X axis in a
nice way, based on the actual X values. If set to a number, that's the
number of ticks you will get. If set to undef, GD::Graph will treat X
data as labels.
Default: undef.

=item x_min_value, x_max_value

The minimum and maximum value to use for the X axis.
Default: computed.

=item x_min_range

Minimal range of x axis.

Default: undef

=item x_number_format

See y_number_format

=item x_label_skip

See y_label_skip

=back


=head2 Options for graphs with bars

=over 4

=item bar_width

The width of a bar in pixels. Also see C<bar_spacing>.  Use C<bar_width>
If you want to have fixed-width bars, no matter how wide the chart gets.
Default: as wide as possible, within the constraints of the chart size
and C<bar_spacing> setting.

=item bar_spacing

Number of pixels to leave open between bars. This works well in most
cases, but on some platforms, a value of 1 will be rounded off to 0.
Use C<bar_spacing> to get a fixed amount of space between bars, with
variable bar widths, depending on the width of the chart.  Note that if
C<bar_width> is also set, this setting will be ignored, and
automatically calculated.  Default: 0

=item bargroup_spacing

Number of pixels (in addition to whatever is specified in C<bar_spacing>)
to leave between groups of bars when multiple datasets are being displayed.
Unlike C<bar_spacing>, however, this parameter will hold its value if
C<bar_width> is set.

=back

=head2 Options for graphs with lines

=over 4

=item line_types

Which line types to use for I<lines> and I<linespoints> graphs. This
should be a reference to an array of numbers:

    $graph->set( line_types => [3, 2, 4] );

Available line types are 1: solid, 2: dashed, 3: dotted, 4:
dot-dashed.

Default: [1] (always use solid)

=item line_type_scale

Controls the length of the dashes in the line types. default: 6.

=item line_width

The width of the line used in I<lines> and I<linespoints> graphs, in pixels.
Default: 1.

=item skip_undef

For all other axes graph types, the default behaviour is (by their
nature) to not draw a point when the Y value is C<undef>. For line
charts the point gets skipped as well, but the line is drawn between the
points n-1 to n+1 directly. If C<skip_undef> has a true value, there
will be a gap in the chart where a Y value is undefined.

Note that a line will not be drawn unless there are I<at least two>
consecutive data points exist that have a defined value. The following
data set will only plot a very short line towards the end if
C<skip_undef> is set:

  @data = (
    [ qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct ) ],
    [ 1, undef, 2, undef, 3, undef, 4, undef, 5, 6 ]
  );

This option is useful when you have a consecutive gap in your data, or
with linespoints charts. If you have data where you have intermittent
gaps, be careful when you use this.
Default value: 0

=back

=head2 Options for graphs with points

=over 4

=item markers

This controls the order of markers in I<points> and I<linespoints>
graphs.  This should be a reference to an array of numbers:

    $graph->set( markers => [3, 5, 6] );

Available markers are: 1: filled square, 2: open square, 3: horizontal
cross, 4: diagonal cross, 5: filled diamond, 6: open diamond, 7:
filled circle, 8: open circle, 9: horizontal line, 10: vertical line.
Note that the last two are not part of the default list.

Default: [1,2,3,4,5,6,7,8]

=item marker_size

The size of the markers used in I<points> and I<linespoints> graphs,
in pixels.  Default: 4.

=back

=head2 Options for mixed graphs

=over 4

=item types

A reference to an array with graph types, in the same order as the
data sets. Possible values are:

  $graph->set( types => [qw(lines bars points area linespoints)] );
  $graph->set( types => ['lines', undef, undef, 'bars'] );

values that are undefined or unknown will be set to C<default_type>.

Default: all set to C<default_type>

=item default_type

The type of graph to draw for data sets that either have no type set,
or that have an unknown type set.

Default: lines

=back

=head2 Graph legends (axestype graphs only)

At the moment legend support is minimal.

B<Methods>

=over 4

=item $graph-E<gt>set_legend(I<@legend_keys>);

Sets the keys for the legend. The elements of @legend_keys correspond
to the data sets as provided to I<plot()>.

If a key is I<undef> or an empty string, the legend entry will be skipped.

=item $graph-E<gt>set_legend_font(I<font name>);

Sets the font for the legend text (see L<"FONTS">).
Default: GD::gdTinyFont.

=back

B<Options>

=over 4

=item legend_placement

Where to put the legend. This should be a two letter key of the form:
'B[LCR]|R[TCB]'. The first letter indicates the placement (I<B>ottom or
I<R>ight), and the second letter the alignment (I<L>eft,
I<R>ight, I<C>enter, I<T>op, or I<B>ottom).
Default: 'BC'

If the legend is placed at the bottom, some calculations will be made
to ensure that there is some 'intelligent' wrapping going on. if the
legend is placed at the right, all entries will be placed below each
other.

=item legend_spacing

The number of pixels to place around a legend item, and between a
legend 'marker' and the text.
Default: 4

=item legend_marker_width, legend_marker_height

The width and height of a legend 'marker' in pixels.
Defaults: 12, 8

=item lg_cols

If you, for some reason, need to force the legend at the bottom to
have a specific number of columns, you can use this.
Default: computed

=back


=head2 Options for pie graphs

=over 4

=item 3d

If set to a true value, the pie chart will be drawn with a 3d look.
Default: 1.

=item pie_height

The thickness of the pie when I<3d> is true.
Default: 0.1 x height.

=item start_angle

The angle at which the first data slice will be displayed, with 0 degrees
being "6 o'clock".
Default: 0.

=item suppress_angle

If a pie slice is smaller than this angle (in degrees), a label will not
be drawn on it. Default: 0.

=item label

Print this label below the pie. Default: undef.

=back

=head1 COLOURS

All references to colours in the options for this module have been
shortened to clr. The main reason for this was that I didn't want to
support two spellings for the same word ('colour' and 'color')

Wherever a colour is required, a colour name should be used from the
package L<GD::Graph::colour>. S<C<perldoc GD::Graph::colour>> should give
you the documentation for that module, containing all valid colour
names. I will probably change this to read the systems rgb.txt file if 
it is available.

=head1 FONTS

Depending on your version of GD, this accepts both GD builtin fonts or
the name of a TrueType font file. In the case of a TrueType font, you
must specify the font size. See L<GD::Text> for more details and other
things, since all font handling in GD::Graph is delegated to there.

Examples:

    $graph->set_title_font('/fonts/arial.ttf', 18);
    $graph->set_legend_font(gdTinyFont);
    $graph->set_legend_font(
        ['verdana', 'arial', gdMediumBoldFont], 12)

(The above discussion is based on GD::Text 0.65. Older versions have
more restrictive behaviour).

=head1 HOTSPOTS

I<Note that this is an experimental feature, and its interface may, and
likely will, change in the future. It currently does not work for area
charts or pie charts.>

I<A known problem with hotspots for GD::Graph::hbars is that the x and y
coordinate come out transposed. This probably won't be fixed until the
redesign of this section>

GD::Graph keeps an internal set of coordinates for each data point and
for certain features of a chart, like the title and axis labels. This
specification is very similar to the HTML image map specification, and
in fact exists mainly for that purpose. You can get at these hotspots
with the C<get_hotspot> method for data point, and
C<get_feature_coordinates> for the chart features. 

The <get_hotspot> method accepts two optional arguments, the number of
the dataset you're interested in, and the number of the point in that
dataset you're interested in. When called with two arguments, the
method returns a list of one of the following forms:

  'rect', x1, y1, x2, y2
  'poly', x1, y1, x2, y2, x3, y3, ....
  'line', xs, ys, xe, ye, width

The parameters for C<rect> are the coordinates of the corners of the
rectangle, the parameters for C<poly> are the coordinates of the
vertices of the polygon, and the parameters for the C<line> are the
coordinates for the start and end point, and the line width.  It should
be possible to almost directly translate these lists into HTML image map
specifications.

If the second argument to C<get_hotspot> is omitted, a list of
references to arrays will be returned. This list represents all the
points in the dataset specified, and each array referred to is of the
form outlined above.

  ['rect', x1, y1, x2, y2 ], ['rect', x1, y1, x2, y2], ...

if both arguments to C<get_hotspot> are omitted, the list that comes
back will contain references to arrays for each data set, which in
turn contain references to arrays for each point.

  [
    ['rect', x1, y1, x2, y2 ], ['rect', x1, y1, x2, y2], ...
  ],
  [
    ['line', xs, ys, xe, ye, w], ['line', xs, ys, xe, ye, w], ...
  ],...

The C<get_feature> method, when called with the name of a feature,
returns a single array reference with a type and coordinates as
described above. When called with no arguments, a hash reference is
returned with the keys being all the currently defined and set
features, and the values array references with the type and
coordinates for each of those features.

=head1 ERROR HANDLING

GD::Graph objects inherit from the GD::Graph::Error class (not the
other way around), so they behave in the same manner. The main feature
of that behaviour is that you have the error() method available to get
some information about what went wrong. The GD::Graph methods all
return undef if something went wrong, so you should be able to write
safe programs like this:

  my $graph = GD::Graph->new()    or die GD::Graph->error;
  $graph->set( %attributes )      or die $graph->error;
  $graph->plot($gdg_data)         or die $graph->error;

More advanced usage is possible, and there are some caveats with this
error handling, which are all explained in L<GD::Graph::Error>.

Unfortunately, it is almost impossible to gracefully recover from an
error in GD::Graph, so you really should get rid of the object, and
recreate it from scratch if you want to recover. For example, to
adjust the correct_width attribute if you get the error "Horizontal
size too small" or "Vertical size too small" (in the case of hbar),
you could do something like:

  sub plot_graph
  {
      my $data    = shift;
      my %attribs = @_;
      my $graph   = GD::Graph::bars->new()
         or die GD::Graph->error;
      $graph->set(%attribs)     or die $graph->error;
      $graph->plot($data)       or die $graph->error;
  }
  
  my $gd;
  eval { $gd = plot_graph(\@data, %attribs) };
  if ($@)
  {
      die $@ unless $@ =~ /size too small/;
      $gd = plot_graph(\@data, %attribs, correct_width => 0);
  }

Of course, you could also adjust the width this way, and you can check
for other errors.

=head1 NOTES

As with all Modules for Perl: Please stick to using the interface. If
you try to fiddle too much with knowledge of the internals of this
module, you could get burned. I may change them at any time.

=head1 BUGS

GD::Graph objects cannot be reused. To create a new plot, you have to
create a new GD::Graph object.

Rotated charts (ones with the X axis on the left) can currently only be
created for bars. With a little work, this will work for all others as
well. Please, be patient :)

Other outstanding bugs can (alas) probably be found in the RT queue for this
distribution, at http://rt.cpan.org/Public/Dist/Display.html?Name=GDGraph

If you think you have found a bug, please check first to see if it 
has already been reported.  If it has not, please do (you can use the 
web interface above or send e-mail to E<lt>bug-GDGraph@rt.cpan.orgE<gt>).  
Bug reports should contain as many as possible of the following:

=over 4

=item *

a concise description of the buggy behavior and how it differs from what you expected,

=item *

the versions of Perl, GD::Graph and GD that you are using,

=item *

a short demonstration script that shows the bug in action,

=item *

a patch that fixes it. :-)

=back

Of all of these, the third is probably the single most important, 
since producing a test case generally makes the explanation much more
concise and understandable, as well as making it much simpler to show 
that the bug has been fixed.  As an incidental benefit, if the bug is in
fact caused by some code outside of GD::Graph, it will become apparent
while you are writing the test case, thereby saving time and confusion
for all concerned.

=head1 AUTHOR

Martien Verbruggen E<lt>mgjv@tradingpost.com.auE<gt>

Current maintenance (including this release) by
Benjamin Warfield E<lt>bwarfield@cpan.orgE<gt>

=head2 Copyright

 GIFgraph: Copyright (c) 1995-1999 Martien Verbruggen.
 Chart::PNGgraph: Copyright (c) 1999 Steve Bonds.
 GD::Graph: Copyright (c) 1999 Martien Verbruggen.

All rights reserved. This package is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head2 Acknowledgements

Thanks to Steve Bonds for releasing Chart::PNGgraph, and keeping the
code alive when GD reached version 1.20, and I didn't have time to do
something about it.

Thanks to the following people for contributing code, or sending me
fixes:
Dave Belcher,
Steve Bonds,
Mike Bremford,
Damon Brodie,
Gary Deschaines,
brian d foy,
Edwin Hildebrand,
Ari Jolma,
Tim Meadowcroft,
Honza Pazdziora,
Scott Prahl,
Ben Tilly,
Vegard Vesterheim,
Jeremy Wadsack.

And some people whose real name I don't know, and whose email address
I'd rather not publicise without their consent.

=head1 SEE ALSO

L<GD::Graph::FAQ>, 
L<GD::Graph::Data>, 
L<GD::Graph::Error>,
L<GD::Graph::colour>

