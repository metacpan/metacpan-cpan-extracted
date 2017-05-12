#!/usr/bin/perl

#
# splitjoinpath.t
#

use strict ;
use Test ;
use Cwd;
use File::PathConvert qw( setfstype splitpath joinpath );

my @data ;

BEGIN {
@data = (
# fsspec   Input                                       volume,                       directory,        filename    
[ 'Win32', 'file',                                     '',                           '',               'file'        ],                         
[ 'Win32', '\\d1/d2\\d3/',                             '',                           '\\d1/d2\\d3/',   ''            ],                         
[ 'Win32', 'd1/d2\\d3/',                               '',                           'd1/d2\\d3/',     ''            ],                         
[ 'Win32', '\\d1/d2\\d3/.',                            '',                           '\\d1/d2\\d3/.',  ''            ],                         
[ 'Win32', '\\d1/d2\\d3/..',                           '',                           '\\d1/d2\\d3/..', ''            ],                         
[ 'Win32', '\\d1/d2\\d3/.file',                        '',                           '\\d1/d2\\d3/',   '.file'       ],                         
[ 'Win32', '\\d1/d2\\d3/file',                         '',                           '\\d1/d2\\d3/',   'file'        ],                         
[ 'Win32', 'd1/d2\\d3/file',                           '',                           'd1/d2\\d3/',     'file'        ],                         
[ 'Win32', 'C:\\d1/d2\\d3/',                           'C:',                         '\\d1/d2\\d3/',   ''            ],                         
[ 'Win32', 'C:d1/d2\\d3/',                             'C:',                         'd1/d2\\d3/',     ''            ],                         
[ 'Win32', 'C:\\d1/d2\\d3/file',                       'C:',                         '\\d1/d2\\d3/',   'file'        ],                         
[ 'Win32', 'C:d1/d2\\d3/file',                         'C:',                         'd1/d2\\d3/',     'file'        ],                         
[ 'Win32', 'C:\\../d2\\d3/file',                       'C:',                         '\\../d2\\d3/',   'file'        ],                         
[ 'Win32', 'C:../d2\\d3/file',                         'C:',                         '../d2\\d3/',     'file'        ],                         
[ 'Win32', '\\../..\\d1/',                             '',                           '\\../..\\d1/',   ''            ],                         
[ 'Win32', '\\./.\\d1/',                               '',                           '\\./.\\d1/',     ''            ],                         
[ 'Win32', '\\\\node\\share\\d1/d2\\d3/',              '\\\\node\\share',            '\\d1/d2\\d3/',   ''            ],                         
[ 'Win32', '\\\\node\\share\\d1/d2\\d3/file',          '\\\\node\\share',            '\\d1/d2\\d3/',   'file'        ],                         
[ 'Win32', '\\\\node\\share\\d1/d2\\file',             '\\\\node\\share',            '\\d1/d2\\',      'file'        ],                         

[ 'VMS',   'file',                                     '',                           '',               'file'        ],                         
[ 'VMS',   '[d1.d2.d3]',                               '',                           '[d1.d2.d3]',     ''            ],                         
[ 'VMS',   '[.d1.d2.d3]',                              '',                           '[.d1.d2.d3]',    ''            ],                         
[ 'VMS',   '[d1.d2.d3]file',                           '',                           '[d1.d2.d3]',     'file'        ],                         
[ 'VMS',   '[.d1.d2.d3]file',                          '',                           '[.d1.d2.d3]',    'file'        ],                         
[ 'VMS',   'node::volume:[d1.d2.d3]',                  'node::volume:',              '[d1.d2.d3]',     ''            ],                         
[ 'VMS',   'node::volume:[d1.d2.d3]file',              'node::volume:',              '[d1.d2.d3]',     'file'        ],                         
[ 'VMS',   'node"access_spec"::volume:[d1.d2.d3]',     'node"access_spec"::volume:', '[d1.d2.d3]',     ''            ],                         
[ 'VMS',   'node"access_spec"::volume:[d1.d2.d3]file', 'node"access_spec"::volume:', '[d1.d2.d3]',     'file'        ],                         

[ 'URL',   'file',                                     '',                           '',               'file'        ],                         
[ 'URL',   '/d1/d2/d3/',                               '',                           '/d1/d2/d3/',     ''            ],                         
[ 'URL',   '/d1/d2/d3/.',                              '',                           '/d1/d2/d3/.',    '',           '/d1/d2/d3/./'              ],
[ 'URL',   '/d1/d2/d3/..',                             '',                           '/d1/d2/d3/..',   '',           '/d1/d2/d3/../'             ],
[ 'URL',   'd1/d2/d3/',                                '',                           'd1/d2/d3/',      ''            ],                         
[ 'URL',   '/d1/d2/d3/file',                           '',                           '/d1/d2/d3/',     'file'        ],                         
[ 'URL',   'd1/d2/d3/file',                            '',                           'd1/d2/d3/',      'file'        ],                         
[ 'URL',   '/../../d1/',                               '',                           '/../../d1/',     ''            ],                         
[ 'URL',   '/././d1/',                                 '',                           '/././d1/',       ''            ],                         
[ 'URL',   'http:file',                                'http:',                      '',               'file'        ],                         
[ 'URL',   'http:/d1/d2/d3/',                          'http:',                      '/d1/d2/d3/',     ''            ],                         
[ 'URL',   'http:d1/d2/d3/',                           'http:',                      'd1/d2/d3/',      ''            ],                         
[ 'URL',   'http:/d1/d2/d3/file',                      'http:',                      '/d1/d2/d3/',     'file'        ],                         
[ 'URL',   'http:d1/d2/d3/file',                       'http:',                      'd1/d2/d3/',      'file'        ],                         
[ 'URL',   'http:/../../d1/',                          'http:',                      '/../../d1/',     ''            ],                         
[ 'URL',   'http:/././d1/',                            'http:',                      '/././d1/',       ''            ],                         
[ 'URL',   'http://a.b.com/file',                      'http://a.b.com',             '/',              'file'        ],                         
[ 'URL',   'http://a.b.com/d1/d2/d3/',                 'http://a.b.com',             '/d1/d2/d3/',     ''            ],                         
[ 'URL',   'http://a.b.com/d1/d2/d3/file',             'http://a.b.com',             '/d1/d2/d3/',     'file'        ],                         
[ 'URL',   'http://a.b.com/../../d1/',                 'http://a.b.com',             '/../../d1/',     ''            ],                         
[ 'URL',   'http://a.b.com/././d1/',                   'http://a.b.com',             '/././d1/',       ''            ],                         
[ 'URL',   'http:file#target',                         'http:',                      '',               'file#target' ],                         
[ 'URL',   'http:file?query',                          'http:',                      '',               'file?query'  ],                         
[ 'URL',   'http:/d1/d2/d3/#target',                   'http:',                      '/d1/d2/d3/',     '#target'     ],                         
[ 'URL',   'http:/d1/d2/d3/.#target',                  'http:',                      '/d1/d2/d3/.',    '#target',    'http:/d1/d2/d3/./#target'  ],
[ 'URL',   'http:/d1/d2/d3/..#target',                 'http:',                      '/d1/d2/d3/..',   '#target',    'http:/d1/d2/d3/../#target' ],
[ 'URL',   'http:/d1/d2/d3/?query',                    'http:',                      '/d1/d2/d3/',     '?query'      ],                         
[ 'URL',   'http:d1/d2/d3/?query',                     'http:',                      'd1/d2/d3/',      '?query'      ],                         
[ 'URL',   'http:/d1/d2/d3/file?query',                'http:',                      '/d1/d2/d3/',     'file?query'  ],                         
[ 'URL',   'http:d1/d2/d3/file?query',                 'http:',                      'd1/d2/d3/',      'file?query'  ],                         
[ 'URL',   'http:/../../d1/?query',                    'http:',                      '/../../d1/',     '?query'      ],                         
[ 'URL',   'http:/././d1/?query',                      'http:',                      '/././d1/',       '?query'      ],                         
[ 'URL',   'http://a.b.com/file?query',                'http://a.b.com',             '/',              'file?query'  ],                         
[ 'URL',   'http://a.b.com/d1/d2/d3/?query',           'http://a.b.com',             '/d1/d2/d3/',     '?query'      ],                         
[ 'URL',   'http://a.b.com/d1/d2/d3/file?query',       'http://a.b.com',             '/d1/d2/d3/',     'file?query'  ],                         
[ 'URL',   'http://a.b.com/../../d1/?query',           'http://a.b.com',             '/../../d1/',     '?query'      ],                         

[ 'other', 'file',                                     '',                           '',               'file'        ],                         
[ 'other', '/d1/d2/d3/',                               '',                           '/d1/d2/d3/',     ''            ],                         
[ 'other', 'd1/d2/d3/',                                '',                           'd1/d2/d3/',      ''            ],                         
[ 'other', '/d1/d2/d3/.',                              '',                           '/d1/d2/d3/.',    ''            ],                         
[ 'other', '/d1/d2/d3/..',                             '',                           '/d1/d2/d3/..',   ''            ],                         
[ 'other', '/d1/d2/d3/.file',                          '',                           '/d1/d2/d3/',     '.file'       ],                         
[ 'other', 'd1/d2/d3/file',                            '',                           'd1/d2/d3/',      'file'        ],                         
[ 'other', '/../../d1/',                               '',                           '/../../d1/',     ''            ],                         
[ 'other', '/././d1/',                                 '',                           '/././d1/',     ''           ],
);

   plan tests => ( ( $#data + 1 ) * 2 ) ;
}

my $oldfsspec= '' ;

my $i ;

for ( $i= 0; $i <= $#data; ++$i ) 
{
   my( $fsspec, $in, $volume_out, $directory_out, $filename_out, $expected_out )=
     @{$data[ $i ]} ;

   die '$fsspec undefined'
      unless defined( $fsspec ) ;
   die '$in undefined'
      unless defined( $in ) ;
   die '$volume_out undefined'
      unless defined( $volume_out ) ;
   die '$directory_out undefined'
      unless defined( $directory_out ) ;
   die '$filename_out undefined'
      unless defined( $filename_out ) ;

   $expected_out = $in
      if ( ! defined( $expected_out ) ) ;

   if ( $fsspec ne $oldfsspec ) 
   {
      setfstype( $fsspec ) ;
      $oldfsspec= $fsspec ;
   }
   my( $volume, $directory, $filename ) = splitpath( $in );
   my $was_not_ok= 
      ! ok( 
         "(\"$volume\", \"$directory\", \"$filename\")", 
         "(\"$volume_out\", \"$directory_out\", \"$filename_out\")", 
         "splitpath( \"$in\" ) for \"$fsspec\"" 
      ) ;

   skip( 
      $was_not_ok, 
      joinpath( $volume, $directory, $filename ), 
      $expected_out, 
      "joinpath( \"$volume\", \"$directory\", \"$filename\" ) for \"$fsspec\"" 
   ) ;
}

