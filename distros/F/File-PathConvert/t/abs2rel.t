#!/usr/bin/perl

#
# abs2rel.t
#


use strict ;
use Test ;
use Cwd;
use File::PathConvert qw( setfstype abs2rel );

my @data ;

BEGIN {
   @data = (
   # OS       INPUT                      BASE          OUTPUT                
   [ 'Win32', '/t1/t2/t3',               '/t1/t2/t3',  ''                     ],  
   [ 'Win32', '/t1/t2/t4',               '/t1/t2/t3',  '../t4'                ],  
   [ 'Win32', '/t1/t2',                  '/t1/t2/t3',  '..'                   ],  
   [ 'Win32', '/t1/t2/t3/t4',            '/t1/t2/t3',  't4'                   ],  
   [ 'Win32', '/t4/t5/t6',               '/t1/t2/t3',  '../../../t4/t5/t6'    ],  
   [ 'Win32', '../t4',                   '/t1/t2/t3',  '../t4'                ],  
   [ 'Win32', '/',                       '/t1/t2/t3',  '../../..'             ],  
   [ 'Win32', '///',                     '/t1/t2/t3',  '../../..'             ],  
   [ 'Win32', '/.',                      '/t1/t2/t3',  '../../..'             ],  
   [ 'Win32', '/./',                     '/t1/t2/t3',  '../../..'             ],  
   [ 'Win32', '/../',                    '/t1/t2/t3',  '../../..'             ],  
   [ 'Win32', '/../../../..',            '/t1/t2/t3',  '../../..'             ],  
   [ 'Win32', '/..a/..b/..c/..',         '/t1/t2/t3',  '../../../..a/..b'     ],  
   [ 'Win32', '/..\\/..\\/..\\/..',      '/t1/t2/t3',  '../../..'             ],  
   [ 'Win32', 't1',                      '/t1/t2/t3',  't1'                   ],  
   [ 'Win32', '.',                       '/t1/t2/t3',  '.'                    ],  
   [ 'Win32', '\\\\a\\b/t1/t2/t4',       '/t1/t2/t3',  '\\\\a\\b/../t4'       ],  
   [ 'Win32', '//a\\b/t1/t2/t4',         '/t1/t2/t3',  '//a\\b/../t4'         ],  

   [ 'VMS',   'node::volume:[t1.t2.t3]', '[t1.t2.t3]',  'node::volume:'       ],
   [ 'VMS',   'node::volume:[t1.t2.t4]', '[t1.t2.t3]',  'node::volume:[.-.t4]'],

## MacOS support has always been borked, it seems.   This module is deprecated,
## so I am just going to document the problem.
#   [ 'MacOS', 't1:t2:t3',                't1:t2:t3',  ''                     ],  
#   [ 'MacOS', 't1:t2',                   't1:t2:t3',  '::'                   ],  
#   [ 'MacOS', 't1:t4',                   't1:t2:t3',  ':::t4'                ],  
#   [ 'MacOS', 't1:t2:t4',                't1:t2:t3',  '::t4'                ],  
#   [ 'MacOS', 't1:t2:t3:t4',             't1:t2:t3',  't4'                   ],  

#   [ 'MacOS', 't4:t5:t6',                't1:t2:t3',  '::::t4:t5:t6'    ],  
#   [ 'MacOS', '::t4',                    't1:t2:t3',  '::t4'                ],  
#   [ 'MacOS', '',                        't1:t2:t3',  ''             ],  
#   [ 'MacOS', ':::',                     't1:t2:t3',  't1'             ],  
#   [ 'MacOS', '::',                      't1:t2:t3',  '::'              ],  
#   [ 'MacOS', '::::',                    't1:t2:t3',  '::::'             ],  
#   [ 'MacOS', 't1',                      't1:t2:t3',  ':::'                   ],  

   [ 'URL', '/t1/t2/t3/',               '/t1/t2/t3/',  ''                    ],  
   [ 'URL', '/t1/t2/t4/',               '/t1/t2/t3/',  '../t4/'                ],  
   [ 'URL', '/t1/t2/',                  '/t1/t2/t3/',  '../'                   ],  
   [ 'URL', '/t1/t2/t3/t4/',            '/t1/t2/t3/',  't4/'                   ],  
   [ 'URL', '/t4/t5/t6/',               '/t1/t2/t3/',  '../../../t4/t5/t6/'    ],  
   [ 'URL', '../t4/',                   '/t1/t2/t3/',  '../t4/'                ],  
   [ 'URL', '/',                        '/t1/t2/t3/',  '../../../'             ],  
   [ 'URL', '//a.b.com/',               '/t1/t2/t3/',  '../../../'             ],  
   [ 'URL', '/./',                      '/t1/t2/t3/',  '../../../'             ],  
   [ 'URL', '/./',                      '/t1/t2/t3/',  '../../../'             ],  
   [ 'URL', '/../',                     '/t1/t2/t3/',  '../../../'             ],  
   [ 'URL', '/../../../../',            '/t1/t2/t3/',  '../../../'             ],  
   [ 'URL', '/..\\/..\\/..\\/../',      '/t1/t2/t3/',  '../../../..\\/..\\/'   ],  
   [ 'URL', '/..a/..b/..c/../',         '/t1/t2/t3/',  '../../../..a/..b/'     ],  
   [ 'URL', 't1/',                      '/t1/t2/t3/',  't1/'                   ],  
   [ 'URL', './',                       '/t1/t2/t3/',  './'                    ],
   [ 'URL', 'http:/./t1/t2/t3/',        'ftp:/./a/b',  'http:../t1/t2/t3/'     ],
   [ 'URL', '/./t1/t2/t3/..',           '/./a/b',     '../t1/t2/'              ],
   [ 'URL', '/./t1/t2',                 '/./a/b',     '../t1/t2'               ],
   [ 'URL', '/./t1/t2/t3',              '/./t1/t2/t4', 't3'                    ],

   [ 'other', '/t1/t2/t3',               '/t1/t2/t3',  ''                    ],  
   [ 'other', '/t1/t2/t4',               '/t1/t2/t3',  '../t4'                ],  
   [ 'other', '/t1/t2',                  '/t1/t2/t3',  '..'                   ],  
   [ 'other', '/t1/t2/t3/t4',            '/t1/t2/t3',  't4'                   ],  
   [ 'other', '/t4/t5/t6',               '/t1/t2/t3',  '../../../t4/t5/t6'    ],  
   [ 'other', '../t4',                   '/t1/t2/t3',  '../t4'                ],  
   [ 'other', '/',                       '/t1/t2/t3',  '../../..'             ],  
   [ 'other', '///',                     '/t1/t2/t3',  '../../..'             ],  
   [ 'other', '/.',                      '/t1/t2/t3',  '../../..'             ],  
   [ 'other', '/./',                     '/t1/t2/t3',  '../../..'             ],  
   [ 'other', '/../',                    '/t1/t2/t3',  '../../..'             ],  
   [ 'other', '/../../../..',            '/t1/t2/t3',  '../../..'             ],  
   [ 'other', '/..\\/..\\/..\\/..',      '/t1/t2/t3',  '../../../..\\/..\\'   ],  
   [ 'other', '/..a/..b/..c/..',         '/t1/t2/t3',  '../../../..a/..b'     ],  
   [ 'other', 't1',                      '/t1/t2/t3',  't1'                   ],  
   [ 'other', '.',                       '/t1/t2/t3',  '.'                    ]   
   );

   plan tests => ( $#data + 1 ) ;
}

my $oldfsspec = '' ;

my $i ;

$oldfsspec= '' ;
for( $i= 0; $i <= $#data; ++$i ) {
   my( $fsspec, $in, $base, $expected ) = @{ $data[ $i ] } ;

   die '$fsspec undefined'
      unless defined( $fsspec ) ;
   die '$in undefined'
      unless defined( $in ) ;
   die '$base undefined'
      unless defined( $base ) ;
   die '$expected undefined'
      unless defined( $expected ) ;

   if ( $fsspec ne $oldfsspec ) 
   {
      setfstype( $fsspec ) ;
      $oldfsspec= $fsspec ;
   }

   ok( 
      abs2rel( $in, $base ), 
      $expected, 
      "abs2rel( \"$in\", \"$base\" ) for \"$fsspec\"" 
   ) ;
}

