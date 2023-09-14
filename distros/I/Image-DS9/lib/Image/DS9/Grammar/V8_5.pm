package Image::DS9::Grammar::V8_5;

# ABSTRACT: Grammar definitions
use v5.10;
use strict;
use warnings;

our $VERSION = 'v1.0.0';

use Exporter::Shiny '_grammar';

use Image::DS9::Util 'TODO';
use Image::DS9::PConsts;
use Image::DS9::Constants::V1 -constants_funcs;

my %Grammar = tokenize(

    #------------------------------------------------------>

    two_mass => TODO,

    #------------------------------------------------------

    threed => TODO,

    #------------------------------------------------------

    about => [ [ [], { rvals => [STRING], query => QONLY } ] ],

    #------------------------------------------------------

    align => [ [ [], { args => [BOOL] } ], ],

    #------------------------------------------------------

    analysis => TODO,

    #------------------------------------------------------

    array => [

        # TODO: is there a bitpix? if so, turn these into ndarrays with the appropriate type.
        # [
        #     [ENUM( ENDIANNESS )],
        #     {
        #         rvals=>[], query => QONLY,
        #     },
        # ],

        [
            [],
            {
                args   => [PDL],
                attrs  => [ new => BOOL, mask => BOOL ],
                query  => QNONE,
                bufarg => 1,
            },

            {
                args  => [SCALARREF],
                attrs => [
                    new    => BOOL,
                    mask   => BOOL,
                    bitpix => INT,
                    skip   => INT,
                    -o     => [ ( -a => [ xdim => INT, ydim => INT ] ), ( dim => INT ) ],
                    zdim   => INT,
                    endian => ENUM( ENDIANNESS ),
                ],
                query  => QNONE,
                bufarg => 1,
            },

        ],

    ],

    #------------------------------------------------------

    backup => [ [ [], { args => [FILENAME], query => QNONE } ] ],

    #------------------------------------------------------

    bin => [
        [ [ 'about', 'center' ], { query => QNONE }, ],

        [ ['about'], { args => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ] }, ],

        [ ['buffersize'], { args => [INT] } ],

        # cols returns 2 or 3 cols depending upon whether i
        # the frame is 3D or not, but it is only used to set
        # the columns for 2D.
        [
            ['cols'],
            {
                args  => [ STRING( '<xcol>' ), STRING( '<ycol>' ) ],
                rvals => [ARRAY],
            },
        ],

        # set the columns for 3D, but it doesn't return them;
        # use cols for that
        [
            ['colsz'],
            {
                args  => [ STRING( '<xcol>' ), STRING( '<ycol>' ), STRING( '<zcol>' ) ],
                query => QNONE,
            },
        ],

        [
            ['factor'],
            { args => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ], rvals => [ARRAY] },
            { args => [ FLOAT( '<x/y>' ) ],               rvals => [ARRAY] },
        ],

        [ ['depth'], { args => [INT] } ],

        [ ['filter'], { args => [ STRING_QUOTE( '<filter>' ) ] } ],

        [ ['function'], { args => [ ENUM( BIN_FUNCTIONS ) ], rvals => [ STRING( '<function>' ) ] } ],

        [ [ ENUM( 'in', 'out' ) ], { query => QNONE } ],

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [ ['match'], { query => QNONE } ],

        [ ['lock'], { args => [BOOL] } ],

        [ [ REWRITE( 'tofit', 'to fit' ) ], { query => QNONE } ],

        [ ['to fit'], { query => QNONE } ],
    ],

    #------------------------------------------------------

    blink => [
        [ [ EPHEMERAL( 'state' ) ], { rvals => [BOOL], query => QONLY }, ],
        [ ['interval'],             { args  => [FLOAT] }, ],
        [ [],                       { args  => [BOOL], query => QNONE }, { query => QNONE }, ],
    ],


    #------------------------------------------------------

    block => [

        [
            ['to'],
            { args => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ], query => QNONE },
            { args => [ FLOAT( '<x/y>' ) ],               query => QNONE },
            { args => ['fit'],                            query => QNONE },
        ],

        [
            [ REWRITE( 'abs' => 'to' ) ],
            { args => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ], query => QNONE },
            { args => [ FLOAT( '<x/y>' ) ],               query => QNONE },
        ],

        [
            [ EPHEMERAL( 'rel' ) ],
            { args => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ], query => QNONE },
            { args => [ FLOAT( '<x/y>' ) ],               query => QNONE },
        ],

        [ [ REWRITE( '0' => 'to fit' ) ], { query => QNONE }, ],

        [ [ REWRITE( tofit => 'to fit' ) ], { query => QNONE }, ],

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [ ['lock'], { args => [BOOL] } ],

        [ ['match'], { query => QNONE } ],

        [
            [],
            { args  => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ], query => QNONE },
            { args  => [ FLOAT( '<x/y>' ) ],               query => QNONE },
            { rvals => [ARRAY],                            query => QONLY },
        ],

    ],

    #------------------------------------------------------>

    catalog => TODO,

    #------------------------------------------------------

    cd => [ [ [], { args => [STRING] } ] ],


    #------------------------------------------------------

    cmap => [
        [ ['file'], { args => [FILENAME] } ],

        [ [ ENUM( 'load', 'save' ) ], { args => [FILENAME], query => QNONE } ],

        [ [ 'tag', 'delete' ], { query => QNONE } ],

        [ [ 'tag', ENUM( 'load', 'save' ) ], { args => [FILENAME], query => QNONE } ],

        [ ['invert'], { args => [BOOL] } ],

        [ ['value'], { args => [ FLOAT( '<contrast>' ), FLOAT( '<brightness>' ) ] } ],

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [ [], { args => [ STRING( '<name>' ) ] } ],
    ],

    #------------------------------------------------------

    colorbar => [
        [ ['numerics'],   { args => [BOOL] }, ],
        [ ['space'],      { args => [ ENUM( 'value', 'distance' ) ], rvals => [ STRING( '<space>' ) ], }, ],
        [ ['font'],       { args => [ ENUM( FONTS ) ],               rvals => [ STRING( '<font>' ) ], } ],
        [ ['fontsize'],   { args => [FLOAT] } ],
        [ ['fontweight'], { args => [ ENUM( FONTWEIGHTS ) ], rvals => [ STRING( '<fontweight>' ) ], } ],
        [ ['fontslant'],  { args => [ ENUM( FONTSLANTS ) ],  rvals => [ STRING( '<fontslant>' ) ], } ],
        [
            ['orientation'],
            { args => [ ENUM( COLORBAR_ORIENTATIONS ) ], rvals => [ STRING( '<orientation>' ) ], },
        ],
        [ ['size'],  { args => [INT] } ],
        [ ['ticks'], { args => [INT] } ],
        [
            ['lock'],
            { args  => [ EPHEMERAL( 'state' ) ], rvals => [BOOL], query => QARGS },
            { args  => [BOOL], query => QNONE },
            { query => QNONE },
        ],
        [ [ ENUM( COLORBAR_ORIENTATIONS ) ], { query => QNONE } ],
        [ ['match'],                         { query => QNONE } ],

        [ [], { args => [BOOL] }, ],

    ],

    #------------------------------------------------------>

    console => TODO,

    #------------------------------------------------------

    contour => [

        [ [ COORDSYS, SKYFRAME ], { rvals => [STRING] } ],

        [ [COORDSYS], { rvals => [STRING] } ],

        [ [ ENUM( 'copy', 'clear', 'generate', 'open', 'close' ) ], { query => QNONE } ],

        [ ['dash'], { args => [BOOL] } ],

        [ ['color'] => { args => [COLOR] } ],

        [ ['width'] => { args => [INT] } ],

        [ ['smooth'] => { args => [INT] } ],

        [
            ['mode'],
            { args => [ ENUM( qw( minmax zscale zmax ) ) ], rvals => [ STRING( '<mode>' ) ], },
            { args => [FLOAT] },
        ],

        [ ['nlevels'] => { args => [INT] } ],

        [ ['convert'] => { query => QNONE } ],

        [ ['scope'] => { args => [ ENUM( 'global', 'local' ) ], rvals => [ STRING( '<scope>' ) ], } ],

        [
            ['scale'] => { args => [ ENUM( CONTOUR_SCALES, \'<scale>' ) ], rvals => [ STRING( '<scale>' ) ], },
        ],

        [ [ 'log', 'exp' ] => { args => [FLOAT] } ],

        [ ['method'] => { args => [ ENUM( 'block', 'smooth' ) ], rvals => [ STRING( '<method>' ) ], } ],

        [ ['limits'] => { args => [ FLOAT, FLOAT ] } ],

        # TODO: this needs to check for float values
        [ ['levels'] => { args => [ARRAY] } ],

        [ [ 'save', 'levels' ] => { args => [FILENAME], query => QNONE } ],
        [ [ 'load', 'levels' ] => { args => [FILENAME], query => QNONE } ],

        [ ['paste'], { args => [ COORDSYS, COLOR, FLOAT, BOOL ], query => QNONE }, { query => QNONE }, ],

        [
            ['save'],
            { args => [ FILENAME, COORDSYS ], query => QNONE },
            { args => [ FILENAME, COORDSYS, SKYFRAME ], query => QNONE },
        ],

        [ ['load'], { args => [FILENAME], query => QNONE }, ],

        [ [], { args => [BOOL] }, ],

    ],


    #------------------------------------------------------

    crop => TODO,

    #------------------------------------------------------

    crosshair => [ [
            ['match'],
            {
                args =>
                  [ ENUM( SKY_COORD_SYSTEMS, FRAME_COORD_SYSTEMS, \'SKY_COORD_SYSTEMS | FRAME_COORD_SYSTEMS' ) ],
                query => QNONE,
            },
        ],

        [ ['lock'], { args => [COORDSYS] }, { args => ['none'], query => QNONE }, ],

        [
            [],
            {
                rvals => [ STRING( '<ra>' ), STRING( '<dec>' ) ],
                query => QONLY,
            },

            {
                args  => [COORDSYS],
                query => QARGS,
                rvals => [ STRING( '<ra>' ), STRING( '<dec>' ) ],
            },

            {
                args  => [ COORDSYS, SKYFORMAT ],
                query => QARGS,
                rvals => [ STRING( '<ra>' ), STRING( '<dec>' ) ],
            },

            {
                args  => [ COORDSYS, SKYFRAME ],
                query => QARGS,
                rvals => [ STRING( '<ra>' ), STRING( '<dec>' ) ],
            },

            {
                args  => [ COORDSYS, SKYFRAME, SKYFORMAT ],
                query => QARGS,
                rvals => [ STRING( '<ra>' ), STRING( '<dec>' ) ],
            },

            {
                args  => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS ],
                query => QNONE,
            },

            {
                args  => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFRAME ],
                query => QNONE,
            },
        ],

    ],

    #------------------------------------------------------

    cube => [ [
            # [play|stop|next|prev|first|last]
            [ ENUM( \'CUBE_CONTROLS', CUBE_CONTROLS ) ],
            { query => QNONE },
        ],

        # [<slice> [<coordsys>]]
        [ ['slice'], { args => [INT], query => QNONE }, { args => [ FLOAT, WCSS ], query => QNONE }, ],

        # [interval <numeric>]
        [ ['interval'], { args => [FLOAT] }, ],

        # [match <coordsys>]
        [ ['match'], { args => [ ENUM( \'CUBE_COORD_SYSTEMS', CUBE_COORD_SYSTEMS ) ], query => QNONE } ],

        # [lock <coordsys>|none]
        [ ['lock'], { args => [ ENUM( \q{(CUBE_COORD_SYSTEMS | 'none')}, CUBE_COORD_SYSTEMS, 'none' ) ] } ],

        [
            # [axes lock [yes|no]]
            [ 'axes', 'lock' ],
            { args => [BOOL] },
        ],

        [
            # [axis <axis>]
            ['axis'],
            { args => [INT] },
        ],

        [
            # [order 123|132|213|231|312|321]
            ['order'],
            { args => [ ENUM( \'CUBE_ORDERS', CUBE_ORDERS ) ] },
        ],

        [ [ ENUM( \'WCS', WCS, 'wcs' ) ], { rvals => [BOOL], query => QONLY, }, ],

        [
            # [open|close]
            [ ENUM( 'open', 'close' ) ], { query => QNONE },
        ],

        [ [], ],

    ],



    #------------------------------------------------------

    cursor => [ [ [], { args => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ], query => QNONE } ] ],

    #------------------------------------------------------

    data => TODO,

    #------------------------------------------------------

    # aliased to dss; see %CmdAlias below

    dsssao => [
        [ ['size'], { args => [ FLOAT( '<x>' ), FLOAT( '<y>' ), ANGLE_UNIT ] } ],

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [ ['save'], { args => [BOOL] } ],

        [
            ['frame'],
            { args  => [ ENUM( 'new', 'current' ) ], query => QNONE },
            { query => QONLY,                        rvals => [STRING] },
        ],

        [ ['update'], { args => [ ENUM( 'frame', 'crosshair' ) ], query => QNONE } ],

        [ ['name'], { args => [STRING] } ],

        [
            ['coord'],
            {
                args  => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ) ],
                rvals => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), STRING ]
                ,    # 8.4.1 returns <ra> <dec> <"sexagesimal">
            },
        ],

        [
            [],
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ) ], query => QNONE },
            { args => [STRING] },
        ],


    ],

    #------------------------------------------------------

    dsseso => [ [
            ['survey'],
            { args => [ ENUM( \'DSS_ESO_SURVEYS', DSS_ESO_SURVEYS ) ], rvals => [ STRING( '<survey>' ) ], },
        ],

        [ ['size'], { args => [ FLOAT( '<x>' ), FLOAT( '<y>' ), ANGLE_UNIT ] } ],

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [ ['save'], { args => [BOOL] } ],

        [
            ['frame'],
            { args  => [ ENUM( 'new', 'current' ) ], query => QNONE },
            { query => QONLY,                        rvals => [STRING] },
        ],

        [ ['update'], { args => [ ENUM( 'frame', 'crosshair' ) ], query => QNONE } ],

        [ ['name'], { args => [STRING] } ],

        [
            ['coord'],
            {
                args  => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ) ],
                rvals => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), STRING ]
                ,    # 8.4.1 returns <ra> <dec> <"sexagesimal">
            },
        ],

        [
            [],
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ) ], query => QNONE },
            { args => [STRING] },
        ],

    ],

    #------------------------------------------------------

    dssstsci => [ [
            ['survey'],
            { args => [ ENUM( \'DSS_STSCI_SURVEYS', DSS_STSCI_SURVEYS ) ], rvals => [ STRING( '<survey>' ) ] },
        ],

        [ ['size'], { args => [ FLOAT( '<x>' ), FLOAT( '<y>' ), ANGLE_UNIT ] } ],

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [ ['save'], { args => [BOOL] } ],

        [
            ['frame'],
            { args  => [ ENUM( 'new', 'current' ) ], query => QNONE },
            { query => QONLY,                        rvals => [STRING] },
        ],

        [ ['update'], { args => [ ENUM( 'frame', 'crosshair' ) ], query => QNONE } ],

        [ ['name'], { args => [STRING] } ],

        [
            ['coord'],
            {
                args  => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ) ],
                rvals => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), STRING ]
                ,    # 8.4.1 returns <ra> <dec> <"sexagesimal">
            },
        ],

        [
            [],
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ) ], query => QNONE },
            { args => [STRING] },
        ],

    ],

    #------------------------------------------------------

    envi => TODO,

    #------------------------------------------------------

    exit => [ [ [], { query => QNONE } ], ],

    #------------------------------------------------------

    export => [

        [
            [ ENUM( 'array', 'nrrd' ) ],
            {
                args  => [ FILENAME, ENUM( ENDIANNESS ) ],
                query => QNONE,
            },
            {
                args  => [FILENAME],
                query => QNONE,
            },
        ],

        [
            ['envi'],
            {
                args  => [ STRING, STRING, ENUM( ENDIANNESS ) ],
                query => QNONE,
            },
            {
                args  => [FILENAME],
                query => QNONE,
            },

        ],

        [ ['jpeg'], { args => [ FILENAME, INT( '<quality>' ) ], query => QNONE }, ],

        [
            ['tiff'],
            { args => [ FILENAME, ENUM( EXPORT_TIFF_ARGS ) ], query => QNONE },
            { args => [FILENAME],                             query => QNONE },
        ],

        [ [ ENUM( 'gif', 'png' ) ], { args => [FILENAME], query => QNONE } ],

    ],

    #------------------------------------------------------

    fade => TODO,

    #------------------------------------------------------

    file => [

        [ [], { query => QONLY, rvals => [STRING] }, ],

    ],

    #------------------------------------------------------

    fits => [

        [
            [ ENUM( 'width', 'height', 'depth', 'bitpix' ) ],
            {
                rvals => [INT],
                query => QONLY,
            },
        ],

        [
            ['size'],
            {
                args  => [ ENUM( \'WCS', 'wcs', WCS ), SKYFRAME, ANGLE_UNIT ],
                rvals => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ],
                query => QARGS,
            },
            {
                args  => [ ENUM( \'WCS', 'wcs', WCS ), ANGLE_UNIT ],
                rvals => [ FLOAT( '<x>' ),             FLOAT( '<y>' ) ],
                query => QARGS,
            },
            { args  => [ SKYFRAME, ANGLE_UNIT ], rvals => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ], query => QARGS },
            { args  => [ANGLE_UNIT], rvals => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ], query => QARGS },
            { rvals => [ FLOAT( '<x>' ), FLOAT( '<y>' ) ], query => QARGS },
        ],

        [
            ['header'],
            { args  => [ INT, 'keyword', STRING ], rvals => [STRING], query => QARGS },
            { args  => [ 'keyword', STRING ],      rvals => [STRING], query => QARGS },
            { args  => [INT],                      rvals => [STRING], query => QARGS },
            { rvals => [STRING],                   query => QONLY },
        ],

        [ [ ENUM( 'image', 'table', 'slice' ) ], { rvals => [STRING], query => QONLY }, ],

        [
            [],

            # open file with optional extname, filter, bin
            {
                args  => [FILENAME],
                query => QNONE,
                attrs => [
                    new     => BOOL,
                    mask    => BOOL,
                    extname => STRING,
                    filter  => STRING_STRIP,
                    bin     => ARRAY( 1, 2 ),
                ],
            },

            # send an existing fits file as a scalarref
            {
                args  => [ SCALARREF( '\$buffer' ) ],
                attrs => [
                    new     => BOOL,
                    mask    => BOOL,
                    extname => STRING,
                    filter  => STRING_STRIP,
                    bin     => ARRAY( 1, 2 ),
                ],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                retref => 1,
                chomp  => 0,
            },

            # return a fits file of some sort
            { query => QONLY },
        ],
    ],

    #------------------------------------------------------>

    footprint => TODO,
    fp        => TODO,

    #------------------------------------------------------

    frame => [

        [ [ ENUM( 'all', 'active' ) ], { query => QONLY, rvals => [ARRAY], retref => 1 } ],

        # [first|next|prev|last]

        [ [ ENUM( FRAME_SELECTIONS ) ], { query => QNONE } ],

        # [new]
        # [new [rgb|3d]]
        [ ['new'], { args => [ ENUM( 'rgb', '3d' ) ], query => QNONE }, { query => QNONE }, ],

        # [center [#|all]]
        # [clear [#|all]]
        # [delete [#|all]]
        # [reset [#|all]]
        # [refresh [#|all]]
        # [hide [#|all]]
        # [show [#|all]]
        [
            [ ENUM( 'center', 'clear', 'delete', 'reset', 'refresh', 'hide', 'show' ) ],
            { query => QNONE },
            { args  => [INT],   query => QNONE },
            { args  => ['all'], query => QNONE },
        ],
        [ [ REWRITE( 'deleteall', 'delete all' ) ], { query => QNONE } ],

        # [move first]
        # [move back]
        # [move forward]
        # [move last]

        [ ['move'], { args => [ ENUM( FRAME_MOVES ) ], query => QNONE } ],

        # [frameno]
        [ ['frameno'], { args => [INT] }, ],

        # [match <coordsys>]
        [ ['match'], { args => [COORDSYS], query => QNONE }, ],

        # [lock <coordsys|none]
        [ ['lock'], { args => [COORDSYS] }, { args => ['none'] }, ],


        # [has contour [aux]]]
        [
            [ 'has', 'contour' ],
            { args  => ['aux'], query => QARGS, rvals => [BOOL] },
            { query => QONLY,   rvals => [BOOL] },
        ],

        # [has fits [bin|cube|mosaic]]
        [
            [ 'has', 'fits' ],
            { args => [ ENUM( 'bin', 'cube', 'mosaic' ) ], query => QARGS, rvals => [BOOL] },
            { query => QONLY, rvals => [BOOL] },
        ],


        # [has marker [highlite|paste|select|undo]]
        [
            [ 'has', 'marker' ],
            { args => [ ENUM( 'highlite', 'paste', 'select', 'undo' ) ], query => QARGS, rvals => [BOOL] },
        ],

        # [has system <coordsys>]
        [ [ 'has', 'system' ], { args => [COORDSYS], query => QARGS, rvals => [BOOL] }, ],

        # [has wcs [<wcssys>]]
        # [has wcs celestial [<wcssys>]]
        # [has wcs linear [<wcssys>]]

        [
            [ 'has', 'wcs' ],
            {
                args  => [WCSS],
                query => QARGS,
                rvals => [BOOL],
            },
            { args  => [ ENUM( 'linear', 'celestial' ), WCSS ], query => QARGS, rvals => [BOOL] },
            { args  => [ ENUM( 'linear', 'celestial' ), ],      query => QARGS, rvals => [BOOL] },
            { query => QONLY, rvals => [BOOL] },
        ],

        # NOTE: this must appear after all of the other 'has' entries, as
        # it'll treat any 'has' command as having no subcommands [has
        # [amplifier|datamin|datasec|detector|grid|iis|irafmin|physical|smooth]]
        [
            ['has'],
            { args => [ ENUM( \'FRAME_COMPONENTS', FRAME_COMPONENTS ) ], query => QARGS, rvals => [BOOL] },
        ],

        [ [], { args => [INT], query => QNONE }, { query => QONLY, rvals => [INT] }, ],

    ],


    #------------------------------------------------------

    gif => [ [
            [ ENUM( 'new', 'slice' ) ],
            {
                args  => [FILENAME],
                query => QNONE,
            },

            # send an existing image as a scalarref
            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },
        ],

        [
            [],

            # load image from file
            { args => [FILENAME], query => QNONE },

            # return image in buffer
            { rvals => [STRING], query => QONLY },

            # send => load image from buffer
            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },
        ],
    ],

    #------------------------------------------------------>

    graph => TODO,

    #------------------------------------------------------

    grid => [

        [ ['type'],   { args => [ ENUM( 'analysis', 'publication' ) ], rvals => [ STRING( '<type>' ) ], } ],
        [ ['system'], { args => [COORDSYS], } ],
        [ ['sky'],    { args => [SKYFRAME], } ],
        [ ['skyformat'], { args => [SKYFORMAT] } ],

        [ [ 'grid', 'color' ],                        { args => [COLOR] } ],
        [ [ 'grid', 'width' ],                        { args => [INT] } ],
        [ [ 'grid', 'dash' ],                         { args => [BOOL] } ],
        [ [ 'grid', ENUM( 'gap1', 'gap2', 'gap3' ) ], { args => [FLOAT] } ],
        [ ['grid'], { args => [BOOL] }, ],

        [ [ 'axes', 'color' ], { args => [COLOR] } ],
        [ [ 'axes', 'width' ], { args => [INT] } ],
        [ [ 'axes', 'dash' ],  { args => [BOOL] } ],
        [
            [ 'axes', 'type' ],
            { args => [ ENUM( 'internal', 'external' ) ], rvals => [ STRING( '<type>' ) ], },
        ],
        [
            [ 'axes', 'origin' ],
            {
                args  => [ ENUM( \'ORIGIN', 'lll', 'llu', 'lul', 'luu', 'ull', 'ulu', 'uul', 'uuu' ) ],
                rvals => [ STRING( '<origin>' ) ],
            },
        ],
        [ ['axes'], { args => [BOOL] }, ],

        [ [ ENUM( 'format1', 'format2' ) ], { args => [STRING] } ],

        [ [ 'tickmarks', 'color' ], { args => [COLOR] } ],
        [ [ 'tickmarks', 'width' ], { args => [INT] } ],
        [ [ 'tickmarks', 'dash' ],  { args => [BOOL] } ],
        [ ['tickmarks'], { args => [BOOL] }, ],

        [ [ 'border', 'color' ], { args => [COLOR] } ],
        [ [ 'border', 'width' ], { args => [INT] } ],
        [ [ 'border', 'dash' ],  { args => [BOOL] } ],
        [ ['border'], { args => [BOOL] }, ],

        [ [ 'numerics', 'font' ],     { args => [ ENUM( FONTS ) ], rvals => [ STRING( '<font>' ) ], } ],
        [ [ 'numerics', 'fontsize' ], { args => [FLOAT] } ],
        [
            [ 'numerics', 'fontweight' ],
            { args => [ ENUM( FONTWEIGHTS ) ], rvals => [ STRING( '<fontweight>' ) ], },
        ],
        [
            [ 'numerics', 'fontslant' ],
            { args => [ ENUM( FONTSLANTS ) ], rvals => [ STRING( '<fontslant>' ) ], },
        ],
        [ [ 'numerics', 'color' ],                        { args => [COLOR] } ],
        [ [ 'numerics', ENUM( 'gap1', 'gap2', 'gap3' ) ], { args => [FLOAT] } ],
        [
            [ 'numerics', 'type' ],
            { args => [ ENUM( 'internal', 'external' ) ], rvals => [ STRING( '<type>' ) ], },
        ],
        [ [ 'numerics', 'vertical' ], { args => [BOOL] }, ],
        [ ['numerics'],               { args => [BOOL] }, ],

        [ [ 'title', 'text' ],     { args => [STRING] }, ],
        [ [ 'title', 'def' ],      { args => [BOOL] }, ],
        [ [ 'title', 'gap' ],      { args => [FLOAT] } ],
        [ [ 'title', 'font' ],     { args => [ ENUM( FONTS ) ], rvals => [ STRING( '<font>' ) ], } ],
        [ [ 'title', 'fontsize' ], { args => [FLOAT] } ],
        [
            [ 'title', 'fontweight' ],
            { args => [ ENUM( FONTWEIGHTS ) ], rvals => [ STRING( '<fontweight>' ) ], },
        ],
        [
            [ 'title', 'fontslant' ],
            { args => [ ENUM( FONTSLANTS ) ], rvals => [ STRING( '<fontslants>' ) ], },
        ],
        [ [ 'title', 'color' ], { args => [COLOR] } ],
        [ ['title'],            { args => [BOOL] }, ],


        [ [ 'labels', 'font' ], { args => [ ENUM( FONTS ) ], rvals => [ STRING( '<font>' ) ], } ],
        [ [ 'labels', ENUM( 'def1', 'def2' ) ],   { args => [BOOL] }, ],
        [ [ 'labels', ENUM( 'text1', 'text2' ) ], { args => [STRING] }, ],
        [ [ 'labels', ENUM( 'gap1', 'gap2' ) ],   { args => [FLOAT] } ],
        [ [ 'labels', 'fontsize' ],               { args => [FLOAT] } ],
        [
            [ 'labels', 'fontweight' ],
            { args => [ ENUM( FONTWEIGHTS ) ], rvals => [ STRING( '<fontweight>' ) ], },
        ],
        [
            [ 'labels', 'fontslant' ],
            { args => [ ENUM( FONTSLANTS ) ], rvals => [ STRING( '<fontslant>' ) ], },
        ],
        [ [ 'labels', 'color' ], { args => [COLOR] } ],
        [ ['labels'],            { args => [BOOL] }, ],

        [ ['reset'], { query => QNONE } ],

        [ ['load'], { args => [FILENAME], query => QNONE }, ],

        [ ['save'],                    { args  => [FILENAME], query => QNONE }, ],
        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [ [], { args => [BOOL] } ],

    ],

    #------------------------------------------------------

    header => [

        [ ['close'], { args => [INT], query => QNONE }, { query => QNONE }, ],

        [
            ['save'], { args => [ INT, FILENAME ], query => QNONE }, { args => [FILENAME], query => QNONE },
        ],

        [ [], { args => [INT], query => QNONE }, { query => QNONE }, ],
    ],


    #------------------------------------------------------

    height => [ [ [], { args => [INT] } ] ],


    #------------------------------------------------------

    iconify => [ [ [], { args => [BOOL] } ], ],

    #------------------------------------------------------>

    ixem => TODO,

    #------------------------------------------------------>

    iis => TODO,

    #------------------------------------------------------>

    illustrate => TODO,

    #------------------------------------------------------>

    jpeg => [

        [
            [ ENUM( 'new', 'slice' ) ],
            {
                args  => [STRING],
                query => QNONE,
            },

            # send an existing image as a scalarref
            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },
        ],

        [
            [],

            # return image in buffer needs to be before
            # args=>[STRING], as a STRING will swallow the INT
            { args => [INT], rvals => [STRING], query => QARGS },

            # load image from file
            { args => [FILENAME], query => QNONE },

            # send => load image from buffer
            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },

            { rvals => [STRING], query => QONLY },

        ],
    ],

    #------------------------------------------------------>

    lock => [

        [
            [ ENUM( 'frame', 'crosshair', 'crop', 'slice' ) ],
            { args => [COORDSYS] },
            { args => ['none'], query => QNONE },
        ],

        [
            [ ENUM( 'bin', 'axes', 'scale', 'scalelimits', 'colorbar', 'block', 'smooth', '3d' ) ],
            { args => [BOOL] },
        ],

    ],

    #------------------------------------------------------

    lower => [ [ [], { query => QNONE } ], ],


    #------------------------------------------------------>

    magnifier => TODO,

    #------------------------------------------------------>

    mask => [
        [ ['color'], { args => [COLOR] } ],
        [
            ['mark'],
            {
                args  => [ ENUM( \'MARK', 'zero', 'nonzero', 'nan', 'nonnan', 'range' ) ],
                rvals => [ STRING( '<mark>' ) ],
            },
        ],
        [ ['range'],        { args => [ FLOAT( '<low>' ), FLOAT( '<high>' ) ] } ],
        [ ['transparency'], { args => [FLOAT] } ],
        [
            ['blend'],
            { args => [ ENUM( 'source', 'screen', 'darken', 'lighten' ) ], rvals => [ STRING( '<blend>' ) ] },
        ],
        [ ['system'],                  { args  => [COORDSYS] }, ],
        [ ['clear'],                   { query => QNONE }, ],
        [ ['load'],                    { args  => [FILENAME], query => QNONE }, ],
        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

    ],

    #------------------------------------------------------>

    match => [
        [ [ ENUM( 'frame', 'crosshair', 'crop', 'slice' ) ], { args => [COORDSYS], query => QNONE } ],

        [
            [ ENUM( 'bin', 'axes', 'scale', 'scalelimits', 'colobar', 'block', 'smooth', '3d' ) ],
            { query => QNONE },
        ],

    ],

    #------------------------------------------------------>

    mecube => TODO,

    #------------------------------------------------------

    minmax => [

        [ ['mode'], { args => [ ENUM( MINMAX_MODES ) ], rvals => [ STRING( '<mode>' ) ], } ],

        [ ['interval'], { args => [INT] } ],

        [ ['rescan'], { query => QNONE }, ],

        [ [], { args => [ ENUM( MINMAX_MODES ) ], rvals => [ STRING( '<mode>' ) ], } ],

    ],

    #------------------------------------------------------

    mode => [ [
            [],
            {
                args  => [ ENUM( \'MOUSE_BUTTON_MODES', MOUSE_BUTTON_MODES ) ],
                rvals => [ STRING( '<modes>' ) ],
            },
        ],
    ],

    #------------------------------------------------------>

    mosaic => [

        [
            [],
            {
                args   => [ SCALARREF, ENUM( 'wcs', 'iraf', WCS ), ENUM( 'new', 'mask' ) ],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },
            {
                args   => [ SCALARREF, ENUM( 'wcs', 'iraf', WCS ) ],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },

            { args => [ ENUM( 'wcs', 'iraf', WCS ), ENUM( 'new', 'mask' ), FILENAME ], query => QNONE },
            { args => [ ENUM( 'wcs', 'iraf', WCS ), FILENAME ],                        query => QNONE },
            { args => [FILENAME],                                                      query => QNONE },

            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },
            { query => QONLY, retref => 1 },
        ],

    ],

    #------------------------------------------------------>

    mosaicimage => [

        [
            [],
            {
                args   => [ SCALARREF, ENUM( 'wcs', 'iraf', 'wfpc2', WCS ), ENUM( 'new', 'mask' ) ],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },
            {
                args   => [ SCALARREF, ENUM( 'wcs', 'iraf', 'wfpc2', WCS ) ],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },

            {
                args  => [ ENUM( 'wcs', 'iraf', 'wfpc2', WCS ), ENUM( 'new', 'mask' ), FILENAME ],
                query => QNONE,
            },
            { args => [ ENUM( 'wcs', 'iraf', 'wfpc2', WCS ), FILENAME ], query => QNONE },
            { args => [FILENAME],                                        query => QNONE },

            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },
        ],

    ],

    #------------------------------------------------------>

    movie => TODO,

    #------------------------------------------------------>

    multiframe => TODO,

    #------------------------------------------------------

    nameserver => [

        [ ['name'], { args => [STRING] } ],

        [
            ['server'],
            { args => [ ENUM( \'NAMESERVERS', NAMESERVERS ) ], rvals => [ STRING( '<nameserver>' ) ], },
        ],

        [ ['skyformat'], { args => [SKYFORMAT] } ],

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [ [], { args => [STRING] } ],

    ],

    #------------------------------------------------------>

    notes => TODO,


    #------------------------------------------------------

    nrrd => TODO,

    #------------------------------------------------------>

    nvss => TODO,

    #------------------------------------------------------

    orient => [
        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],
        [ [], { args => [ ENUM( 'none', 'x', 'y', 'xy' ) ], rvals => [ STRING( '<orientation>' ) ], }, ],
    ],

    #------------------------------------------------------

    pagesetup => [

        [ ['orient'], { args => [ ENUM( PAGE_ORIENTATIONS ) ], rvals => [ STRING( '<orient>' ) ], } ],

        [ ['scale'], { args => [FLOAT], } ],

        [ ['size'], { args => [ ENUM( \'PAGE_SIZES', PAGE_SIZES ) ], rvals => [ STRING( '<size>' ) ], } ],

    ],


    #------------------------------------------------------

    pan => [
        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [
            ['to'],
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ) ],                      query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS ],            query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFORMAT ], query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFRAME ],  query => QNONE },
            {
                args  => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFRAME, SKYFORMAT ],
                query => QNONE,
            },
        ],

        [
            [ REWRITE( 'abs', 'to' ) ],
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ) ],                      query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS ],            query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFORMAT ], query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFRAME ],  query => QNONE },
            {
                args  => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFRAME, SKYFORMAT ],
                query => QNONE,
            },
        ],

        [
            [ EPHEMERAL( 'rel' ) ],
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ) ],                      query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS ],            query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFORMAT ], query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFRAME ],  query => QNONE },
            {
                args  => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFRAME, SKYFORMAT ],
                query => QNONE,
            },
        ],

        [
            [],
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ) ],                      query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS ],            query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFORMAT ], query => QNONE },
            { args => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFRAME ],  query => QNONE },
            {
                args  => [ COORD_RA( '<ra>' ), COORD_DEC( '<dec>' ), COORDSYS, SKYFRAME, SKYFORMAT ],
                query => QNONE,
            },

            {
                rvals => [ STRING, STRING ],
                cvt   => 0,
            },

            {
                args  => [ COORDSYS, SKYFORMAT ],
                query => QARGS,
                rvals => [ STRING, STRING ],
                cvt   => 0,
            },

            {
                args  => [ COORDSYS, SKYFRAME, SKYFORMAT ],
                query => QARGS,
                rvals => [ STRING, STRING ],
                cvt   => 0,
            },

            {
                args  => [ COORDSYS, SKYFRAME ],
                query => QARGS,
                rvals => [ STRING, STRING ],
                cvt   => 0,
            },

            {
                args  => [COORDSYS],
                query => QARGS,
                rvals => [ STRING, STRING ],
                cvt   => 0,
            },


        ],

    ],

    #------------------------------------------------------

    pixeltable => [ [ [], { args => [ ENUM( 'open', 'close' ) ] }, { args => [BOOL] }, ], ],

    #------------------------------------------------------>

    plot => TODO,

    #------------------------------------------------------

    png => [ [
            [ ENUM( 'new', 'slice' ) ],
            {
                args  => [STRING],
                query => QNONE,
            },

            # send an existing image as a scalarref
            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },
        ],

        [
            [],

            # load image from file
            { args => [FILENAME], query => QNONE },

            # return image in buffer
            { rvals => [STRING], query => QONLY },

            # send => load image from buffer
            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },
        ],
    ],

    #------------------------------------------------------>

    prefs => TODO,

    #------------------------------------------------------

    preserve => [ [ [ ENUM( 'pan', 'regions' ) ], { args => [BOOL] }, ], ],

    #------------------------------------------------------>

    # ALIASED BELOW: psprint

    #------------------------------------------------------

    print => [

        [
            ['destination'],
            { args => [ ENUM( PRINT_DESTINATIONS ) ], rvals => [ STRING( '<destination>' ) ], },
        ],

        [ ['command'], { args => [STRING] }, ],

        [ ['filename'], { args => [STRING] }, ],

        [ ['color'], { args => [ ENUM( PRINT_COLORS ) ], rvals => [ STRING( '<color>' ) ], }, ],

        [ ['level'], { args => [ ENUM( PRINT_LEVELS ) ], rvals => [ INT( '<level>' ) ], }, ],

        [
            ['resolution'],
            {
                args  => [ ENUM( \'PRINT_RESOLUTIONS', PRINT_RESOLUTIONS ) ],
                rvals => [ STRING( '<resolution>' ) ],
            },
        ],

        [ [], { query => QNONE } ],

    ],

    #------------------------------------------------------>

    prism => TODO,

    #------------------------------------------------------

    quit => [ [ [], { query => QNONE }, ] ],


    #------------------------------------------------------

    raise => [ [ [], { query => QNONE }, ] ],


    #------------------------------------------------------

    region => [

        [ [ ENUM( qw( movefront moveback selectall selectnone deleteall ) ) ], { query => QNONE }, ],


        [ [ ENUM( qw( load save ) ) ], { args => [FILENAME], query => QNONE }, ],

        [
            ['format'],
            { args => [ ENUM( \'REGION_FORMATS', REGION_FORMATS ) ], rvals => [ STRING( '<format>' ) ], },
        ],

        [ ['system'], { args => [COORDSYS] }, ],

        [ ['sky'], { args => [SKYFRAME] }, ],

        [ ['skyformat'], { args => [SKYFORMAT] }, ],

        [ ['strip'], { args => [BOOL] }, ],

        [ [ ENUM( qw(source background include exclude selected) ) ], { query => QONLY } ],

        [ ['shape'], { args => [STRING] } ],

        [ ['width'], { args => [INT] } ],

        [ ['color'], { args => [COLOR] } ],


        [
            [],
            {
                args   => [STRING_NL],
                query  => QNONE,
                bufarg => 1,
            },
            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
            },
            {
                # not sure what this combination of flags is supposed to mean.
                query => QYES | QONLY | QATTR,
                rvals => [STRING],
                attrs => [
                    -format    => ENUM( \'REGION_FORMATS', REGION_FORMATS ),
                    -system    => COORDSYS,
                    -sky       => SKYFRAME,
                    -skyformat => SKYFORMAT,
                    -strip     => BOOL,
                    -prop      => ENUM( \'REGION_PROPERTIES', REGION_PROPERTIES ),
                ],
            },
        ],

    ],

    #------------------------------------------------------

    restore => [ [ [], { args => [STRING], query => QNONE } ] ],

    #------------------------------------------------------>

    rgb => TODO,

    #------------------------------------------------------>

    rgbarray => TODO,

    #------------------------------------------------------>

    rgbcube => TODO,

    #------------------------------------------------------>

    rgbimage => TODO,

    #------------------------------------------------------

    rotate => [

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [ ['to'], { args => [FLOAT], query => QNONE }, ],

        [ [ REWRITE( 'abs', 'to' ) ], { args => [FLOAT], query => QNONE }, ],

        [ [ EPHEMERAL( 'rel' ) ], { args => [FLOAT], query => QNONE }, ],


        [ [], { args => [FLOAT] }, ],

    ],

    #------------------------------------------------------>

    samp => TODO,

    #------------------------------------------------------

    save => [ [
            [ ENUM( SAVE_FORMATS ) ],
            { args => [ FILENAME, ENUM( 'image', 'table', 'slice' ) ], query => QNONE },
        ],
    ],

    #------------------------------------------------------

    saveimage => [
        [ [JPEG_FILE], { args => [INT], query => QNONE }, ],

        [ [TIFF_FILE], { args => [EXPORT_TIFF_ARGS], query => QNONE }, ],

        [ [ ENUM( SAVE_IMAGE_FORMATS ) ], { args => [FILENAME], query => QNONE }, ],
    ],

    #------------------------------------------------------

    scale => [

        [ [ 'log', 'exp' ] => { args => [FLOAT] } ],

        [ ['datasec'], { args => [BOOL] }, ],

        [ ['limits'], { args => [ FLOAT, FLOAT ] }, ],

        [
            ['mode'],

            { args => [ ENUM( qw( minmax zscale zmax ) ) ], rvals => [ STRING( '<mode>' ) ], },
            { args => [FLOAT] },
        ],

        [ ['scope'], { args => [ ENUM( qw( local global ) ) ], rvals => [ STRING( '<scope>' ) ], }, ],

        [ [ 'match', 'limits' ], { query => QNONE }, ],

        [ ['match'], { query => QNONE }, ],

        [ [ 'lock', 'limits' ], { args => [BOOL] } ],
        [ ['lock'],             { args => [BOOL] } ],

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE }, ],

        [
            [],
            { args => [ ENUM( \'SCALE_FUNCTIONS', SCALE_FUNCTIONS ) ], rvals => [ STRING( '<function>' ) ], },
        ],

    ],

    #------------------------------------------------------>

    shm => TODO,

    #------------------------------------------------------>

    sia => TODO,

    #------------------------------------------------------

    single => [
        [ [ EPHEMERAL( 'state' ) ], { rvals => [BOOL], query => QONLY }, ],

        [ [], { query => QNONE }, ],
    ],

    #------------------------------------------------------>

    skyview => TODO,

    #------------------------------------------------------

    sleep => [ [ [], { args => [INT], query => QNONE }, { query => QNONE }, ], ],

    #------------------------------------------------------

    smooth => [

        [
            ['function'],
            { args => [ ENUM( 'boxcar', 'tophat', 'gaussian' ) ], rvals => [ STRING( '<function>' ) ], },
        ],

        [ [ ENUM( 'radius', 'radiusminor' ) ], { args => [INT] }, ],

        [ [ ENUM( 'sigma', 'sigmaminor', 'angle' ) ], { args => [FLOAT] }, ],

        [ ['match'], { query => QNONE }, ],

        [ ['lock'], { args => [BOOL] } ],

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],

        [ [], { args => [BOOL] }, ],

    ],


    #------------------------------------------------------

    source => [ [ [], { args => [STRING], query => QNONE }, ], ],

    #------------------------------------------------------

    tcl => [ [ [], { args => [STRING], query => QNONE }, ], ],

    #------------------------------------------------------

    threads => [ [ [], { args => [INT] }, ], ],

    #------------------------------------------------------

    tiff => [

        [
            [ ENUM( 'new', 'slice' ) ],
            {
                args  => [STRING],
                query => QNONE,
            },

            # send an existing image as a scalarref
            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },
        ],

        [
            [],

            # return image in buffer needs to be before
            # args=>[STRING], as a STRING will swallow the EXPORT_TIFF_ARGS
            # THIS IS BUGGY.  this means you can't have a file name IN EXPORT_TIFF_ARGS
            # as it's using the value of the first argument to determine if it is a set or a get.
            { args => [ ENUM( EXPORT_TIFF_ARGS ) ], query => QARGS },

            # load image from file
            { args => [FILENAME], query => QNONE },

            # send => load image from buffer
            {
                args   => [SCALARREF],
                query  => QNONE,
                bufarg => 1,
                cvt    => 0,
                chomp  => 0,
            },

            { rvals => [STRING], query => QONLY },

        ],
    ],

    #------------------------------------------------------


    tile => [
        [ ['mode'], { args => [ ENUM( 'grid', 'column', 'row' ) ], rvals => [ STRING( '<mode>' ) ], } ],

        [
            [ 'grid', 'mode' ],
            { args => [ ENUM( 'automatic', 'manual' ) ], rvals => [ STRING( '<mode>' ) ], },
        ],

        [ [ 'grid', 'direction' ], { args => [ ENUM( 'x', 'y' ) ] }, ],

        [ [ 'grid', 'layout' ], { args => [ INT, INT ] }, ],

        [ [ 'grid', 'gap' ], { args => [INT] }, ],

        [ [ ENUM( 'grid', 'row', 'column' ) ], { query => QNONE }, ],

        [ [ EPHEMERAL( 'state' ) ], { rvals => [BOOL], query => QONLY }, ],

        [ [], { args => [BOOL] } ],
    ],

    #------------------------------------------------------

    update => [ [
            ['now'],
            {
                args  => [ INT, FLOAT, FLOAT, FLOAT, FLOAT ],
                query => QNONE,
            },
            {
                query => QNONE,
            },
        ],
        [
            [],
            {
                args  => [ INT, FLOAT, FLOAT, FLOAT, FLOAT ],
                query => QNONE,
            },
            {
                query => QNONE,
            },
        ],

    ],

    #------------------------------------------------------

    url => [ [ [], { args => [STRING], query => QNONE }, ], ],

    #------------------------------------------------------

    version => [ [
            [],
            {
                rvals => [STRING],
                query => QONLY,
            },
        ],
    ],

    #------------------------------------------------------

    view => [

        [
            ['layout'],
            { args => [ ENUM( \'VIEW_LAYOUTS', VIEW_LAYOUTS ) ], rvals => [ STRING( '<layout>' ) ], },
        ],

        [ ['keyvalue'], { args => [STRING] }, ],

        [ [ ENUM( \'VIEW_BOOL_COMPONENTS', VIEW_BOOL_COMPONENTS ) ], { args => [BOOL] }, ],

        [ [ ENUM( RGB_COMPONENTS ) ], { args => [BOOL] }, ],

        [ [ 'graph', ENUM( GRAPH_ORIENTATIONS ) ], { args => [BOOL] }, ],

        [ [COORDSYS], { args => [BOOL] }, ],
    ],

    #------------------------------------------------------>

    vla => TODO,

    #------------------------------------------------------>

    vlss => TODO,

    #------------------------------------------------------

    vo => TODO,

    #------------------------------------------------------

    wcs => [

        [ ['system'], { args => [WCSS] } ],

        [ ['sky'], { args => [SKYFRAME] } ],

        [ ['skyformat'], { args => [SKYFORMAT] } ],

        [ ['align'], { args => [BOOL] } ],

        [ ['reset'], { query => QNONE }, ],

        [ ['load'], { args => [FILENAME], query => QNONE }, ],

        [
            [ ENUM( 'replace', 'append' ) ],
            { args => [WCS_SCALARREF], query => QNONE, bufarg => 1 },
            { args => [WCS_HASH],      query => QNONE, bufarg => 1 },
            { args => [WCS_ARRAY],     query => QNONE, bufarg => 1 },
        ],

        [
            ['save'], { args => [ INT, FILENAME ], query => QNONE }, { args => [FILENAME], query => QNONE },
        ],

        [ [ ENUM( 'open', 'close' ) ], { query => QNONE } ],


        [ [], { args => [WCSS] }, ],

    ],

    #------------------------------------------------------

    web => [
        [ ['new'], { args => [ STRING, STRING ], query => QNONE }, ],

        [ [ STRING, ENUM( 'clear', 'close' ) ], { query => QNONE }, ],

        [
            [ STRING, 'click' ],
            { args => [INT],                                           query => QNONE },
            { args => [ ENUM( 'back', 'forward', 'stop', 'reload' ) ], query => QNONE },
        ],

        [ [], { args => [STRING], query => QNONE }, { query => QONLY }, ],
    ],


    #------------------------------------------------------

    width => [ [ [], { args => [INT] } ] ],

    #------------------------------------------------------

    xpa => [
        [ ['info'],       { query => QONLY } ],
        [ ['disconnect'], { query => QNONE } ],

        [ [], { args => [BOOL_FALSE], query => QNONE }, ],
    ],

    #------------------------------------------------------

    zscale => [
        [ [ ENUM( 'sample', 'line' ) ], { args  => [INT] } ],
        [ [ ENUM( 'contrast' ) ],       { args  => [FLOAT] } ],
        [ [],                           { query => QNONE } ],
    ],

    #------------------------------------------------------

    zoom => [
        [ ['to'], { args => [FLOAT], query => QNONE }, { args => ['fit'], query => QNONE }, ],

        [ [ ENUM( 'in', 'out' ) ], { query => QNONE } ],

        [ [ REWRITE( 'abs' => 'to' ) ], { args => [FLOAT], query => QNONE }, ],

        [ [ EPHEMERAL( 'rel' ) ], { args => [FLOAT], query => QNONE }, ],

        [ [ REWRITE( '0' => 'to fit' ) ], { query => QNONE, comment => q{alias for 'to fit'} }, ],

        [ [ REWRITE( tofit => 'to fit' ) ], { query => QNONE, comment => q{alias for 'to fit'} }, ],

        [ [], { args => [FLOAT] } ],

    ],
);

my %CmdAlias = (
    colormap => 'cmap',
    dss      => 'dsssao',
    file     => 'fits',
    psprint  => 'print',
    regions  => 'region',
);

sub _grammar {
    return defined $_[0]
      ? $Grammar{ $CmdAlias{ $_[0] } // $_[0] }
      : \%Grammar;
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Image::DS9::Grammar::V8_5 - Grammar definitions

=head1 VERSION

version v1.0.0

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
