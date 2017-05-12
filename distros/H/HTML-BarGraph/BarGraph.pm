package HTML::BarGraph;

use strict;

use Exporter;

use vars qw($VERSION @ISA @EXPORT);

$VERSION = 0.5;

@ISA = qw(Exporter);
@EXPORT = qw(graph);

###  general characteristics of the graphic, used by some subroutines
my ($maxidx, $maxval, $hlttype, $hlttab);

sub graph {
    my %args;
    if (scalar(@_) % 2 == 0) {  
        %args = @_;
    }
    elsif (ref $_[0] eq 'HASH') {
        %args = %{$_[0]};
    }
    else {
        warn "odd number of arguments\n"; 
        return;
    }

    check_args(\%args) or return;

    ($hlttype, $hlttab) = highlight(\%args);

    set_colors(\%args);

#use Data::Dumper;
#print Dumper(\%args);


    ###  output the HTML
    my $html;
    $html .= table_header(\%args);

    $html .= title_layer(\%args);

    $html .= spacing_layer(\%args) if $args{direction} eq 'h';



    $html .= ylabel(\%args) if $args{ylabel};

    ###  the graph layer
    if ($args{direction} eq 'v') { 
        $html .= graph_v(\%args);
    }
    elsif ($args{direction} eq 'h') { 
        $html .= graph_h_first(\%args); 
    }


    if ($args{direction} eq 'v') {
        $html .= axis_values_y(\%args) if $args{showaxistags};
    }
    elsif ($args{direction} eq 'h') {
        $html .= graph_h_rest(\%args);
    }



    $html .= spacing_layer(\%args) if $args{direction} eq 'h';

    $html .= xlabel(\%args) if $args{xlabel};

    $html .= table_footer(\%args);

    return $html;
}






sub check_args {
    my $args = shift;

    ###  required params
    unless (ref($args->{data}) eq 'ARRAY') {
        warn "value of 'data' has to be an arrayref\n";
        return;
    }
    if (exists($args->{tags}) and ref($args->{tags}) ne 'ARRAY') {
        warn "value of 'tags' has to be an arrayref\n";
        return;
    }


    ###  put the data in a format that can be used in the same way for
    ###  single and multiple data sets (ie a list of arrayrefs)
    if (ref($args->{data}->[0]) eq '') {
        my $tmp = $args->{data};
        $args->{data} = [ $tmp ];
    }

    my $datasets = scalar(@{$args->{data}});

    ###  get the max value for graf size
    foreach my $set (@{$args->{data}}) {
       foreach (@$set) {
           $maxval = $_ if $maxval < $_;
       }
       my $t = scalar(@$set);
       $maxidx = $t if $maxidx < $t;
    }
    unless ($maxidx) {
        warn "no non-null values in the data sets?\n";
        return;
    }
    $maxval ||= 1;   ###  to avoid division by zero below

    ###   check to have tags at least as longest data set
    if ($args->{tags} and scalar(@{$args->{tags}}) < $maxidx) {
        warn "the 'data' set has more elements than the 'tags' set\n";
        return;
    }

    ###  defaults
#    if ($args->{graphminsize} and $args->{barlength}) {
#        my $factor;
#        $factor = 1.5 if $args->{showaxistags} or  $args->{showvalues};
#        $factor = 2.0 if $args->{showaxistags} and $args->{showvalues};
#
#        $args->{graphminsize} = int($args->{barlength} * $factor)
#                  if $args->{graphminsize} < int($args->{barlength} * $factor);
#    }
    $args->{graphminsize} = undef if $args->{barlength};

    $args->{direction}    ||= 'h';
    $args->{bartype}      ||= 'html';
    $args->{baraspect}    ||= .05;
    $args->{barlength}    ||= 100;
    $args->{barwidth}     ||= int($args->{barlength} * $args->{baraspect}) || 1;
    $args->{fontface}     ||= 'TimesRoman';
    $args->{color}        ||= 'blue';
    $args->{highlightcolor} ||= 'red';
    $args->{pixelfmt}     ||= 'PNG';
    $args->{addalt}        = 1 unless exists($args->{addalt});
    $args->{showaxistags}  = 1 unless exists($args->{showaxistags});
    $args->{showvalues}    = 1 unless exists($args->{showvalues});
    $args->{setspacer}     = 1 unless exists($args->{setspacer});


    $args->{direction} = 'h' if $args->{direction} eq '-';
    $args->{direction} = 'v' if $args->{direction} eq '|';
    if ($args->{bordertype}) {
        if ($args->{bordertype} eq 'flat') {
            $args->{bordercolor}  ||= 'black';
            $args->{borderwidth}  ||= 3;
        }
        elsif ($args->{bordertype} eq 'reised') {
            $args->{borderwidth}  ||= 1;
        }
    }


    $args->{titlealign}  ||= 'center';
    $args->{xlabelalign} ||= 'center';
    $args->{ylabelalign} ||= 'middle';

    $args->{bgcolor}      ||= 'white';
    $args->{textcolor}    ||= 'black';
    $args->{titlecolor}   ||= $args->{textcolor};
    $args->{labelbgcolor} ||= $args->{bgcolor};



    ###  set some values that make sense only in some conditions
    $args->{showaxistags} = undef unless $args->{tags};
    $args->{highlighttag} = undef unless $datasets == 1 and $args->{tags};
    $args->{highlightpos} = undef unless $datasets == 1;
    $args->{setspacer}    = undef if $datasets == 1;
    $args->{colors}       = undef if exists($args->{colors}) and 
                                   ref($args->{colors}) ne 'ARRAY';
    $args->{valuesuffix}  = undef unless $args->{showvalues};
    $args->{valueprefix}  = undef unless $args->{showvalues};
    $args->{pixelfmt}     = undef if $args->{bartype} eq 'html';
    $args->{addalt}       = undef if $args->{bartype} eq 'html';

    1;
}


sub highlight {
    my $args = shift or return;

    $hlttype = 0;  ###  0 - none, 1 - tag based, 2 - position based highlight
    $hlttab = {};  ###  lookup table for tag- or position-based highlighting

    
    if ($args->{tags} and $args->{highlighttag}) {
        if (ref($args->{highlighttag}) eq 'ARRAY') { ### multi value highlight
            $hlttab = { map { ($_,1) } @{$args->{highlighttag}} };
            $hlttype = 1;
        }
        elsif (ref($args->{highlighttag}) eq '') {   ### single value highlight
            $hlttab->{$args->{highlighttag}}++;
            $hlttype = 1;
        }
    }
    
    unless (scalar keys %$hlttab) {   ###  check the other possibility
        if (ref($args->{highlightpos}) eq 'ARRAY') { ### multi value highlight
            $hlttab = { map { ($_,1) } @{$args->{highlightpos}} };
            $hlttype = 2;
        }
        elsif (ref($args->{highlightpos}) eq '') {   ### single value highlight
            $hlttab->{$args->{highlightpos}}++;
            $hlttype = 2;
        }
    }

    return ($hlttype, $hlttab);
}
    

sub is_highlighted {
    my ($args, $index) = @_;
    return unless defined $index;

    if ($hlttype == 1) {   ###  tag-based highlighting
        return $hlttab->{$args->{tags}->[$index]};
    }
    elsif ($hlttype == 2) {
        return $hlttab->{$index+1};
    }
}



sub set_colors {
    my $args = shift;

    my $datasets = scalar(@{$args->{data}});
    if ($datasets == 1) {
        $args->{colors} = [ $args->{color} ] unless $args->{colors};
    }
    else {
        my $colors = scalar(@{$args->{colors}});
        if (exists($args->{colors}) and $colors) {
            if ($colors < $datasets) {  ###  loop through the colors
                for (1 .. int($datasets/$colors)) {
                    push(@{$args->{colors}}, @{$args->{colors}});
                }
            }
        }
        else {
            $args->{colors} = [ ($args->{color}) x $datasets ];
        }
    }
}




sub table_header {
    my $args = shift or return;

    my $html = "\n<!--  GRAPH START -->\n";
    if ($args->{bordertype} eq 'flat') {
        $html .= <<"ENDOFHTML";
<table cellpadding="$args->{borderwidth}">
   <tr>
   <td bgcolor="$args->{bordercolor}">
ENDOFHTML
    }
    elsif ($args->{bordertype} eq 'reised') {
        $html .= <<"ENDOFHTML";
<table border="$args->{borderwidth}">
   <tr>
   <td>
ENDOFHTML
    }

    my $msz = "width=$args->{graphminsize} "
                       if $args->{direction} eq 'h' and $args->{graphminsize};

    $html .= "<table cellspacing=0 cellpadding=2 border=0 $msz" .
             "bgcolor=\"$args->{bgcolor}\">\n";

    return $html;
}



sub table_footer {
    my $args = shift or return;

    my $html = "</table>\n";

    if ($args->{bordertype}) {
        $html .= <<"ENDOFHTML";
   </td>
   </tr>
</table>
ENDOFHTML
    }

    $html .= "<!--  GRAPH END -->\n\n";

    return $html;
}


sub title_layer {
    my $args = shift or return;

    return unless $args->{title};

    my $html = "   <tr bgcolor=\"$args->{bgcolor}\">\n";
    $html .= "      <td bgcolor=\"$args->{bgcolor}\"></td>\n" if $args->{ylabel};
    my $colspan = $args->{direction} eq 'v' ? $maxidx+2 : 1;
    $colspan++ if $args->{showaxistags} and $args->{direction} eq 'h';
    $html .= <<"ENDOFHTML";
      <td align="$args->{titlealign}" colspan="$colspan">
          <font face="$args->{fontface}" color="$args->{titlecolor}" size="+1"><b><u>$args->{title}</u></b></font>
      </td>
   </tr>
ENDOFHTML

    return $html;
}


sub spacing_layer {
    my $args = shift or return;

    my $html .= "   <tr bgcolor=\"$args->{bgcolor}\">\n";
    $html .= "      <td></td>\n" if $args->{ylabel};
    $html .= "      <td></td>\n" if $args->{showaxistags};
    $html .= "      <td></td>\n";
    $html .= "   </tr>\n";

    return $html;
}



sub ylabel {
    my $args = shift or return;

    my $rowspan = $args->{direction} eq 'h' ? $maxidx+1 : 1;
    my $ylabelhtml = join('&nbsp;<br>&nbsp;', split(//, $args->{ylabel}));

    my $html =<<"ENDOFHTML";
    <tr bgcolor="$args->{bgcolor}">
      <td bgcolor="$args->{labelbgcolor}" valign="$args->{ylabelalign}" align="center" rowspan="$rowspan">
         <font face="$args->{fontface}" color="$args->{labeltextcolor}"><b>
          &nbsp;$ylabelhtml&nbsp;
         </b></font>
      </td>
ENDOFHTML

    return $html;
}



sub xlabel {
    my $args = shift or return;

    my $colspan = $args->{direction} eq 'v' ? $maxidx+1 : 1;
    my $xlabelhtml = join('&nbsp;', split(//, $args->{xlabel}));

    my $html = qq|  <tr bgcolor="$args->{bgcolor}">\n|;
    $html .= qq|      <td></td>\n| if $args->{ylabel};
    $html .= qq|      <td></td>\n| if $args->{direction} eq 'v' or
                                     ($args->{direction} eq 'h' and
                                      $args->{showaxistags});
    $html .=<<"ENDOFHTML";
      <td bgcolor="$args->{labelbgcolor}" valign="middle" align="$args->{xlabelalign}" colspan="$colspan">
          <font face="$args->{fontface}" color="$args->{labeltextcolor}">
             <b>$xlabelhtml</b>
          </font>
      </td>
ENDOFHTML
    $html .= qq|    <td></td>\n| if $args->{direction} eq 'v';
    $html .= qq|  </tr>\n|;

    return $html;
}



sub axis_value_x {
    my ($args, $i) = @_;
    return unless defined $i;

    my $k = $args->{tags}->[$i];

    my $html =<<"ENDOFHTML";
      <td align="right" valign="middle">
        <font face="$args->{fontface}" color="$args->{textcolor}"> 
        $k 
        </font>
      </td>
ENDOFHTML

    return $html;
}


sub axis_values_y {
    my $args = shift or return;

    my $html;
    $html .= "   <tr bgcolor=\"$args->{bgcolor}\">\n";
    $html .= "      <td></td>\n" if $args->{ylabel};
    $html .= "      <td></td>\n";

    foreach my $i (0 .. $maxidx-1) {
        my $k = $args->{tags}->[$i];
        $html .=<<"ENDOFHTML";
      <td align="center" valign="middle">
         <font face="$args->{fontface}" color="$args->{textcolor}">$k</font>
      </td>
ENDOFHTML
    }

    $html .= "      <td></td>\n";

    return $html;
}



sub draw_bar {
    my ($x, $y, $color, $curval, $pixdir, $pixfmt, $addalt) = @_;

#    $color = 'transparent' unless $x and $y;
#    ###  draw a transparent bar of 1 pixel length
    $x ||= 1;  $y ||= 1;


    my $html;
    if ($pixfmt) {   ###  ie bartype is 'pixel'
        $pixfmt = lc($pixfmt);
       
        $html .= qq|        |;
#        $html .= qq|<a href="">| if $addalt;
        $html .= qq|<img src="$pixdir/$color.$pixfmt" width="$x" height="$y"|;
        $html .= qq| border=0 alt="$curval"| if $addalt;
        $html .= qq|>|;
#        $html .= qq|</a>| if $addalt;
        $html .= qq|\n|;
    }
    else {  ###  ie bartype is 'html'
        my $align = $x <= $y ? 'center' : 'left';
        my $tdalign = $x <= $y ? 'align="center" valign="bottom"' 
                              : 'align="left" valign="middle"';
        $html =<<"EOFHMTML";
             <table cellspacing=0 cellpadding=0 border=0 align="$align">
                <tr><td width="$x" height="$y" bgcolor="$color" $tdalign></td></tr>
             </table>&nbsp;
EOFHMTML
    }

    return $html;
}



sub field {
    my ($args, $v, $i, $j, $dir) = @_;

    return unless defined $v;

    my $vshow = join('', $args->{valueprefix}, $v, $args->{valuesuffix});

    my $color = is_highlighted($args, $i) ? $args->{highlightcolor} 
                                          : $args->{colors}->[$j];

    my ($align, $barx, $bary, $html);
    if ($dir eq 'v') {
        $align = 'align="center"';
        $barx = $args->{barwidth};
        $bary = int($args->{barlength} * ($v/$maxval));

        $html .=<<"ENDOFHTML" if $args->{showvalues};
        <font face="$args->{fontface}" color="$args->{textcolor}" size="-2">
        $vshow
        </font><br>
ENDOFHTML
        $html .= draw_bar($barx, $bary, $color, $v, 
                        $args->{pixeldir}, $args->{pixelfmt}, $args->{addalt});
    }
    else {
        $align = 'valign="middle"';
        $barx = int($args->{barlength} * ($v/$maxval));
        $bary = $args->{barwidth};

        $html .= draw_bar($barx, $bary, $color, $v, 
                        $args->{pixeldir}, $args->{pixelfmt}, $args->{addalt});
        $html .=<<"ENDOFHTML" if $args->{showvalues};
        <font face="$args->{fontface}" color="$args->{textcolor}" size="-2">
        $vshow
        </font>
ENDOFHTML
    }

    return "$html\n";
}



sub multiset_h {
    my ($args, $i) = @_;

    my $html = "        <td align=\"left\" valign=\"middle\">\n";

    my $j;
    foreach my $set (@{$args->{data}}) {
        $html .= field($args, $set->[$i], $i, $j++, 'h', $maxval) . "\n<br>\n";
    }

    $html .= "      </td>\n";

    return $html;
}


sub multiset_v {
    my ($args, $i) = @_;

    my $html; 
    my $j;
    foreach my $set (@{$args->{data}}) {
        $html .=<<"ENDOFHTML";
      <td align="center" valign="bottom" bgcolor="$args->{bgcolor}">
ENDOFHTML
        $html .= field($args, $set->[$i], $i, $j, 'v', $maxval);

        $html .=<<"ENDOFHTML";
      </td>
ENDOFHTML
        $j++;
    }

    return $html;
}



sub graph_h_first {
    my $args = shift or return;

    return graph_h($args, [ 0 ]);
}


sub graph_h_rest {
    my $args = shift or return;

    return graph_h($args, [ 1 .. $maxidx-1 ]);
}


sub graph_h {
    my ($args, $range) = @_;

    my $html;
    foreach my $i (@$range) {
        $html .= qq|   <tr bgcolor="$args->{bgcolor}">\n|;

        $html .= axis_value_x($args, $i) if $args->{showaxistags}; 

        ###  the values from multiple sets are represented as columns,
        ###  included in a table
        $html .= multiset_h($args, $i);

        $html .= qq|   </tr>\n|;

        $html .= qq|          <tr height=$args->{barwidth}></tr>\n| 
                if $args->{setspacer};
    }

    return $html;
}



sub graph_v {
    my $args = shift or return;

    ###  the spacing column for v
    my $html;
    $html .= "   <tr bgcolor=\"$args->{bgcolor}\">\n" unless $args->{ylabel};
    $html .= "      <td></td>\n";

    ###  the multiset graph v
    foreach my $i (0 .. $maxidx-1) {
        $html .=<<"ENDOFHTML";
      <td align="center" valign="bottom" bgcolor="$args->{bgcolor}">
        <table cellspacing=0 cellpadding=0 border=0 bgcolor="$args->{bgcolor}">
          <tr>
ENDOFHTML

        ###  the values from multiple sets are represented as columns,
        ###  included in a table
        $html .= multiset_v($args, $i);

        $html .= qq|          <td width=$args->{barwidth}></td>\n| 
                if $args->{setspacer};

        $html .=<<"ENDOFHTML";
          </tr>
        </table>
      </td>
ENDOFHTML
    }

    ###  the spacing column for v
    $html .= "      <td></td>\n";

    return $html;
}



1;

__END__

=head1 NAME

HTML::BarGraph - generate multiset bar graphs using plain HTML

=head1 SYNOPSIS

use HTML::BarGraph;

 print graph( 
             direction           => 'h',        ###  or 'v' or '|' / '-'
             graphminsize        => 250,
             bartype             => 'pixel',    ###  or 'html'
             barlength           => 100,
             barwidth            => 10 ,
             baraspect           => .03,
             color               => 'blue',
             colors              => [ 'blue', 'red', 'lightblue' ],
             pixeldir            => '/images',
             pixelfmt            => 'PNG',
             data                => [ 
                                      [ val11, val12, ... ],
                                      [ val21, val22, ... ],
                                    ],
             tags                =>   [  one,  two, ...   ],
             setspacer           => 0,
             highlighttag        => [ tag1... ], ###  or tag1 (one value)
                # OR
             highlightpos        => [ 5, ...],   ###  or 5 (one value)
             highlightcolor      => 'red',
             addalt              => 1,
             showaxistags        => 1,
             showvalues          => 1,
             valuesuffix         => '%',
             valueprefix         => '=> ',
             bordertype          => 'flat',     ### or 'reised' 
             bordercolor         => '#333333',  ### or '#RRGGBB'
             borderwidth         => 1,
             bgcolor             => 'bisque',   ### or '#RRGGBB'
             textcolor           => 'black',    ### or '#RRGGBB'
             title               => 'title',
             titlecolor          => 'black',    ### or '#RRGGBB'
             titlealign          => 'center',   ### or 'left' or 'right'
             fontface            => 'sansserif',
             ylabel              => 'randoms',
             ylabelalign         => 'middle',   ### or 'top' or 'bottom'
             xlabel              => 'index',
             xlabelalign         => 'center',   ### or 'left' or 'right'
             labeltextcolor      => 'yellow',
             labelbgcolor        => 'black',
           );

=head1 DESCRIPTION

C<HTML::BarGraph> is a module that creates graphics for one or more datasets, 
using plain HTML and, optionally, one-pixel images, which are stretched using 
the C<width> and C<height> attributes of the HTML C<img> tag.

Multiple customization options are provided, such as the maximum bar length,
bar colors etc.

The main subroutine, C<graph()>, returns the HTML code for a graphic, and it
accepts the following paramaters to define the graphic to be drawn:

=over 4

=item direction

Default: C<h>.  This arg indicates the orientation of the graphic bars (horizontal,
h or -, or vertical, v or |).

=item graphminsize

Optional arg to specify the minimum size of the graph in the direction of bar 
length;  this can be used to get a consistent size when multiple graphics are 
displayed.

=item bartype

Default: C<html>.  This arg indicates whether the color bars should be build
as HTML tables with a certain C<width>, C<height> and C<bgcolor>, or out of a 
pixel image (value C<pixel>) "stretched" with the C<width> and C<hight> 
attributes of C<img> tag.

=item barlength

Default: C<100>.  This arg indicates the length of the bar (in pixels) for the
maximum value to be represented in the graphic.

=item barwidth

This arg indicates the width of a graphic's bar.  If this arg is missing, it is
calculated based on C<barlength> and C<baraspect> (using their default values 
if they are missing too).

=item baraspect

Default: C<0.5>.  This arg indicates the aspect between the graphic bar's width
and length.  If both C<barwidth> and C<baraspect> are set, C<barwidth> is used.

=item color

Default: C<blue>.  This arg indicates the default color to be used in drawing
the graphic's bars for a single dataset representation (see also C<colors>).

=item colors

Default: C<color>.   This arg should be an arrayref to a list of colors to be
used in displaying the bars for multiple dataset graphs. If this arg is missing,
the bars for all datasets will be displayed in color C<color>. If the number of
colors is smaller then the number of datasets to be represented, the values are
"recycled". See also the Note for C<color> argument.

=item pixeldir

Optional argument to indicate the directory where the color pixel files are located;  for web scripts, this will have to be relative to the C<htdocs> dir. This
argument is ignored unless C<bartype> is set to C<pixel>.

=item pixelfmt

Default: PNG.  Optional argument to indicate the graphic format of the color 
pixel files; the C<lc()> of this argument's value is used as pixel file's 
extension (eg for PNG files, pixel files will be C<colorname.png>.  This 
argument is ignored unless C<bartype> is set to C<pixel>.

=item data

This is a required arg, and should contain the datasets to be represented in the
graphic.  It should be passed as arrayref of scalars (one set) or arrayrefs 
(multiple sets). 

=item tags

If this arg is present, it should indicate the tags that should be used to
identify the values in datasets. It should be an arrayref to a list of scalars,
with at least that many elements as the number of elements in the largest dataset.

=item setspacer

Default: true.  If true, this arg indicate that a space should be inserted to
separate the consecutive representations of datasets, for a cleaner view.  It
is set to false on single set representations.

=item highlighttag

This arg has effect only for a single dataset representation, and only when C<tags>
is present as well (when dataset has no C<tags>, see C<highlightpos>).  It can be an arrayref or scalar. If present, its values are compared with C<tags> values, and in case it matches one exactly, the color of the correspondent bar will be
set to C<highlightcolor> , if specified (see below).  If both C<highlighttag> 
and C<highlightpos> are specified, C<highlightpos> is ignored.

=item highlightpos

This arg has effect only for a single dataset representation.  It can be an 
arrayref or scalar. If present, the color of the correspondent 1-indexed position(s)in C<data> will be set to C<highlightcolor>, if specified (see below).  If 
both C<highlighttag> and C<highlightpos> are specified, C<highlightpos> is ignored.

=item highlightcolor

Default: C<red>.   This arg has effect only when C<highlighttag> or C<highlightpos>
has effect (see above).

=item addalt

Default: true.   If true, the C<addalt> attribute is added to the HTML C<img> 
tag, having as value the value that is represented on the bar.

=item showaxistags

Default: true.  If true, C<tags> are displayed along the base axis, if provided.

=item showvalues

Default: true.   If true, the values are displayed at the end of each bar.

=item valuesuffix

If C<showvalues> is true, any text string assigned to this argument will be 
displayed after the max value.

=item valueprefix

If C<showvalues> is true, any text string assigned to this argument will be
displayed before the max value.

=item bordertype

Default: C<undef>.  This arg sets the type of border the whole graph will be 
surrounded by.  Valid values are C<flat> (a frame of C<borderwidth> width and
C<bordercolor> color will be drawn around the graphic, using C<&lt;table&gt;> on
C<&lt;table&gt;> technique) or C<reised> (the C<border> attribute of the HTML
C<table> will be set to C<borderwidth> value) (see below).

=item bordercolor

Default: C<black>.  This arg has effect only when C<bordertype> is set to 
C<flat>, and it indicates the color for the graph's frame).  The value of this
arg can be a "well-known" color name (ie white, black etc) or the RGB value, as
specified in the HTML spec.

=item borderwidth

Default: C<3> for C<bordertype> set to C<flat>, and C<1> for C<reised>.  This 
arg has effect only when C<bordertype> is set, and it indicates the width
of the graph's border, in pixels.

=item bgcolor

Default: C<white>.  This arg indicates the background color of the graph area.
See format of color args at C<bordercolor>.

=item textcolor

Default: C<black>.  This arg indicates the font color of C<tags> and C<values>.

=item title

This arg indicates a string to be displayed as the title of the graph.

=item titlecolor

Default: C<textcolor>.  This arg only has effect when C<title> is specified, and
indicates the font color of C<title>.

=item titlealign

Default: C<center>.  This arg only has effect when C<title> is specified, and it
indicates the justification of the C<title> on the graph. Other valid values are
C<left> and C<right>.

=item fontface

Default: C<TimesRoman>.  This arg indicates the font face to be used in the text
displayed in the graph. The C<title> is displayed using size +2, the C<tags> and
axis labels (see below) in normal size, and the max values at the head of graph
bars in -1.

=item xlabel, ylabel

This args indicate the labels to be displayed on the base (x) and values (y)
axis of the graph.  Note: for a horizontal graph, the names of the axes are
reversed as normal (ie the x axis is the vertical one).

=item xlabelalign

Default: C<center>.  This arg only has effect when a C<xlabel> is specified, and
it indicates the justification of the C<xlabel> on the graph. Other valid values
are C<left> and C<right>.

=item ylabelalign

Default: C<middle>.  This arg only has effect when a C<ylabel> is specified, and
it indicates the justification of the C<ylabel> on the graph. Other valid values
are C<top> and C<bottom>.

=item labeltextcolor

Default: C<black>.  This arg indicates a color for the C<xlabel> and C<ylabel> 
text.

=item labelbgcolor

Default: C<bgcolor>.  This arg indicates a background color for the row and 
column that contain the C<xlabel> and C<ylabel>.

=back

=head1 TODO

=over 4

=item

alternate background color for dataset rows/cols

=item

accept a formatting string for max values (for sprintf)

=item

C<showaxis>

=item

support same size bars:  ######___ 66%

=item

ranges in tags, and C<highlighttag>/C<highlightpos> to fit in a range

=item

accept args to specify the text height for title, tags, max vals

=item

trick so that C<ALT> attrib of C<IMG> tags are displayed in netscape/linux

=item

support for negative values (1 col/row for +, 1 col/row for -)

=item

implement an object oriented interface 

=item

use HTML table building modules?

=item

test in IE

=back

=head1 BUGS

=over 4

=item

in several cases, the bars are not perfectly aligned (left for 'h' and bottom
for 'v') and the values are written on the next line for 'h' graphics

=item

values are not middle "valigned" for 'h'/'bgcolor' graphics

=back

=head1 AUTHOR

Vlad Podgurschi  E<lt>cpan@podgurschi.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut

