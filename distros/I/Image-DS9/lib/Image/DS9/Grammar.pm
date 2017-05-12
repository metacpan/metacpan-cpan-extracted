package Image::DS9::Grammar;

use strict;
use warnings;

use Image::DS9::PConsts;

use constant REGIONFORMAT => ENUM( qw( ds9 ciao saotng saoimage pros xy ) );

# TODO:
#  about?
#  analysis
#  shm


our %Grammar =
  (

#------------------------------------------------------

   array =>
   [
    [ 
     [],
     { args => [ PDL ], 
       attrs => [ new    => BOOL ],
       query => QNONE,
       bufarg => 1
     },

     { args => [ SCALARREF ], 
       attrs => [ new    => BOOL,
		  bitpix => INT,
		  skip   => INT,
		  -o => [ ( -a => [ xdim => INT, ydim => INT ] ),
			  ( dim => INT ) ],
		],
       query => QNONE,
       bufarg => 1
     }

    ],

   ],

#------------------------------------------------------

   bin =>
   [ 
    [
     ['about'],
     { args => [ FLOAT, FLOAT ] }
    ],

    [
     ['buffersize'],
     { args => [ INT ] }
    ],

    # cols can take 2 or three arguments.  the current interface
    # doesn't handle this elegantly, so try 3 args first.  it'll
    # always be the one to be queried, so have it return an indeterminate
    # length array (which isn't length checked yet anyway)
    [ 
     ['cols'],
     { args => [ STRING, STRING, STRING ],
       rvals => [ ARRAY ]
     },
     { args => [ STRING, STRING ] }
    ],

    [
     ['factor'],
     { args => [ FLOAT, FLOAT ], rvals => [ ARRAY ] },
     { args => [ FLOAT ], rvals => [ ARRAY ] }
    ],

    [
     ['depth'],
     { args => [ INT ] }
    ],

    [
     ['filter'],
     { args => [ STRING_STRIP ] }
    ],

    [
     ['function'],
     { args => [ ENUM( 'average', 'sum' ) ] }
    ],

    [
     [ REWRITE('tofit', 'to fit') ],
     { query => QNONE }
    ],

    [
     [ 'to fit' ],
     { query => QNONE }
    ],
   ],

#------------------------------------------------------

   blink =>
   [
    [
     [ EPHEMERAL('state') ],
     { rvals => [ BOOL ], query => QONLY },
    ],

    [
     [],
     { query => QNONE },
    ]
   ],


#------------------------------------------------------

   cd =>
   [
    [
     [],
     { args => [STRING] }
    ]
   ],


#------------------------------------------------------

   cmap =>
   [ 
    [
     ['file'],
     { args => [ STRING ] }
    ],

    [
     ['invert'],
     { args => [ BOOL ] }
    ],

    [
     ['value'],
     { args => [ FLOAT, FLOAT ] }
    ],

    [
     [],
     { args => [ STRING ] }
    ],
   ],

#------------------------------------------------------

   contour =>
   [

    [
     ['copy'],
     { query => QNONE }
    ],

    [
     ['paste'],
     { args => [ COORDSYS, SKYFRAME, COLOR, FLOAT ], query => QNONE },
     { args => [ COORDSYS, COLOR, FLOAT ], query => QNONE }
    ],

    [
     ['save'],
     { args => [ STRING, COORDSYS ], query => QNONE },
     { args => [ STRING, COORDSYS, SKYFRAME ], query => QNONE }
    ],

    [
     ['load'],
     { args => [ STRING, COORDSYS, COLOR, FLOAT ], query => QNONE },
     { args => [ STRING, COORDSYS, SKYFRAME, COLOR, FLOAT ], query => QNONE }
    ],

    [
     [],
     { args => [ BOOL ] }
    ],

   ],


#------------------------------------------------------

   crosshair =>
   [
    [
     [],
     { rvals => [STRING, STRING] },

     { args => [ COORDSYS ],
       query => QARGS|QYES,
       rvals => [STRING,STRING] },

     { args => [ COORDSYS, SKYFORMAT ],
       query => QARGS|QYES,
       rvals => [STRING, STRING] },

     { args => [ COORDSYS, SKYFRAME  ],
       query => QARGS|QYES,
       rvals => [STRING, STRING] },

     { args => [ COORDSYS, SKYFRAME, SKYFORMAT ],
       query => QARGS|QYES,
       rvals => [STRING, STRING] },

     { args => [ COORD_RA, COORD_DEC, COORDSYS ],
       query => QNONE,
     },

     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFRAME ],
       query => QNONE,
     }
    ],

   ],

#------------------------------------------------------

   cursor =>
   [
    [
     [],
     { args => [ FLOAT, FLOAT ], query => QNONE }
    ]
   ],

#------------------------------------------------------

   dsssao =>
   [
    [
     ['name'],
     { args => [ STRING ] }
    ],

    [
     ['coord'],
     { args => [ COORD_RA, COORD_DEC ] }
    ],

    [
     ['size'],
     { args => [ FLOAT, FLOAT, ANGLE_UNIT ] }
    ],

    [
     [ 'close' ],
     { query => QNONE } 
    ],

    [
     [ 'open' ],
     { query => QNONE } 
    ],


   ],

#------------------------------------------------------

   dsseso =>
   [
    [
     ['name'],
     { args => [ STRING ] }
    ],

    [
     ['coord'],
     { args => [ COORD_RA, COORD_DEC ] }
    ],

    [
     ['survey'],
     { args => [ ENUM( 'dss', 'dss2-red', 'dss2-blue', 'dss2-infrared' ) ] }
    ],

    [
     ['size'],
     { args => [ FLOAT, FLOAT, ANGLE_UNIT ] }
    ],

    [
     [ 'close' ],
     { query => QNONE } 
    ],

    [
     [ 'open' ],
     { query => QNONE } 
    ],


   ],

#------------------------------------------------------

   dssstsci =>
   [
    [
     ['name'],
     { args => [ STRING ] }
    ],

    [
     ['coord'],
     { args => [ COORD_RA, COORD_DEC ] }
    ],

    [
     ['size'],
     { args => [ FLOAT, FLOAT, ANGLE_UNIT ] }
    ],

    [
     ['survey'],
     { args => [ ENUM( qw{ poss2ukstu_red
			   poss2ukstu_ir
			   poss2ukstu_blue
			   poss1_blue
			   poss1_red
			   all
			   quickv
			   phase2_gsc2
			   phase2_gsc1
		     }
		     )
	       ]
     }
    ],

    [
     [ 'close' ],
     { query => QNONE } 
    ],

    [
     [ 'open' ],
     { query => QNONE } 
    ],

   ],

#------------------------------------------------------

   exit =>
   [
    [ 
     [], 
     { query => QNONE } 
    ],
   ],


#------------------------------------------------------

   file =>
   [

    [ 
     [ENUM('fits', 'mosaic', 'mosaicimage')],
     { args => [ STRING ], 
       attrs => [ new => BOOL ],
       query => QNONE
     }
    ],

    [ 
     ['array'],
     { args => [ STRING ], 
       attrs => [ new    => BOOL,
		  bitpix => INT,
		  skip   => INT,
		  -o => [ [ -a => [ xdim => FLOAT, ydim => FLOAT ] ],
			  [ dim => FLOAT ] ],
		],
       query => QNONE,
     }
    ],

    [ 
     ['url'],
     { args => [ STRING ], 
       attrs => [ new => BOOL ],
       query => QNONE,
     }
    ],

    [ 
     ['save'],
     { args => [ STRING ], 
       query => QNONE,
     }
    ],

    [ 
     ['save', 'gz'],
     { args => [ STRING ], 
       query => QNONE,
     }
    ],

    [ 
     ['save', 'resample'],
     { args => [ STRING ], 
       query => QNONE,
     }
    ],

    [ 
     ['save', 'resample', 'gz'],
     { args => [ STRING ], 
       query => QNONE,
     }
    ],

    [ 
     [],
     { args => [ STRING ], 
       attrs => [ new => BOOL,
		  extname => STRING,
		  filter => STRING_STRIP,
		  bin => ARRAY(1,2),
		],
     }
    ],

   ],

#------------------------------------------------------

   fits =>
   [

    [
     ['mosaic'],
     { args => [ SCALARREF ],
       attrs => [ new => BOOL,
		  extname => STRING,
		  filter => STRING_STRIP,
		  bin => ARRAY(1,2),
		],
       query => QNONE,
       bufarg => 1,
       cvt => 0,
       retref => 1,
       chomp => 0,
     }
    ],

    [
     ['mosaicimage'],
     { args => [ SCALARREF ],
       attrs => [ new => BOOL,
		  extname => STRING,
		  filter => STRING_STRIP,
		  bin => ARRAY(1,2),
		],
       query => QNONE,
       bufarg => 1,
       cvt => 0,
       retref => 1,
       chomp => 0,
     }
    ],

    [
     ['type'],
     { query => QONLY }
    ],

    [
     ['image', 'gz'],
     { query => QONLY,
       cvt => 0,
       rvals => [STRING],
       retref => 1,
       chomp => 0,
     }
    ],

    [
     ['image'],
     { query => QONLY,
       cvt => 0,
       rvals => [STRING],
       retref => 1,
       chomp => 0,
     }
    ],

    [
     ['resample', 'gz'],
     { query => QONLY,
       cvt => 0,
       rvals => [STRING],
       retref => 1,
       chomp => 0,
     }
    ],

    [
     ['resample'],
     { query => QONLY,
       cvt => 0,
       rvals => [STRING],
       retref => 1,
       chomp => 0,
 }
    ],

    [
     [],
     { args => [ SCALARREF ],
       attrs => [ new => BOOL,
		  extname => STRING,
		  filter => STRING_STRIP,
		  bin => ARRAY(1,2),
		],
       query => QYES,
       bufarg => 1,
       cvt => 0,
       retref => 1,
       chomp => 0,
     }
    ],

   ],

#------------------------------------------------------

   frame =>
   [

    [
     ['all'],
     { query => QONLY, rvals => [ ARRAY ], retref => 1 }
    ],

    [
     ['first'],
     { query => QNONE }
    ],

    [
     ['next'],
     { query => QNONE }
    ],

    [
     ['prev'],
     { query => QNONE }
    ],

    [
     ['last'],
     { query => QNONE }
    ],

    [
     ['new', 'rgb'],
     { query => QNONE }
    ],


    [
     ['new'],
     { query => QNONE }
    ],

    [
     ['center'],
     { query => QNONE },
     { args => [ INT ], query => QNONE },
     { args => [ ENUM( 'all' ) ], query => QNONE }
    ],

    [
     ['clear'],
     { query => QNONE },
     { args => [ INT ], query => QNONE },
     { args => [ ENUM( 'all' ) ], query => QNONE }
    ],

    [
     ['delete'],
     { query => QNONE },
     { args => [ INT ], query => QNONE },
     { args => [ ENUM( 'all' ) ], query => QNONE }
    ],

    [
     ['reset'],
     { query => QNONE },
     { args => [ INT ], query => QNONE },
     { args => [ ENUM( 'all' ) ], query => QNONE }
    ],

    [
     ['refresh'],
     { query => QNONE },
     { args => [ INT ], query => QNONE },
     { args => [ ENUM( 'all' ) ], query => QNONE }
    ],

    [
     ['hide'],
     { query => QNONE },
     { args => [ INT ], query => QNONE },
     { args => [ ENUM( 'all' ) ], query => QNONE }
    ],

    [
     ['show'],
     { query => QNONE },
     { args => [ INT ], query => QNONE },
     { args => [ ENUM( 'all' ) ], query => QNONE }

    ],

    [
     ['move'],
     { args => [ ENUM( 'first', 'back', 'forward', 'last' ) ], query => QNONE }
    ],

    [
     ['frameno'],
     { args => [ INT ] },
    ],

    [
     [],
     { args => [ INT ] }
    ],

   ],


#------------------------------------------------------

   grid =>
   [

    [
     ['load'],
     { args => [ STRING ], query => QNONE },
    ],

    [
     ['save'],
     { args => [ STRING ], query => QNONE },
    ],

    [
     [],
     { args => [ BOOL ] }
    ],

   ],

#------------------------------------------------------

   height =>
   [
    [
     [],
     { args => [INT] }
    ]
   ],


#------------------------------------------------------

   iconify =>
   [
    [
     [],
     { args => [ BOOL ] }
    ],
   ],

#------------------------------------------------------

   lower =>
   [
    [
     [],
     { query => QNONE }
    ],
   ],


#------------------------------------------------------

   minmax =>
   [

    [
     ['mode'],
     { args => [ ENUM( 'scan', 'sample', 'datamin', 'irafmin' ) ] }
    ],

    [
     ['interval'],
     { args => [ INT ] }
    ],

    [
     [],
     { args => [ ENUM( 'scan', 'sample', 'datamin', 'irafmin' ) ] }
    ],

   ],

#------------------------------------------------------

   mode =>
   [
    [
     [],
     { args => [ ENUM( qw< none region crosshair colorbar pan zoom rotate catalog examine > ) ],
     }
    ],
   ],

#------------------------------------------------------

   nameserver =>
   [

    [
     ['name'],
     { args => [STRING], query => QNONE }
    ],

    [
     ['server'],
     { args => [ ENUM( 'ned-sao', 'ned-eso', 'simbad-sao', 'simbad-eso' ) ] },
    ],

    [
     ['skyformat'],
     { args => [ SKYFORMAT ] }
    ],

    [
     [ 'close' ],
     { query => QNONE } 
    ],

    [
     [ 'open' ],
     { query => QNONE } 
    ],

    [
     [],
     { args => [STRING], query => QNONE }
    ],

   ],

#------------------------------------------------------

   orient =>
   [
    [
     [],
     { args => [ ENUM( 'none', 'x', 'y', 'xy' ) ] },
    ],
   ],

#------------------------------------------------------

   page =>
   [

    [
     ['setup', 'orientation'],
     { args => [ ENUM( 'portrait', 'landscape' ) ], }
    ],

    [
     ['setup', 'pagescale'],
     { args => [ ENUM( 'scaled', 'fixed' ) ], }
    ],

    [
     ['setup', 'pagesize'],
     { args => [ ENUM( 'letter', 'legal', 'tabloid', 'poster', 'a4' ) ], }
    ],

   ],


#------------------------------------------------------

   pan =>
   [

    [
     [ 'to' ],
     { args => [ COORD_RA, COORD_DEC ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFORMAT ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFRAME  ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFRAME, SKYFORMAT ], 
       query => QNONE },
    ],

    [
     [ REWRITE( 'abs', 'to' ) ],
     { args => [ COORD_RA, COORD_DEC ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFORMAT ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFRAME  ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFRAME, SKYFORMAT ], 
       query => QNONE },
    ],

    [
     [ EPHEMERAL( 'rel' ) ],
     { args => [ COORD_RA, COORD_DEC ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFORMAT ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFRAME  ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFRAME, SKYFORMAT ], 
       query => QNONE },
    ],

    [
     [],
     { args => [ COORD_RA, COORD_DEC ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFORMAT ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFRAME  ], query => QNONE },
     { args => [ COORD_RA, COORD_DEC, COORDSYS, SKYFRAME, SKYFORMAT ],
       query => QNONE },

     { rvals => [STRING, STRING],
       cvt => 0
     },

     { args => [ COORDSYS, SKYFORMAT ],
       query => QONLY,
       rvals => [STRING, STRING],
       cvt => 0
     },

     { args => [ COORDSYS, SKYFRAME, SKYFORMAT ],
       query => QONLY,
       rvals => [STRING, STRING],
       cvt => 0
     },

     { args => [ COORDSYS, SKYFRAME ],
       query => QONLY,
       rvals => [STRING, STRING],
       cvt => 0
     },

     { args => [ COORDSYS ],
       query => QONLY,
       rvals => [STRING, STRING],
       cvt => 0
     },


    ],

   ],

#------------------------------------------------------

   pixeltable =>
   [
    [
     [],
     { args => [ ENUM( 'yes', 'no' ) ] },
     { args => [ ENUM( 'open', 'close' ) ] },
    ],
   ],

#------------------------------------------------------

   print =>
   [

    [
     ['destination'],
     { args => [ ENUM( 'printer', 'file' ) ] },
    ],

    [
     ['command'],
     { args => [ STRING ] },
    ],

    [
     ['filename'],
     { args => [ STRING ] },
    ],

    [
     ['palette'],
     { args => [ ENUM( 'rgb', 'cmyk', 'gray' ) ] },
    ],

    [
     ['level'],
     { args => [ ENUM( '1', '2' ) ] },
    ],

    [
     ['resolution'],
     { args => [ ENUM( qw( 53 72 75 150 300 600  )) ] },
    ],

    [
     [],
     { query => QNONE }
    ],

   ],


#------------------------------------------------------

   quit =>
   [
    [
     [],
     { query => QNONE },
    ]
   ],


#------------------------------------------------------

   raise =>
   [
    [
     [],
     { query => QNONE },
    ]
   ],


#------------------------------------------------------

   regions =>
   [

    [
     [ENUM( qw( movefront moveback selectall selectnone deleteall )) ],
     { query => QNONE },
    ],


    [
     [ENUM( qw( load save ) )],
     { args => [ STRING ], query => QNONE },
    ],

    [
     ['format'],
     { args => [ REGIONFORMAT ] },
    ],

    [
     ['system'],
     { args => [ COORDSYS ] },
    ],

    [
     ['sky'],
     { args => [ SKYFRAME ] },
    ],

    [
     ['skyformat'],
     { args => [ SKYFORMAT ] },
    ],

    [
     ['strip'],
     { args => [ BOOL ] },
    ],

    [ 
     [ENUM(qw(source background include exclude selected)) ],
     { query => QONLY }
    ],

    [
     ['shape'],
     { args => [STRING] }
    ],

    [ 
     ['width'],
     { args => [INT] }
    ],

    [ 
     ['color'],
     { args => [ENUM(qw( black white red green blue cyan magenta yellow))] }
    ],


    [
     [],
     { args => [STRING_NL], 
       query => QNONE, 
       bufarg => 1,
     },
     { query => QYES|QONLY|QATTR, 
       rvals => [ STRING ],
       attrs => [
		 -format => REGIONFORMAT,
		 -system => COORDSYS,
		 -sky    => SKYFRAME,
		 -skyformat => SKYFORMAT,
		 -strip  => BOOL,
		 -prop   => ENUM(qw( select edit move rotate delete fixed 
				     include source )),
		] 
     }
    ],

   ],

#------------------------------------------------------

   rotate =>
   [

    [
     [ 'to' ],
     { args => [FLOAT], query => QNONE },
    ],

    [
     [ REWRITE( 'abs', 'to' ) ],
     { args => [FLOAT], query => QNONE },
    ],

    [
     [ EPHEMERAL( 'rel' ) ],
     { args => [FLOAT], query => QNONE },
    ],


    [
     [],
     { args => [FLOAT] },
    ],

   ],

#------------------------------------------------------

   saveas =>
   [
    [
     [ENUM( qw( jpeg tiff png ppm ) )],
     { args => [ STRING ], query => QNONE },
    ]
   ],

#------------------------------------------------------

   scale =>
   [

    [
     ['datasec'],
     { args => [ BOOL ] },
    ],

    [
     ['limits'],
     { args => [ FLOAT, FLOAT ] },
    ],

    [
     ['mode'],
     { args => [ ENUM( qw( minmax zscale zmax ) ) ] },
     { args => [ FLOAT ] },
    ],

    [
     ['scope'],
     { args => [ ENUM( qw( local global ) ) ] },
    ],

    [
     [],
     { args => [ ENUM( qw( linear log squared sqrt histequ ) ) ] }
    ],

   ],

#------------------------------------------------------

   single =>
   [
    [
     [ EPHEMERAL('state') ],
     { rvals => [ BOOL ], query => QONLY },
    ],

    [
     [],
     { query => QNONE },
    ]
   ],

#------------------------------------------------------

   smooth =>
   [

    [
     [ 'function' ],
     { args => [ ENUM( 'boxcar', 'tophat', 'gaussian' ) ] },
    ],

    [
     [ 'radius' ],
     { args => [ FLOAT ] },
    ],

    [
     [],
     { args => [ BOOL ] },
    ],

   ],


#------------------------------------------------------

   source =>
   [
    [
     [],
     { args => [STRING], query => QNONE },
    ],
   ],

#------------------------------------------------------

   tcl =>
   [
    [
     [],
     { args => [STRING], query => QNONE },
    ],
   ],

#------------------------------------------------------

   tile =>
   [
    [
     [ 'mode' ],
     { args => [ ENUM('grid', 'column', 'row' ) ] }
    ],

    [
     ['grid', 'mode'],
     {args => [ ENUM('automatic','manual') ] },
    ],

    [
     ['grid', 'layout'],
     { args => [ INT, INT ] },
    ],

    [
     [ 'grid', 'gap' ],
     { args => [ INT ] },
    ],

    [
     [ENUM('grid', 'row', 'column')],
     { query => QNONE },
    ],

    [
     [ EPHEMERAL('state') ],
     { rvals => [ BOOL ], query => QONLY },
    ],

    [
     [],
     { args => [ BOOL ] }
    ],
   ],

#------------------------------------------------------

   update =>
   [
    [],
    { attrs => [ now => BOOL ], query => QNONE },
    { args => [ INT, FLOAT, FLOAT, FLOAT, FLOAT ], 
      attrs => [ now => BOOL ], 
      query => QNONE }
   ],

#------------------------------------------------------

   version =>
   [
    [
     [],
     { rvals => [STRING],
       query => QONLY },
    ],
   ],

#------------------------------------------------------

   view =>
   [
    [
     [ENUM( qw( info
		panner
		magnifier
		buttons
		filename
		object
		minmax
		lowhigh
		frame
		red
		green
		blue
	     ) )],
     { args => [ BOOL ] },
    ],

    [
     ['layout'],
     { args => [ ENUM( 'vertical', 'horizontal' ) ] },
    ],


    [
     ['colorbar', 'numerics' ],
     { args => [ BOOL ] },
    ],


    [
     ['colorbar'],
     { args => [ ENUM( 'vertical', 'horizontal' ) ] },
     { args => [ BOOL ] },
    ],

    [
     ['graph', 'vertical' ],
     { args => [ BOOL ] },
    ],

    [
     ['graph', 'horizontal' ],
     { args => [ BOOL ] },
    ],

    [
     [COORDSYS],
     { args => [ BOOL ] },
    ]
   ],

#------------------------------------------------------

   vo =>
   [
    [
     [],
     { args => [ STRING ] }
    ],
   ],

#------------------------------------------------------

   wcs =>
   [

    [
     ['system'],
     { args => [ WCSS ] }
    ],

    [
     ['sky'],
     { args => [ SKYFRAME ] }
    ],

    [
     ['skyformat'],
     { args => [ SKYFORMAT ] }
    ],

    [
     ['align'],
     { args => [ BOOL ] }
    ],

    [
     ['reset'],
     { query => QNONE },
    ],


    [
     ['replace', 'file' ],
     { args => [ STRING ], query => QNONE },
    ],

    [
     ['append', 'file' ],
     { args => [ STRING ], query => QNONE },
    ],

    [
     [ENUM( 'replace', 'append' )],
     { args => [ WCS_SCALARREF ], query => QNONE, bufarg => 1 },
     { args => [ WCS_HASH ], query => QNONE, bufarg => 1 },
     { args => [ WCS_ARRAY ], query => QNONE, bufarg => 1 },
    ],

    [
     [],
     { args => [ WCSS ] },
    ],

   ],

#------------------------------------------------------

   web =>
   [
    [
     [],
     { args => [STRING] }
    ]
   ],


#------------------------------------------------------

   width =>
   [
    [
     [],
     { args => [INT] }
    ]
   ],


#------------------------------------------------------

   zoom =>
   [
    [
     [ 'to' ],
     { args => [FLOAT], query => QNONE },
     { args => ['fit'], query => QNONE },
    ],

    [
     [ REWRITE( 'abs' => 'to') ],
     { args => [FLOAT], query => QNONE },
    ],

    [
     [ EPHEMERAL('rel') ],
     { args => [FLOAT], query => QNONE },
    ],

    [
     [ REWRITE( '0' => 'to fit' ) ],
     { query => QNONE },
    ],

    [
     [ REWRITE( tofit => 'to fit' ) ],
     { query => QNONE },
    ],

    [ 
     [],
     { args => [FLOAT] }
    ],

   ]
  );


1;

