#========================================================================
# Kite::PScript::Defs
#
# DESCRIPTION 
#   Perl module defining a number of PostScript definitions useful 
#   for generating PostScript documents for kite part layout, etc.
# 
# AUTHOR
#   Simon Stapleton <simon@tufty.co.uk> wrote the original xml2ps.pl
#   utility which contained most of the PostScript contained herein.
#
#   Most of that, he freely admits, was gleaned from the Blue Book
#   (PostScript Language Tutorial and Cookbook, Adobe).
#
#   Andy Wardley <abw@kfs.org> re-packaged it into a module for 
#   integration into the Kite bundle.
#
# COPYRIGHT
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# VERSION
#   $Id: Defs.pm,v 1.3 2000/10/18 08:37:49 abw Exp $
#
#========================================================================

package Kite::PScript::Defs;

require 5.004;
use Exporter;

use base qw( Exporter );
use vars qw( $AUTOLOAD @EXPORT_OK %EXPORT_TAGS 
             $mm $lines $cross $dot $circle $crop $clip $reg $noreg 
             $outline $tiles $tilemap $dotiles $pathtext $box );

@EXPORT_OK   = qw( mm lines cross dot circle crop clip reg noreg 
                   outline tiles tilemap dotiles pathtext );
%EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

sub AUTOLOAD {
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';
    return ${ __PACKAGE__ . "\::$item" };
}

sub load {
    my $class = shift;
    return $class;
}

sub new {
    my $class = shift;
    bless { }, $class;
}


#------------------------------------------------------------------------
$mm =<<EOF;
/mm { 72 mul 25.4 div } bind def
EOF

#------------------------------------------------------------------------
$lines =<<EOF;
/linelight  { 0.25 setlinewidth [] 0 setdash } bind def
/linenormal { 0.5  setlinewidth [] 0 setdash } bind def
/lineheavy  { 0.75 setlinewidth [] 0 setdash } bind def
/linedotted { 0.5  setlinewidth [3 5 1 5] 0 setdash } def
/linedashed { 0.5  setlinewidth [5 3 2 3] 0 setdash } def
EOF

#------------------------------------------------------------------------
$cross =<<EOF;
/cross {
  linenormal
  newpath moveto
  -5 mm 0 rmoveto
  10 mm 0 mm rlineto
  -5 mm -5 mm rmoveto
  0 mm 10 mm rlineto
  stroke
} def
EOF

#------------------------------------------------------------------------
$dot =<<EOF;
/dot {
  linenormal
  newpath 0.75 mm 0 360 arc
  fill
  stroke
} def
EOF

#------------------------------------------------------------------------
$circle =<<EOF;
/circle {
  linenormal
  newpath 2 mm 0 360 arc
  stroke
} def
EOF

#------------------------------------------------------------------------
$crop =<<EOF;
/crop {
    /y exch def
    /x exch def
    x y circle
    x y cross
} def
EOF

#------------------------------------------------------------------------
$clip =<<EOF;
% clipping rectangle set to current imageable size minus border
clippath pathbbox 
/cliptry exch border sub def 
/cliptrx exch border sub def 
/clipbly exch border add def 
/clipblx exch border add def
/clipysize cliptry clipbly sub def
/clipxsize cliptrx clipblx sub def
/clipbox {
  clipblx clipbly clipxsize clipysize
} def

EOF

#------------------------------------------------------------------------
$reg =<<EOF;
% registration marks relative to clipping rectangle,
% of course...
/regmarks {
  % draw clipping edge if border > 0
  border 0 gt {
    linedashed
%    .5 setgray
    clipbox rectstroke
  } if

  % draw registration marks at corners
  linenormal
%  0 setgray
  clipblx clipbly crop
  clipblx cliptry crop 
  cliptrx cliptry crop
  cliptrx clipbly crop
} def
EOF

#------------------------------------------------------------------------
$noreg =<<EOF;
% Define a dummy regmarks procedure
/regmarks { } def
EOF

#------------------------------------------------------------------------
$outline =<<EOF;
% define procedure to draw an outline at a fixed distance from path
/outline {
  gsave
  linedashed
  dup /outwide exch def
  setlinewidth
  gsave stroke grestore
  outwide 2 sub setlinewidth 1 setgray [] 0 setdash
  stroke
  grestore
} def
EOF
    
#------------------------------------------------------------------------
$tiles =<<EOF;
% tiles determines number of page tiles required for path on stack
/tiles {
  gsave
  pathbbox 
  /try exch def 
  /trx exch def 
  /bly exch def 
  /blx exch def
  /ysize try bly sub abs def
  /xsize trx blx sub abs def
  grestore

  % calculate number of tiles required in X and Y
  /tilesnx { xsize clipxsize div ceiling } def
  /tilesny { ysize clipysize div ceiling } def

  % determine X/Y offset required to centre path in tiles
  /tilesxorg tilesnx clipxsize mul xsize sub 2 div border add def
  /tilesyorg tilesny clipysize mul ysize sub 2 div border add def

  % add border to tilesorgx/y?
} def
EOF


#------------------------------------------------------------------------
$tilemap =<<EOF;
% prints map of page tiles with current page shaded
/tilemap {
  gsave
%  0.5 setlinewidth
  /mapx clipxsize 15 div def
  /mapy clipysize 15 div def
  /gapx mapx 5 div def
  /gapy gapx def
  /mapxsize mapx gapx add def
  /mapysize mapy gapy add def
  /mapxorg clipblx gapx add def
  /mapyorg cliptry mapysize tilesny mul sub def
  0 1 tilesnx 1 sub {
    /maptx exch def
    0 1 tilesny 1 sub {
      /mapty exch def
      % fill tile if current page
      maptx tilex eq mapty tiley eq and {
        mapxorg maptx mapxsize mul add
        mapyorg mapty mapysize mul add
        mapx mapy .9 setgray rectfill
        0.2 setgray
        0.5 setlinewidth
      } {
        0.5 setgray
        0.5 setlinewidth
      } ifelse
      % outline tile
      mapxorg maptx mapxsize mul add
      mapyorg mapty mapysize mul add
      mapx mapy rectstroke
    } for
  } for
  grestore
} def
EOF

#------------------------------------------------------------------------
# dotiles
$dotiles =<<EOF;
% we process pages from top left to bottom right, so must negate the order 
% of the y pages
tilesny 1 sub -1 0
{
  /tiley exch def
  0 1 tilesnx 1 sub
  {
    /tilex exch def
    tilepage
    gsave
      clipbox rectclip
      % translate origin to the new image rectangle
      tilesxorg tilesyorg translate
      tilex clipxsize mul neg tiley clipysize mul neg translate
      tileimage
      showpage
    grestore
  } for
} for
EOF


#------------------------------------------------------------------------
$pathtext =<<EOF;
%------------------------------------------------------------------------
% Define /pathtext function to draw text along an arbitrary path (ripped 
% off from the Blue Book, of course)
%
/pathtextdict 26 dict def
/pathtext { 
  pathtextdict begin
  /offset exch def
  /str exch def
  /pathdist 0 def
  /setdist offset def
  /charcount 0 def
  gsave
    flattenpath
    {movetoproc} {linetoproc} {curvetoproc} {closepathproc}
    pathforall
  grestore
  newpath
  end
} def

pathtextdict begin
/movetoproc { 
  /newy exch def /newx exch def
  /firstx newx def /firsty newy def
  /ovr 0 def
  newx newy transform
  /cpy exch def /cpx exch def
} def

/linetoproc { 
  /oldx newx def /oldy newy def
  /newy exch def /newx exch def
  /dx newx oldx sub def
  /dy newy oldy sub def
  /dist dx dup mul dy dup mul add sqrt def
  dist 0 ne
    { /dsx dx dist div ovr mul def
      /dsy dy dist div ovr mul def
      oldx dsx add oldy dsy add transform
      /cpy exch def /cpx exch def
      /pathdist pathdist dist add def
      { setdist pathdist le
          { charcount str length lt
              {setchar} {exit} ifelse }
          { /ovr setdist pathdist sub def
            exit }
          ifelse
      } loop
  } if
} def

/curvetoproc { 
  (ERROR: No curveto's after flattenpath!) print
} def

/closepathproc { 
  firstx firsty linetoproc
  firstx firsty movetoproc
} def

/setchar {
  /char str charcount 1 getinterval def
  /charcount charcount 1 add def
  /charwidth char stringwidth pop def
  gsave
    cpx cpy itransform translate
    dy dx atan rotate
    0 0 moveto char show
    currentpoint transform
    /cpy exch def /cpx exch def
  grestore
  /setdist setdist charwidth add def
} def
end
%------------------------------------------------------------------------

EOF


#------------------------------------------------------------------------
$box =<<EOF;
% blx bly trx try Box
% create a new Box array
/Box {
    4 array astore
} def

% Box Box_select
% unpacks Box to define various Box_* variables
/Box_select {
    aload pop
    /Box_try exch def
    /Box_trx exch def
    /Box_bly exch def
    /Box_blx exch def
    /Box_width  Box_trx Box_blx sub abs def
    /Box_height Box_try Box_bly sub abs def
} def

% Box Box_rect
% output Box as a rect suitable for rectstoke etc.
/Box_rect {
    Box_select
    Box_blx Box_bly Box_width Box_height
} def

% Box Box_path
% output Box as a path suitable for stroke, clip, etc.
/Box_path {
    Box_select
    newpath
    Box_blx Box_bly moveto
    Box_blx Box_try lineto
    Box_trx Box_try lineto
    Box_trx Box_bly lineto
    closepath 
} def

% Box border Box_border
% create a new Box bordered within a Box
/Box_border {
    /border exch def
    Box_select
    Box_blx border add 
    Box_bly border add
    Box_trx border sub 
    Box_try border sub 
    Box
} def

% Box tiles space pad Box_vsplit
% split Box vertically into 'tiles' new Boxes, spaced apart by 'space' 
% and padded within the original Box by 'pad'
/Box_vsplit {
    /Box_pad   exch def
    /Box_space exch def    
    /Box_tiles exch def
    Box_select
    /Box_height 
      Box_try Box_bly sub 
      Box_pad 2 mul sub 
      Box_space Box_tiles 1 sub mul sub 
      Box_tiles div
      def
    /Box_width
      Box_trx Box_blx sub 
      Box_pad 2 mul sub 
      def
    /Box_blx Box_blx Box_pad add def
    /Box_bly Box_bly Box_pad add def
    1 1 Box_tiles {
      pop
      Box_blx Box_bly Box_blx Box_width add Box_bly Box_height add Box
      /Box_bly Box_bly Box_height add Box_space add def
    } for
} def 

% Box tiles space pad Box_hsplit
% as per Box_vsplit, splitting Box horizontally
/Box_hsplit {
    /Box_pad   exch def
    /Box_space exch def    
    /Box_tiles exch def
    Box_select
    /Box_height Box_height 
      Box_pad 2 mul sub 
      def
    /Box_width Box_width
      Box_pad 2 mul sub 
      Box_space Box_tiles 1 sub mul sub 
      Box_tiles div
      def
    /Box_blx Box_blx Box_pad add def
    /Box_bly Box_bly Box_pad add def
    1 1 Box_tiles {
      pop
      Box_blx Box_bly Box_blx Box_width add Box_bly Box_height add Box
      /Box_blx Box_blx Box_width add Box_space add def
    } for
} def 


/Box_focus {
    /Box_box exch def
    gsave
    Box_box Box_select
    Box_box Box_path clip
    Box_blx Box_bly translate
} def

/Box_defocus {
    grestore
} def
EOF


1;

__END__

=head1 NAME

Kite::PScript::Defs - useful PostScript definitions for kite layout et al

=head1 SYNOPSIS

    use Kite::PScript::Defs;

    # access package variables directly
    print $Kite::PScript::Defs::mm;

    # or as package subs
    print Kite::PScript::Defs::mm();

    # or as class methods
    print Kite::PScript::Defs->mm();

    # here's a convenient shorthand
    my $ps = 'Kite::PScript::Defs';
    print $ps->mm;

    # import various definitions
    use Kite::PScript::Defs qw( mm clip );
    print mm, clip;

    # or specify :all tag to import all definitions as subs
    use Kite::PScsript::Defs qw( :all );
    print mm, reg, clip, pathtext;

=head1 DESCRIPTION

Module defining a number of useful PostScript definitions for kite part
layout and other similar tasks.  

The definitions are provided as package variables which can be accessed
directly:

    use Kite::PScript::Defs;

    print $Kite::PScript::Defs::mm;

An AUTOLOAD method is provided which translates any subroutine or method
calls into accesses to the appropriate variable.  Thus, the PostScript 
definition specified in the $mm package variable can be accessed by calling 
either of:

    Kite::PScript::mm();
    Kite::PScript->mm();

The latter use allows a 'factory' variable to be defined to make this 
less tedious.

    my $ps = 'Kite::PScript::Defs';
    print $ps->mm, $ps->clip, $ps->pathtext;

You can specify import parameters when loading the module.  Any definitions
specified will be imported as subroutines into the caller's namespace.

    use Kite::PScript::Defs qw( mm clip );
    print mm, clip;

The ':all' import tag can be specified to import all the PoscScript 
definitions.

    use Kite::PScript::Defs qw( :all );
    print mm, clip, pathtext;

=head1 TEMPLATE TOOLKIT

The module is defined to be intimately useful when used in conjunction 
with the Template Toolkit.  To use the PostScript definitions within a 
template, simply ensure that the module is loaded and bless an empty 
hash into the Kite::PScript::Defs package.  This will allow the Template
Toolkit to resolve to the correct class methods.

    use Template;
    use Kite::PScript::Defs;

    my $tt2  = Template->new();
    my $vars = {
	psdefs => bless({ }, 'Kite::PScript::Defs'),
    };

    $tt2->process(\*DATA, $vars)
	|| die $tt2->error();

    __END__
    %!PS-Adobe-3.0
    %%EndComments

    [% psdefs.mm %]
    [% psdefs.lines %]
    [% psdefs.cross %]
    [% psdefs.dot %]
    [% psdefs.circle %]
    [% psdefs.crop %]
    [% psdefs.reg %]

    0 mm 0 mm moveto	% /mm defined in psdefs.mm
    crop		% /crop defined in psdefs.crop
    regmarks		% /regmarks defined in psdefs.reg
    ...etc...

=head1 POSTSCRIPT DEFINITION METHODS

=over 4

=item mm

Defines millimetres /mm.

    [% psdefs.mm %]
    10 mm 10 mm moveto
    50 mm 10 mm lineto

=item lines

Defines the following line styles:

    linelight		% 0.25 setlinewidth
    linenormal		% 0.5  setlinewidth
    lineheavy		% 0.75 setlinewidth
    linedotted		% 0.5  setlinewidth + dotted
    linedashed		% 0.5  setlinewidth + dashed

Example:

    [% psdefs.mm %]
    [% psdefs.lines %]
    linenormal
    newpath
    0 mm 0 mm moveto
    100 mm 0 mm lineto
    stroke
  
=item cross

Defines a procedure to generate a cross from vertical and horizontal 
lines 10mm in length, crossing at the current point.  Requires 'mm'
and 'lines'.

    [% psdefs.mm %]
    [% psdefs.lines %]
    [% psdefs.cross %]
    50 mm 50 mm		% move to a point
    cross		% draw cross

=item dot

Defines a procedure to generate a small filled dot at the current
point.  Requires 'mm' and 'lines'.

    [% psdefs.mm %]
    [% psdefs.lines %]
    [% psdefs.dot %]
    50 mm 50 mm		% move to a point
    dot			% draw dot

=item circle

Defines a procedure to generate a small circle at the current point.
Requires 'mm' and 'lines'.

    [% psdefs.mm %]
    [% psdefs.lines %]
    [% psdefs.circle %]
    50 mm 50 mm		% move to a point
    circle		% draw circle

=item crop

Defines a procedure to generate a crop mark at the current point,
built from a combination of /cross and /circle.  Requires 'mm',
'lines', 'cross' and 'circle'.

    [% psdefs.mm %]
    [% psdefs.lines %]
    [% psdefs.cross %]
    [% psdefs.circle %]
    0 mm 0 mm		% move to a point
    circle		% draw crop mark

=item clip

Defines /cliprect as a procedure to return a clipping rectangle set to
the imageable size.  Defines a number of other variables containing 
information about the clipping rectangle.

    cliprect		% clipping rectangle
    cliptrx		% top right x
    cliptry		% top right y
    clipblx		% bottom left x
    clipbly		% bottom left y
    clipxsize		% width 
    clipysize		% height 

=item reg

Defines /regmarks to generate registration marks (crop) at the corners
of the clipping rectangle, /cliprect.  Requires 'mm', 'lines', 'cross',
'circle', 'crop' and 'clip'.

    [% psdefs.mm %]
    [% psdefs.lines %]
    [% psdefs.cross %]
    [% psdefs.circle %]
    [% psdefs.crop %]
    [% psdefs.clip %]

    regmarks		% draw registration marks

=item noreg

Defines /regmarks as a no-op procedure to prevent registration marks 
from being produced.

    regmarks		% null registration marks

=item pathtext

Defines /pathtext to draw text along an arbitrary path.

    path text pathtext	% draw text along path    

    ** TODO - see Blue Book for examples **

=item tiles

Defines /tiles as a procedure which calculates the number of pages 
required to display the current path on the output device.  Also 
calculates the X/Y origin required for the path to be centered within
the tile set.  Defines the following items.

    tilesnx		% no. of tiles in x
    tilesny		% no. of tiles in y
    tilesxorg		% suggested x origin
    tilesyorg		% suggested y origin

See next item for example of use.

=item dotiles

Generates PostScript to tile an image into multiple pages.  It requires
that a number of items be pre-defined.  The first, /tileimage, should 
be a procedure defined to generate the image itself.

    /tileimage {
	...PostScript to generate your image...
    } def

The next item, /tilepath, should be a procedure defined to generate a path
which encloses the image.  This is used to calculate the bounding box for
the image.

    /tilepath {
	...PostScript path to bound your image...
    } def

Finally, the /tilepage item should be a procedure defined to generate any
output required on each tiled page (i.e. independant of the main image 
which ends up split across many pages).

    [% psdefs.mm %]
    [% psdefs.reg %]
    [% psdefs.clip %]

    /tilepage {
	regmarks		% generate registration marks
	/Times-Roman findfont 
	24 scalefont setfont	% set font
	clipblx 3 mm add 
	clipbly 3 mm add moveto	% move to lower left corner
	([% title %]) show	% print title
	tilemap			% generate tiling map
    } def

To tile the image onto multiple pages, the /tiles procedure should be 
called to determine the tiling requirements.  The /tilepath item should
be on the stack (i.e. precede the call).  

    [% psdefs.tiles %]

    tilepath tiles

Then, the 'dotiles' method can be called to generate the appropriate
PostScript code to tile the image onto multiple pages.

    [% defs.dotiles %]

=item Box

This item generates a PostScript definition for a Box object which can 
be used for all kinds of things boxlike.  The following documentation 
items describe the available Box "methods" in more detail, but for now,
here's a complete example.

    %!PS-Adobe-3.0
    %%Title: Box Example
    %%EndComments

    [% defs.mm %]
    [% defs.lines %]
    [% defs.cross %]
    [% defs.dot %]
    [% defs.circle %]
    [% defs.crop %]
    [% defs.box %]

    # define a general border value
    /border [% border %] mm def

    % convert the clipping path into a Box
    clippath pathbbox Box 

    % inset this Box by /border
    border Box_border 

    % and define /page to be this slightly smaller Box
    /page exch def

    % split /page into 3 vertical boxes
    page 3 border 0 Box_vsplit
    /upper  exch def
    /middle exch def
    /lower  exch def

    % inset upper box by border and define /inner
    upper border Box_border
    /inner exch def

    % split it horizontally into /left and /right
    inner 2 border 0 Box_hsplit
    /right exch def
    /left  exch def

    % stroke /upper, /middle and /lower boxes.
    linenormal
    upper  Box_rect rectstroke
    middle Box_rect rectstroke
    lower  Box_rect rectstroke

    % focus the drawing context on the /middle box
    middle Box_focus
    newpath
    0 0 moveto
    100 mm 100 mm lineto
    ...more complicated stuff here...
    stroke
    middle Box_defocus

    showpage

=item Box_select

Unpacks a Box structure to define various Box_* variables.

    Box_try	    % top right y
    Box_trx	    % top right x
    Box_bly	    % bottom left y
    Box_blx	    % bottom left x
    Box_width	    % width of Box
    Box_height	    % height of Box

Example:

    mybox Box_select

=item Box_rect

Unpacks a Box structure to a rect suitable for rectstroke, etc.

    mybox Box_rect rectstroke

=item Box_path

Unpacks a Box structure to a path suitable for stroke, clip, etc.

    mybox Box_path stroke

=item Box_border

Creates a new Box within a specified border of an existing Box.

    mybox 10 mm Box_bqorder
    /smallbox exch def

=item Box_vsplit

Splits a box vertically into a number of equal sized boxes.  Spacing and
padding variables should also be specified to control the sizes and 
relative positions of the new boxes.

    % split /mybox into 3 new Box objects, /upper, /middle and 
    % /lower, padded 10 mm within existing /mybox and spaced 
    % 5 mm apart from each other
    mybox 3 10 mm 5 mm Box_vsplit
    /upper  exch def
    /middle exch def
    /lower  exch def

=item Box_hsplit

As per Box_Vsplit but splitting a Box horizontally.

    middle 2 10 mm 5 mm Box_hsplit
    /right exch def
    /left  exch def

=item Box_focus

Creates a new drawing context which is focussed on a particular Box.
That is, all drawing will happen relative to the origin of the Box and
be clipped within its bounds.

    middle Box_focus

=item Box_defocus

Restores the previous drawing context saved by a prior Box_focus.
    
=back

=head1 AUTHOR

Simon Stapleton <simon@tufty.co.uk> wrote the original xml2ps.pl
utility which inspired much of the original PostScript contained
herein.  Most of that, he freely admits, was gleaned from the Blue
Book (PostScript Language Tutorial and Cookbook, Adobe).

Andy Wardley <abw@kfs.org> re-packaged it into a module for
integration into the Kite bundle.  Various features and more advanced
defintions have been added along the way.

=head1 REVISION

$Revision: 1.3 $

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 TODO

It would be nice to have some way of automatically managing all
dependencies between different procedures.  For example, if you call
the 'circle' method then it should ensure that 'mm' and 'lines' are
first called if they haven't been called previously.

It may make more sense to package this module as a general purpose 
PostScript library and/or plugin for the Template Toolkit.

=head1 SEE ALSO

For further information on the Kite::* modules, see L<Kite>.  For
further information on the Template Toolkit, see L<Template> or 
http://www.template-toolkit.org/ .

=cut


