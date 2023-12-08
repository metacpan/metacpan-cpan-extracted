package Image::DS9::Constants::V1;

# ABSTRACT:  predefined constants

use v5.10;
use strict;
use warnings;

our $VERSION = 'v1.0.1';

use List::Util 'max';
use CXC::Exporter::Util ':all';
use base 'Exporter::Tiny';

## no critic(BuiltinFunctions::ProhibitComplexMappings)
sub _normalize {
    my $pfx = shift;

    $pfx = defined $pfx ? $pfx . '_' : q{};
    return {
        map {
            my $value   = $_;
            my $keyword = uc $value;
            $keyword =~ s/-/_/g;
            ( $pfx . $keyword, $value );
        } @_,
    };
}

BEGIN {
    my @misc = (
        'about',       'abs',          'active',     'align',      'all',         'amplifier',
        'append',      'array',        'automatic',  'average',    'background',  'black',
        'blink',       'blue',         'boxcar',     'buffersize', 'buttons',     'center',
        'clear',       'colorbar',     'cols',       'column',     'command',     'copy',
        'coordinate',  'coordformat',  'crosshair',  'cyan',       'datasec',     'degrees',
        'delete',      'deleteall',    'delim',      'depth',      'destination', 'detector',
        'dss',         'dss2blue',     'dss2red',    'ecliptic',   'eso',         'examine',
        'exclude',     'factor',       'file',       'filename',   'filter',      'first',
        'fits',        'fk4',          'fk5',        'format',     'function',    'galactic',
        'gap',         'gaussian',     'global',     'green',      'grid',        'gz',
        'hide',        'horzgraph',    'icrs',       'image',      'include',     'info',
        'invert',      'interpolate',  'interval',   'jpeg',       'last',        'layout',
        'level',       'limits',       'linear',     'load',       'local',       'log',
        'magenta',     'magnifier',    'manual',     'minmax',     'mode',        'mosaic',
        'mosaicimage', 'mosaicimages', 'moveback',   'movefront',  'name',        'new',
        'next',        'nl',           'no',         'off',        'on',          'orientation',
        'page',        'pagescale',    'pagesize',   'palette',    'pan',         'panner',
        'paste',       'physical',     'png',        'pointer',    'ppm',         'prev',
        'pros',        'radius',       'red',        'refresh',    'rel',         'replace',
        'resample',    'reset',        'resolution', 'rotate',     'row',         'sao',
        'saoimage',    'saotng',       'save',       'scope',      'selectall',   'selected',
        'selectnone',  'semicolon',    'server',     'setup',      'sexagesimal', 'show',
        'single',      'size',         'sky',        'skyformat',  'smooth',      'source',
        'sqrt',        'squared',      'state',      'strip',      'stsci',       'sum',
        'survey',      'system',       'tiff',       'tile',       'to',          'to fit',
        'tofit',       'type',         'url',        'user',       'value',       'vertgraph',
        'wcs',         'white',        'x',          'xy',         'y',           'yellow',
        'yes',         'zoom',         'zscale',
    );

    install_CONSTANTS( {
            ANGULAR_FORMATS => _normalize( ANGULAR_FORMAT => 'degrees', 'sexagesimal' ),

            ANGULAR_UNITS => _normalize( ANGULAR_UNIT => 'degrees', 'arcmin', 'arcsec' ),

            BIN_FUNCTIONS => _normalize( BIN_FUNCTION => 'average', 'sum' ),

            COLORBAR_ORIENTATIONS => _normalize( COLORBAR => 'horizontal', 'vertical' ),

            COLORS =>
              _normalize( undef, 'black', 'white', 'red', 'green', 'blue', 'cyan', 'magenta', 'yellow' ),

            CONTOUR_SCALES => _normalize(
                'CONTOUR_SCALE', 'linear', 'log', 'pow', 'squared', 'sqrt', 'asinh', 'sinh', 'histequ',
            ),

            CONTOUR_METHODS => _normalize( 'CONTOUR_METHOD', 'block', 'smooth', ),

            CUBE_CONTROLS => _normalize( CUBE_CONTROL => 'play', 'stop', 'next', 'prev', 'first', 'last' ),

            CUBE_ORDERS => _normalize( CUBE_ORDER => '123', '132', '213', '231', '312', '321' ),


            DSS_ESO_SURVEYS   => _normalize( DSS_ESO => 'DSS1', 'DSS2-red', 'DSS2-blue', 'DSS2-infrared', ),
            DSS_STSCI_SURVEYS => _normalize(
                DSS_STSCI => 'all',
                'phase2_gsc1',
                'phase2_gsc2',
                'poss1_blue',
                'poss1_red',
                'poss2ukstu_blue',
                'poss2ukstu_ir',
                'poss2ukstu_red',
                'quickv',
            ),

            ENDIANNESS => _normalize( ENDIAN => 'big', 'little', 'native' ),

            EXPORT_FORMATS =>
              _normalize( EXPORT_FORMAT => 'array', 'nrrd', 'envi', 'gif', 'tiff', 'jpeg', 'png' ),
            EXPORT_FORMATS_NOARGS => _normalize( EXPORT_FORMAT   => 'array', 'nrrd', 'gif', 'tiff', 'png' ),
            EXPORT_TIFF_ARGS      => _normalize( EXPORT_TIFF_ARG => 'none',  'jpeg', 'packbits', 'deflate' ),


            FONTS       => _normalize( FONT       => 'times',  'helvetica', 'courier' ),
            FONTWEIGHTS => _normalize( FONTWEIGHT => 'normal', 'bold' ),
            FONTSLANTS  => _normalize( FONTSLANT  => 'roman',  'italic' ),

            # no idea what to call this
            FRAME_COMPONENTS => _normalize(
                FRAME_COMPONENT => 'amplifier',
                'datamin', 'datasec', 'detector', 'grid',
                'iis',     'irafmin', 'physical', 'smooth',
            ),

            FRAME_SELECTIONS => _normalize( FRAME => 'first', 'next', 'prev',    'last' ),
            FRAME_MOVES      => _normalize( FRAME => 'first', 'back', 'forward', 'last' ),

            GRAPH_ORIENTATIONS => _normalize( GRAPH => 'horizontal', 'vertical' ),

            MINMAX_MODES => _normalize( MINMAX_MODE => 'scan', 'sample', 'datamin', 'irafmin' ),

            MISC => {
                map {
                    my $k = $_;
                    $k =~ s/\s/_/g;
                    ( $k => $_ )
                } @misc,
            },

            MOUSE_BUTTON_MODES => _normalize(
                MOUSE_BUTTON_MODE => 'none',
                'region',
                'crosshair',
                'colorbar',
                'pan',
                'zoom',
                'rotate',
                'catalog',
                'examine',
                '3d',
            ),

            NAMESERVERS => _normalize(
                NAMESERVER => 'ned-sao',
                'ned-cds',
                'simbad-sao',
                'simbad-cds',
                'vizier-sao',
                'vizier-cds',
            ),

            PAGE_ORIENTATIONS => _normalize( PAGE_ORIENT => 'portrait', 'landscape' ),
            PAGE_SIZES        => _normalize( PAGE_SIZE   => 'letter',   'legal', 'tabloid', 'poster', 'a4' ),

            PRINT_COLORS       => _normalize( PRINT_COLOR       => 'rgb',     'cmyk', 'gray' ),
            PRINT_DESTINATIONS => _normalize( PRINT_DESTINATION => 'printer', 'file' ),
            PRINT_LEVELS       => _normalize( PRINT_LEVEL       => 1,         2, 3 ),
            PRINT_RESOLUTIONS  => _normalize( PRINT_RESOLUTION  => 72, 96, 144, 150, 225, 300, 600, 1200 ),

            REGION_FORMATS =>
              _normalize( REGION_FORMAT => 'ds9', 'xml', 'ciao', 'saotng', 'saoimage', 'pros', 'xy' ),

            REGION_PROPERTIES => _normalize(
                REGION_PROPERTY => 'select',
                'edit', 'move', 'rotate', 'delete', 'fixed', 'include', 'source'
            ),

            RGB_COMPONENTS => _normalize( undef => 'blue', 'green', 'red' ),

            SAVE_FORMATS => _normalize(
                SAVE_FMT => 'fits',
                'rgbimage', 'rgbcube', 'mecube', 'mosaic', 'mosaicimage', 'mosaicwcs', 'mosaicimagewcs',
            ),

            SAVE_IMAGE_FORMATS => _normalize( SAVE_IMAGE_FMT => 'fits', 'eps', 'gif', 'tiff', 'jpeg', 'png' ),

            SCALE_FUNCTIONS =>
              _normalize( SCALE_FUNC => 'linear', 'log', 'pow', 'sqrt', 'squared', 'asinh', 'sinh', 'histequ' ),

            SKY_COORD_SYSTEMS =>
              _normalize( SKY_COORDSYS => 'fk4', 'fk5', 'icrs', 'galactic', 'ecliptic', 'B1950', 'J2000' ),

            SMOOTH_FUNCTIONS => _normalize( SMOOTH_FUNC => 'boxcar', 'tophat', 'gaussian' ),

            SPECIAL_ATTRIBUTES => _normalize( SPECIAL_ATTR => 'new', 'mask', 'now' ),

            VIEW_LAYOUTS => _normalize( VIEW_LAYOUT => 'horizontal', 'vertical', 'basic', 'advanced' ),

            WCS => { map { my $v = 'wcs' . $_; uc( $v ) => $v } ( 'a' .. 'z' ) },

            TERMINATE_DS9 => {
                TERMINATE_DS9_NO       => 0,
                TERMINATE_DS9_STARTED  => 1,
                TERMINATE_DS9_ATTACHED => 2,
                TERMINATE_DS9_YES      => 3,
            },
        },
    );

    install_EXPORTS( { _ => ['list'] } );
}

# performed outside of BEGIN so we get access to WCS
install_CONSTANTS( {
        CUBE_COORD_SYSTEMS => _normalize( CUBE_COORDSYS => 'wcs', WCS, 'image' ),

        FRAME_COORD_SYSTEMS =>
          _normalize( 'FRAME_COORDSYS', 'image', 'physical', 'amplifier', 'detector', 'wcs', WCS ),

        FRAME_COORD_SYSTEMS_NON_WCS =>
          _normalize( 'FRAME_COORDSYS_NON_WCS', 'image', 'physical', 'amplifier', 'detector' ),

        VIEW_BOOL_COMPONENTS => _normalize(
            VIEW_BOOL_COMPONENT => 'buttons',
            'colorbar',
            'filename',
            'frame',
            'icons',
            'image',
            'info',
            'keyword',
            'lowhigh',
            'magnifier',
            'minmax',
            'multi',
            'object',
            'panner',
            'physical',
            'units',
            'wcs',
            WCS,
        ),
    } );

install_EXPORTS;

sub list {
    my %opt = @_;

    my @TAGS;

    if ( exists $opt{tags} ) {
        @TAGS = 'ARRAY' eq ref $opt{tags} ? @{ $opt{tags} } : $opt{tags};
        my @bad = grep { !exists $EXPORT_TAGS{$_} } @TAGS;
        die( 'unknown tags: ', join( q{, }, @bad ) ) if @bad;
    }

    @TAGS or @TAGS = keys %EXPORT_TAGS;

    my @tags   = grep     { !/^(?:constants_funcs|_)$/ } @TAGS;
    my @list   = sort map { @{ $EXPORT_TAGS{$_} } } @tags;
    my $len    = max map  { length } @list;
    my $format = $opt{format} // "%-${len}s => '%s'\n";
    printf( $format, $_, &{ \&{$_} } ) foreach @list;
}

#
# This file is part of Image-DS9
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory NAMESERVERS WCS WCSA WCSZ

=head1 NAME

Image::DS9::Constants::V1 - predefined constants

=head1 VERSION

version v1.0.1

=head1 SYNOPSIS

  # import all of the constants
  use Image::DS9::Constants::V1 '-all';

  # import a subset
  use Image::DS9::Constants::V1 qw( const1 const2 );

  # change the prefix and import all of the constants
  use Image::DS9::Constants::V1 { prefix => 'X_' }, '-all';

  # change the prefix and import a subset
  # imports X_const1, X_const2
  use Image::DS9::Constants::V1
     { prefix => 'X_' }, qw( const1 const2 );

  # list the available constants
  use Image::DS9::Constants::V1;
  Image::DS9::Constants::V1::list;

=head1 DESCRIPTION

This module provides Perl constants for option strings used to
communicate with B<DS9>, making it easier to spot typos in code.  For
example,

  use Image::DS9::Constants::V1
     { prefix => 'X_' }, qw( reset );

  $ds9->regions( 'resett' );

will be caught at run time, while

  $ds9->regions( X_resett );

will be caught at compile time.

=head2 Renaming constants

B<Image::DS9::Constants> uses L<Exporter::Tiny>, so the constant names
can be modified when they are imported into the user's package.  See
that module's documentation for more information (See also the above
L</SYNOPSIS>).

=head2 Groups of constants

B<Image::DS9> uses L<CXC::Exporter::Util> to provide enumerating
functions for groups of constants.  To import an entire group
(e.g. the DSS_ESO_SURVEYS group)

  use Image::DS9::Constants -dss_eso_surveys;

To import the enumerating function for a group (e.g. the
DSS_ESO_SURVEYS group):

  use Image::DS9::Constants 'DSS_ESO_SURVEYS';

=head2 Listing Constants

To list the available constants, use the B<list> function:

  perl -MImage::DS9::Constants=list -e 'list'

This will print a listing of all of the constants.

=head1 CONSTANT GROUPS

The following groups are available. The group name is also the
enumerating function for the constants in the group, e.g.

  say $_ for ANGULAR_FORMATS;

results in

  degrees
  sexagesimal

=head2 ANGULAR_FORMATS

=head3 ANGULAR_FORMAT_DEGREES => C<degrees>

=head3 ANGULAR_FORMAT_SEXAGESIMAL => C<sexagesimal>

=head2 ANGULAR_UNITS

=head3 ANGULAR_UNIT_ARCMIN => C<arcmin>

=head3 ANGULAR_UNIT_ARCSEC => C<arcsec>

=head3 ANGULAR_UNIT_DEGREES => C<degrees>

=head2 BIN_FUNCTIONS

=head3 BIN_FUNCTION_AVERAGE => C<average>

=head3 BIN_FUNCTION_SUM => C<sum>

=head2 COLORS

=head3 BLACK => C<black>

=head3 BLUE => C<blue>

=head3 CYAN => C<cyan>

=head3 GREEN => C<green>

=head3 MAGENTA => C<magenta>

=head3 RED => C<red>

=head3 WHITE => C<white>

=head3 YELLOW => C<yellow>

=head2 DSS_ESO_SURVEYS

=head3 DSS_ESO_DSS1 => C<DSS1>

=head3 DSS_ESO_DSS2_BLUE => C<DSS2-blue>

=head3 DSS_ESO_DSS2_INFRARED => C<DSS2-infrared>

=head3 DSS_ESO_DSS2_RED => C<DSS2-red>

=head2 DSS_STSCI_SURVEYS

=head3 DSS_STSCI_ALL => C<all>

=head3 DSS_STSCI_GSC1 => C<gsc1>

=head3 DSS_STSCI_PHASE2 => C<phase2>

=head3 DSS_STSCI_PHASE2_GSC2 => C<phase2_gsc2>

=head3 DSS_STSCI_QUICKV => C<quickv>

=head2 FRAME_COORD_SYSTEMS

=head3 FRAME_COORDSYS_IMAGE => C<image>

=head3 FRAME_COORDSYS_PHYSICAL => C<physical>

=head3 FRAME_COORDSYS_WCS => C<wcs>

=head3 FRAME_COORDSYS_WCSA - FRAME_COORDSYS_WCSZ  => C<wcsa> - C<wcsz>

=head2 MINMAX_MODES

=head3 MINMAX_MODE_DATAMIN => C<datamin>

=head3 MINMAX_MODE_IRAFMIN => C<irafmin>

=head3 MINMAX_MODE_SAMPLE => C<sample>

=head3 MINMAX_MODE_SCAN => C<scan>

=head2 MOUSE_BUTTON_MODES

=head3 MOUSE_BUTTON_MODE_3D => C<3d>

=head3 MOUSE_BUTTON_MODE_CATALOG => C<catalog>

=head3 MOUSE_BUTTON_MODE_COLORBAR => C<colorbar>

=head3 MOUSE_BUTTON_MODE_CROSSHAIR => C<crosshair>

=head3 MOUSE_BUTTON_MODE_EXAMINE => C<examine>

=head3 MOUSE_BUTTON_MODE_NONE => C<none>

=head3 MOUSE_BUTTON_MODE_PAN => C<pan>

=head3 MOUSE_BUTTON_MODE_REGION => C<region>

=head3 MOUSE_BUTTON_MODE_ROTATE => C<rotate>

=head3 MOUSE_BUTTON_MODE_ZOOM => C<zoom>

=head2 NAMESERVERS

=head3 NAMESERVER_NED_CDS => C<ned-cds>

=head3 NAMESERVER_NED_SAO => C<ned-sao>

=head3 NAMESERVER_SIMBAD_CDS => C<simbad-cds>

=head3 NAMESERVER_SIMBAD_SAO => C<simbad-sao>

=head3 NAMESERVER_VIZIER_CDS => C<vizier-cds>

=head3 NAMESERVER_VIZIER_SAO => C<vizier-sao>

=head2 PAGE_ORIENTATIONS

=head3 PAGE_ORIENT_LANDSCAPE => C<landscape>

=head3 PAGE_ORIENT_PORTRAIT => C<portrait>

=head2 PAGE_SIZES

=head3 PAGE_SIZE_A4 => C<a4>

=head3 PAGE_SIZE_LEGAL => C<legal>

=head3 PAGE_SIZE_LETTER => C<letter>

=head3 PAGE_SIZE_POSTER => C<poster>

=head3 PAGE_SIZE_TABLOID => C<tabloid>

=head2 PRINT_COLORS

=head3 PRINT_COLOR_CMYK => C<cmyk>

=head3 PRINT_COLOR_GRAY => C<gray>

=head3 PRINT_COLOR_RGB => C<rgb>

=head2 PRINT_DESTINATIONS

=head3 PRINT_DESTINATION_FILE => C<file>

=head3 PRINT_DESTINATION_PRINTER => C<printer>

=head2 PRINT_LEVELS

=head3 PRINT_LEVEL_1 => C<1>

=head3 PRINT_LEVEL_2 => C<2>

=head3 PRINT_LEVEL_3 => C<3>

=head2 PRINT_RESOLUTIONS

=head3 PRINT_RESOLUTION_1200 => C<1200>

=head3 PRINT_RESOLUTION_144 => C<144>

=head3 PRINT_RESOLUTION_150 => C<150>

=head3 PRINT_RESOLUTION_225 => C<225>

=head3 PRINT_RESOLUTION_300 => C<300>

=head3 PRINT_RESOLUTION_600 => C<600>

=head3 PRINT_RESOLUTION_72 => C<72>

=head3 PRINT_RESOLUTION_96 => C<96>

=head3 PRINT_RESOLUTION_SCREEN => C<screen>

=head2 REGION_FORMATS

=head3 REGION_FORMAT_CIAO => C<ciao>

=head3 REGION_FORMAT_DS9 => C<ds9>

=head3 REGION_FORMAT_PROS => C<pros>

=head3 REGION_FORMAT_SAOIMAGE => C<saoimage>

=head3 REGION_FORMAT_SAOTNG => C<saotng>

=head3 REGION_FORMAT_XML => C<xml>

=head3 REGION_FORMAT_XY => C<xy>

=head2 SKY_COORD_SYSTEMS

=head3 SKY_COORDSYS_ECLIPTIC => C<ecliptic>

=head3 SKY_COORDSYS_FK4 => C<fk4>

=head3 SKY_COORDSYS_FK5 => C<fk5>

=head3 SKY_COORDSYS_GALACTIC => C<galactic>

=head3 SKY_COORDSYS_ICRS => C<icrs>

=head2 WCS

=head3 WCSA - WCSZ => C<wcsa> - C<wcsz>

=head2 GRAPH_ORIENTATIONS

=head3 GRAPH_VERTICAL => C<vertical>

=head3 GRAPH_HORIZONTAL => C<horizontal>

=head2 MISC

These are available, but deprecated, as they are common names for
existing subroutines.  It's best to import them with a prefix, e.g.

  use Image::DS9::Constants::V1 { prefix => 'X_' }, -misc;

They have not been updated for DS9 V8.4.1, so some are no longer valid.

  about	       => 'about'	      abs	   => 'abs'
  active       => 'active'	      align	   => 'align'
  all	       => 'all'		      amplifier	   => 'amplifier'
  append       => 'append'	      array	   => 'array'
  automatic    => 'automatic'	      average	   => 'average'
  background   => 'background'	      black	   => 'black'
  blink	       => 'blink'	      blue	   => 'blue'
  boxcar       => 'boxcar'	      buffersize   => 'buffersize'
  buttons      => 'buttons'	      center	   => 'center'
  clear	       => 'clear'	      colorbar	   => 'colorbar'
  cols	       => 'cols'	      column	   => 'column'
  command      => 'command'	      coordformat  => 'coordformat'
  coordinate   => 'coordinate'	      copy	   => 'copy'
  crosshair    => 'crosshair'	      cyan	   => 'cyan'
  datasec      => 'datasec'	      degrees	   => 'degrees'
  delete       => 'delete'	      deleteall	   => 'deleteall'
  delim	       => 'delim'	      depth	   => 'depth'
  destination  => 'destination'	      detector	   => 'detector'
  dss	       => 'dss'		      dss2blue	   => 'dss2blue'
  dss2red      => 'dss2red'	      ecliptic	   => 'ecliptic'
  eso	       => 'eso'		      examine	   => 'examine'
  exclude      => 'exclude'	      factor	   => 'factor'
  file	       => 'file'	      filename	   => 'filename'
  filter       => 'filter'	      first	   => 'first'
  fits	       => 'fits'	      fk4	   => 'fk4'
  fk5	       => 'fk5'		      format	   => 'format'
  function     => 'function'	      galactic	   => 'galactic'
  gap	       => 'gap'		      gaussian	   => 'gaussian'
  global       => 'global'	      green	   => 'green'
  grid	       => 'grid'	      gz	   => 'gz'
  hide	       => 'hide'	      horzgraph	   => 'horzgraph'
  icrs	       => 'icrs'	      image	   => 'image'
  include      => 'include'	      info	   => 'info'
  interpolate  => 'interpolate'	      interval	   => 'interval'
  invert       => 'invert'	      jpeg	   => 'jpeg'
  last	       => 'last'	      layout	   => 'layout'
  level	       => 'level'	      limits	   => 'limits'
  linear       => 'linear'	      load	   => 'load'
  local	       => 'local'	      log	   => 'log'
  magenta      => 'magenta'	      magnifier	   => 'magnifier'
  manual       => 'manual'	      minmax	   => 'minmax'
  mode	       => 'mode'	      mosaic	   => 'mosaic'
  mosaicimage  => 'mosaicimage'	      mosaicimages => 'mosaicimages'
  moveback     => 'moveback'	      movefront	   => 'movefront'
  name	       => 'name'	      new	   => 'new'
  next	       => 'next'	      nl	   => 'nl'
  no	       => 'no'		      off	   => 'off'
  on	       => 'on'		      orientation  => 'orientation'
  page	       => 'page'	      pagescale	   => 'pagescale'
  pagesize     => 'pagesize'	      palette	   => 'palette'
  pan	       => 'pan'		      panner	   => 'panner'
  paste	       => 'paste'	      physical	   => 'physical'
  png	       => 'png'		      pointer	   => 'pointer'
  ppm	       => 'ppm'		      prev	   => 'prev'
  pros	       => 'pros'	      radius	   => 'radius'
  red	       => 'red'		      refresh	   => 'refresh'
  rel	       => 'rel'		      replace	   => 'replace'
  resample     => 'resample'	      reset	   => 'reset'
  resolution   => 'resolution'	      rotate	   => 'rotate'
  row	       => 'row'		      sao	   => 'sao'
  saoimage     => 'saoimage'	      saotng	   => 'saotng'
  save	       => 'save'	      scope	   => 'scope'
  selectall    => 'selectall'	      selected	   => 'selected'
  selectnone   => 'selectnone'	      semicolon	   => 'semicolon'
  server       => 'server'	      setup	   => 'setup'
  sexagesimal  => 'sexagesimal'	      show	   => 'show'
  single       => 'single'	      size	   => 'size'
  sky	       => 'sky'		      skyformat	   => 'skyformat'
  smooth       => 'smooth'	      source	   => 'source'
  sqrt	       => 'sqrt'	      squared	   => 'squared'
  state	       => 'state'	      strip	   => 'strip'
  stsci	       => 'stsci'	      sum	   => 'sum'
  survey       => 'survey'	      system	   => 'system'
  tiff	       => 'tiff'	      tile	   => 'tile'
  to	       => 'to'		      to_fit	   => 'to fit'
  tofit	       => 'tofit'	      type	   => 'type'
  url	       => 'url'		      user	   => 'user'
  value	       => 'value'	      vertgraph	   => 'vertgraph'
  wcs	       => 'wcs'		      white	   => 'white'
  x	       => 'x'		      xy	   => 'xy'
  y	       => 'y'		      yellow	   => 'yellow'
  yes	       => 'yes'		      zoom	   => 'zoom'
  zscale       => 'zscale'

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-image-ds9@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-DS9>

=head2 Source

Source is available at

  https://gitlab.com/djerius/image-ds9

and may be cloned from

  https://gitlab.com/djerius/image-ds9.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Image::DS9|Image::DS9>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
