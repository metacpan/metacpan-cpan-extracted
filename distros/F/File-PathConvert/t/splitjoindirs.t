#!/usr/bin/perl

#
# splitjoindirs.t
#

use strict ;
use Test ;
use Cwd;
use File::PathConvert qw( setfstype splitdirs joindirs );

my @data ;

BEGIN {
   @data = (
   # fsspec   INPUT           OUTPUT         ...
   [ 'Win32', '',             '',            ''    ],   
   [ 'Win32', '\\d1/d2\\d3/', '/d1/d2/d3/',  '',   'd1', 'd2', 'd3', '' ],
   [ 'Win32', 'd1/d2\\d3/',   'd1/d2/d3/',   'd1', 'd2', 'd3', ''    ],
   [ 'Win32', '\\d1/d2\\d3',  '/d1/d2/d3',   '',   'd1', 'd2', 'd3'  ],
   [ 'Win32', 'd1/d2\\d3',    'd1/d2/d3',    'd1', 'd2', 'd3'  ],   

   [ 'VMS',   '',             '[]',          ''    ],   
   [ 'VMS',   '[]',           '[]',          ''    ],   
   [ 'VMS',   'd1.d2.d3',     '[d1.d2.d3]',  'd1', 'd2', 'd3'  ],   
   [ 'VMS',   '[d1.d2.d3]',   '[d1.d2.d3]',  'd1', 'd2', 'd3'  ],   
   [ 'VMS',   '.d1.d2.d3',    '[.d1.d2.d3]', '',   'd1', 'd2', 'd3'  ],
   [ 'VMS',   '[.d1.d2.d3]',  '[.d1.d2.d3]', '',   'd1', 'd2', 'd3'  ],
   [ 'VMS',   '.-.d2.d3',     '[.-.d2.d3]',  '',   '-',  'd2', 'd3'  ],
   [ 'VMS',   '[.-.d2.d3]',   '[.-.d2.d3]',  '',   '-',  'd2', 'd3'  ],

   [ 'URL',   '',             '',            ''    ],   
   [ 'URL',   '/d1/d2/d3/',   '/d1/d2/d3/',  '',   'd1', 'd2', 'd3', '' ],
   [ 'URL',   'd1/d2/d3/',    'd1/d2/d3/',   'd1', 'd2', 'd3', ''    ],
   [ 'URL',   '/d1/d2/d3',    '/d1/d2/d3',   '',   'd1', 'd2', 'd3'  ],
   [ 'URL',   'd1/d2/d3',     'd1/d2/d3',    'd1', 'd2', 'd3'  ],

   [ 'other', '',             '',            ''    ],   
   [ 'other', '/d1/d2/d3/',   '/d1/d2/d3/',  '',   'd1', 'd2', 'd3', '' ],
   [ 'other', 'd1/d2/d3/',    'd1/d2/d3/',   'd1', 'd2', 'd3', ''    ],
   [ 'other', '/d1/d2/d3',    '/d1/d2/d3',   '',   'd1', 'd2', 'd3'  ],
   [ 'other', 'd1/d2/d3',     'd1/d2/d3',    'd1', 'd2', 'd3'  ]    
   );

   plan tests => ( ( $#data + 1 ) * 2 ) ;
}

my $oldfsspec = '' ;

my $i ;

for( $i= 0; $i <= $#data; ++$i ) {
   my( $fsspec, $in, $expected ) = @{ $data[ $i ] } ;

   die '$fsspec undefined'
      unless defined( $fsspec ) ;
   die '$in undefined'
      unless defined( $in ) ;
   die '$expected undefined'
      unless defined( $expected ) ;

   my @intermediate_expected= @{ $data[ $i ] } ;
   splice( @intermediate_expected, 0, 3 ) ;
   my $intermediate_expected = 
     join( '', ( "[ '", join( "', '", @intermediate_expected ), "' ]" ));

   if ( $fsspec ne $oldfsspec ) 
   {
      setfstype( $fsspec ) ;
      $oldfsspec= $fsspec ;
   }
   my @intermediate= splitdirs( $in ) ;
   my $intermediate = join( '', ( "[ '", join( "', '", @intermediate ), "' ]" ) ) ;
   my $was_not_ok = ! ok( 
      $intermediate, 
      $intermediate_expected, 
      "splitdirs( \"$in\" ) for \"$fsspec\""
   ) ;

   skip( 
      $was_not_ok, 
      joindirs( @intermediate ), 
      $expected,
      "joindirs( $intermediate ) for \"$fsspec\""
   ) ;
}
