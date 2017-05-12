use strict;
use warnings;
use GPS::Babel;
use File::Spec;
use Data::Dumper;
use Test::More;

my @tests;

BEGIN {
  my $ref_info = {
    'formats' => {
      'google' => {
        'nmodes' => 8,
        'parent' => 'google',
        'desc'   => 'Google Maps XML',
        'modes'  => '--r---',
        'ext'    => 'xml'
      },
      'nmn4' => {
        'nmodes'  => 3,
        'parent'  => 'nmn4',
        'options' => {
          'index' => {
            'min' => '1',
            'desc' =>
             'Index of route to write (if more the one in source)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          }
        },
        'desc'  => 'Navigon Mobile Navigator .rte files',
        'modes' => '----rw',
        'ext'   => 'rte'
      },
      'tpg' => {
        'nmodes'  => 48,
        'parent'  => 'tpg',
        'options' => {
          'datum' => {
            'min'     => '',
            'desc'    => 'Datum (default=NAD27)',
            'max'     => '',
            'default' => 'N. America 1927 mean',
            'type'    => 'string'
          }
        },
        'desc'  => 'National Geographic Topo .tpg (waypoints)',
        'modes' => 'rw----',
        'ext'   => 'tpg'
      },
      'mxf' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'MapTech Exchange Format',
        'modes' => 'rw----',
        'ext'   => 'mxf'
      },
      'igc' => {
        'nmodes'  => 15,
        'parent'  => 'igc',
        'options' => {
          'timeadj' => {
            'min' => '',
            'desc' =>
             '(integer sec or \'auto\') Barograph to GPS time diff',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'FAI/IGC Flight Recorder Data Format',
        'modes' => '--rwrw'
      },
      'magellan' => {
        'nmodes'  => 63,
        'parent'  => 'magellan',
        'options' => {
          'nukewpt' => {
            'min'     => '',
            'desc'    => 'Delete all waypoints',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'noack' => {
            'min'     => '',
            'desc'    => 'Suppress use of handshaking in name of speed',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'baud' => {
            'min'     => '',
            'desc'    => 'Numeric value of bitrate (baud=4800)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'maxcmts' => {
            'min'  => '',
            'desc' => 'Max number of comments to write (maxcmts=200)',
            'max'  => '',
            'default' => '',
            'type'    => 'integer'
          }
        },
        'desc'  => 'Magellan SD files (as for Meridian)',
        'modes' => 'rwrwrw'
      },
      'lowranceusr' => {
        'nmodes'  => 63,
        'parent'  => 'lowranceusr',
        'options' => {
          'merge' => {
            'min'     => '',
            'desc'    => '(USR output) Merge into one segmented track',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'ignoreicons' => {
            'min'     => '',
            'desc'    => 'Ignore event marker icons',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'break' => {
            'min'  => '',
            'desc' => '(USR input) Break segments into separate tracks',
            'max'  => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Lowrance USR',
        'modes' => 'rwrwrw',
        'ext'   => 'usr'
      },
      'dmtlog' => {
        'nmodes'  => 60,
        'parent'  => 'dmtlog',
        'options' => {
          'index' => {
            'min'     => '1',
            'desc'    => 'Index of track (if more the one in source)',
            'max'     => '',
            'default' => '1',
            'type'    => 'integer'
          }
        },
        'desc'  => 'TrackLogs digital mapping (.trl)',
        'modes' => 'rwrw--',
        'ext'   => 'trl'
      },
      'garmin' => {
        'options' => {
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'power_off' => {
            'min'     => '',
            'desc'    => 'Command unit to power itself down',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'category' => {
            'min'     => '1',
            'desc'    => 'Category number to use for written waypoints',
            'max'     => '16',
            'default' => '',
            'type'    => 'integer'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Length of generated shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'get_posn' => {
            'min'     => '',
            'desc'    => 'Return current position as a waypoint',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        }
      },
      'bcr' => {
        'nmodes'  => 3,
        'parent'  => 'bcr',
        'options' => {
          'index' => {
            'min' => '1',
            'desc' =>
             'Index of route to write (if more the one in source)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'radius' => {
            'min' => '',
            'desc' =>
             'Radius of our big earth (default 6371000 meters)',
            'max'     => '',
            'default' => '6371000',
            'type'    => 'float'
          },
          'name' => {
            'min'     => '',
            'desc'    => 'New name for the route',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'Motorrad Routenplaner (Map&Guide) .bcr files',
        'modes' => '----rw',
        'ext'   => 'bcr'
      },
      'msroute' => {
        'nmodes' => 2,
        'parent' => 'msroute',
        'desc'   => 'Microsoft Streets and Trips (pin/route reader)',
        'modes'  => '----r-',
        'ext'    => 'est'
      },
      'csv' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Comma separated values',
        'modes' => 'rw----'
      },
      'tomtom' => {
        'nmodes' => 48,
        'parent' => 'tomtom',
        'desc'   => 'TomTom POI file',
        'modes'  => 'rw----',
        'ext'    => 'ov2'
      },
      'gcdb' => {
        'nmodes' => 48,
        'parent' => 'gcdb',
        'desc'   => 'GeocachingDB for Palm/OS',
        'modes'  => 'rw----',
        'ext'    => 'pdb'
      },
      'gpssim' => {
        'nmodes'  => 21,
        'parent'  => 'gpssim',
        'options' => {
          'wayptspd' => {
            'min'     => '',
            'desc'    => 'Default speed for waypoints (knots/hr)',
            'max'     => '',
            'default' => '',
            'type'    => 'float'
          },
          'split' => {
            'min'     => '',
            'desc'    => 'Split input into separate files',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Franson GPSGate Simulation',
        'modes' => '-w-w-w',
        'ext'   => 'gpssim'
      },
      'yahoo' => {
        'nmodes'  => 32,
        'parent'  => 'yahoo',
        'options' => {
          'addrsep' => {
            'min' => '',
            'desc' =>
             'String to separate concatenated address fields (default=", ")',
            'max'     => '',
            'default' => ', ',
            'type'    => 'string'
          }
        },
        'desc'  => 'Yahoo Geocode API data',
        'modes' => 'r-----'
      },
      'wbt-bin' => {
        'nmodes' => 8,
        'parent' => 'wbt-bin',
        'desc'   => 'Wintec WBT-100/200 Binary file format',
        'modes'  => '--r---'
      },
      'stmsdf' => {
        'nmodes'  => 15,
        'parent'  => 'stmsdf',
        'options' => {
          'index' => {
            'min'     => '1',
            'desc'    => 'Index of route (if more the one in source)',
            'max'     => '',
            'default' => '1',
            'type'    => 'integer'
          }
        },
        'desc'  => 'Suunto Trek Manager (STM) .sdf files',
        'modes' => '--rwrw',
        'ext'   => 'sdf'
      },
      'easygps' => {
        'nmodes' => 48,
        'parent' => 'easygps',
        'desc'   => 'EasyGPS binary format',
        'modes'  => 'rw----',
        'ext'    => 'loc'
      },
      'openoffice' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc' =>
         'Tab delimited fields useful for OpenOffice, Ploticus etc.',
        'modes' => 'rw----'
      },
      'ktf2' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Kartex 5 Track File',
        'modes' => 'rw----',
        'ext'   => 'ktf'
      },
      'geo' => {
        'nmodes'  => 48,
        'parent'  => 'geo',
        'options' => {
          'nuke_placer' => {
            'min'     => '',
            'desc'    => 'Omit Placer name',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'Geocaching.com .loc',
        'modes' => 'rw----',
        'ext'   => 'loc'
      },
      'pcx' => {
        'nmodes'  => 63,
        'parent'  => 'pcx',
        'options' => {
          'cartoexploreur' => {
            'min'     => '',
            'desc'    => 'Write tracks compatible with Carto Exploreur',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => 'Waypoint',
            'type'    => 'string'
          }
        },
        'desc'  => 'Garmin PCX5',
        'modes' => 'rwrwrw',
        'ext'   => 'pcx'
      },
      'xmap' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'DeLorme XMap HH Native .WPT',
        'modes' => 'rw----',
        'ext'   => 'wpt'
      },
      'holux' => {
        'nmodes' => 48,
        'parent' => 'holux',
        'desc'   => 'Holux (gm-100) .wpo Format',
        'modes'  => 'rw----',
        'ext'    => 'wpo'
      },
      'gpspilot' => {
        'nmodes'  => 48,
        'parent'  => 'gpspilot',
        'options' => {
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'GPSPilot Tracker for Palm/OS',
        'modes' => 'rw----',
        'ext'   => 'pdb'
      },
      'kml' => {
        'nmodes'  => 63,
        'parent'  => 'kml',
        'options' => {
          'max_position_points' => {
            'min' => '',
            'desc' =>
             'Retain at most this number of position points  (0 = unlimited)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'line_color' => {
            'min'     => '',
            'desc'    => 'Line color, specified in hex AABBGGRR',
            'max'     => '',
            'default' => '64eeee17',
            'type'    => 'string'
          },
          'trackdata' => {
            'min' => '',
            'desc' =>
             'Include extended data for trackpoints (default = 1)',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean'
          },
          'line_width' => {
            'min'     => '',
            'desc'    => 'Width of lines, in pixels',
            'max'     => '',
            'default' => '6',
            'type'    => 'integer'
          },
          'points' => {
            'min'     => '',
            'desc'    => 'Export placemarks for tracks and routes',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean'
          },
          'lines' => {
            'min'     => '',
            'desc'    => 'Export linestrings for tracks and routes',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'floating' => {
            'min' => '',
            'desc' =>
             'Altitudes are absolute and not clamped to ground',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'labels' => {
            'min' => '',
            'desc' =>
             'Display labels on track and routepoints  (default = 1)',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean'
          },
          'extrude' => {
            'min'  => '',
            'desc' => 'Draw extrusion line from trackpoint to ground',
            'max'  => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'units' => {
            'min' => '',
            'desc' =>
             'Units used when writing comments (\'s\'tatute or \'m\'etric)',
            'max'     => '',
            'default' => 's',
            'type'    => 'string'
          }
        },
        'desc'  => 'Google Earth (Keyhole) Markup Language',
        'modes' => 'rwrwrw',
        'ext'   => 'kml'
      },
      'wfff' => {
        'nmodes'  => 32,
        'parent'  => 'wfff',
        'options' => {
          'snmac' => {
            'min'     => '',
            'desc'    => 'Shortname is MAC address',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'ahcicon' => {
            'min'     => '',
            'desc'    => 'Ad-hoc closed icon name',
            'max'     => '',
            'default' => 'Red Diamond',
            'type'    => 'string'
          },
          'ahoicon' => {
            'min'     => '',
            'desc'    => 'Ad-hoc open icon name',
            'max'     => '',
            'default' => 'Green Diamond',
            'type'    => 'string'
          },
          'aicicon' => {
            'min'     => '',
            'desc'    => 'Infrastructure closed icon name',
            'max'     => '',
            'default' => 'Red Square',
            'type'    => 'string'
          },
          'aioicon' => {
            'min'     => '',
            'desc'    => 'Infrastructure open icon name',
            'max'     => '',
            'default' => 'Green Square',
            'type'    => 'string'
          }
        },
        'desc'  => 'WiFiFoFum 2.0 for PocketPC XML',
        'modes' => 'r-----',
        'ext'   => 'xml'
      },
      'mapconverter' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Mapopolis.com Mapconverter CSV',
        'modes' => 'rw----',
        'ext'   => 'txt'
      },
      'cetus' => {
        'nmodes'  => 56,
        'parent'  => 'cetus',
        'options' => {
          'appendicon' => {
            'min'     => '',
            'desc'    => 'Append icon_descr to description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'Cetus for Palm/OS',
        'modes' => 'rwr---',
        'ext'   => 'pdb'
      },
      'alantrl' => {
        'nmodes' => 12,
        'parent' => 'alantrl',
        'desc'   => 'Alan Map500 tracklogs (.trl)',
        'modes'  => '--rw--',
        'ext'    => 'trl'
      },
      'glogbook' => {
        'nmodes' => 12,
        'parent' => 'glogbook',
        'desc'   => 'Garmin Logbook XML',
        'modes'  => '--rw--',
        'ext'    => 'xml'
      },
      'fugawi' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Fugawi',
        'modes' => 'rw----',
        'ext'   => 'txt'
      },
      'xmapwpt' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'DeLorme XMat HH Street Atlas USA .WPT (PPC)',
        'modes' => 'rw----'
      },
      'xmap2006' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'DeLorme XMap/SAHH 2006 Native .TXT',
        'modes' => 'rw----',
        'ext'   => 'txt'
      },
      'saroute' => {
        'nmodes'  => 8,
        'parent'  => 'saroute',
        'options' => {
          'controls' => {
            'min'     => '',
            'desc'    => 'Read control points as waypoint/route/none',
            'max'     => '',
            'default' => 'none',
            'type'    => 'string'
          },
          'times' => {
            'min'     => '',
            'desc'    => 'Synthesize track times',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'turns_only' => {
            'min'     => '',
            'desc'    => 'Only read turns; skip all other points',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'turns_important' => {
            'min'     => '',
            'desc'    => 'Keep turns if simplify filter is used',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'split' => {
            'min'     => '',
            'desc'    => 'Split into multiple routes at turns',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'DeLorme Street Atlas Route',
        'modes' => '--r---',
        'ext'   => 'anr'
      },
      'gpx' => {
        'nmodes'  => 63,
        'parent'  => 'gpx',
        'options' => {
          'logpoint' => {
            'min'     => '',
            'desc'    => 'Create waypoints from geocache log entries',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Base URL for link tag in output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'gpxver' => {
            'min'     => '',
            'desc'    => 'Target GPX version for output',
            'max'     => '',
            'default' => '1.0',
            'type'    => 'string'
          },
          'suppresswhite' => {
            'min'     => '',
            'desc'    => 'No whitespace in generated shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Length of generated shortnames',
            'max'     => '',
            'default' => '32',
            'type'    => 'integer'
          }
        },
        'desc'  => 'GPX XML',
        'modes' => 'rwrwrw',
        'ext'   => 'gpx'
      },
      'an1' => {
        'nmodes'  => 55,
        'parent'  => 'an1',
        'options' => {
          'nogc' => {
            'min'     => '',
            'desc'    => 'Do not add geocache data to description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'radius' => {
            'min'     => '',
            'desc'    => 'Radius for circles',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'zoom' => {
            'min'     => '',
            'desc'    => 'Zoom level to reduce points',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Symbol to use for point data',
            'max'     => '',
            'default' => 'Red Flag',
            'type'    => 'string'
          },
          'wpt_type' => {
            'min'     => '',
            'desc'    => 'Waypoint type',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'color' => {
            'min'     => '',
            'desc'    => 'Color for lines or mapnotes',
            'max'     => '',
            'default' => 'red',
            'type'    => 'string'
          },
          'type' => {
            'min'     => '',
            'desc'    => 'Type of .an1 file',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'road' => {
            'min'     => '',
            'desc'    => 'Road type changes',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'DeLorme .an1 (drawing) file',
        'modes' => 'rw-wrw',
        'ext'   => 'an1'
      },
      'hsandv' => {
        'nmodes' => 48,
        'parent' => 'hsandv',
        'desc'   => 'HSA Endeavour Navigator export File',
        'modes'  => 'rw----'
      },
      'netstumbler' => {
        'nmodes'  => 32,
        'parent'  => 'netstumbler',
        'options' => {
          'snmac' => {
            'min'     => '',
            'desc'    => 'Shortname is MAC address',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'nseicon' => {
            'min'     => '',
            'desc'    => 'Non-stealth encrypted icon name',
            'max'     => '',
            'default' => 'Red Square',
            'type'    => 'string'
          },
          'nsneicon' => {
            'min'     => '',
            'desc'    => 'Non-stealth non-encrypted icon name',
            'max'     => '',
            'default' => 'Green Square',
            'type'    => 'string'
          },
          'sneicon' => {
            'min'     => '',
            'desc'    => 'Stealth non-encrypted icon name',
            'max'     => '',
            'default' => 'Green Diamond',
            'type'    => 'string'
          },
          'seicon' => {
            'min'     => '',
            'desc'    => 'Stealth encrypted icon name',
            'max'     => '',
            'default' => 'Red Diamond',
            'type'    => 'string'
          }
        },
        'desc'  => 'NetStumbler Summary File (text)',
        'modes' => 'r-----'
      },
      'custom' => {
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        }
      },
      'gpsdrive' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'GpsDrive Format',
        'modes' => 'rw----'
      },
      'gtrnctr' => {
        'nmodes' => 4,
        'parent' => 'gtrnctr',
        'desc'   => 'Garmin Training Centerxml',
        'modes'  => '---w--'
      },
      'geonet' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'GEOnet Names Server (GNS)',
        'modes' => 'rw----',
        'ext'   => 'txt'
      },
      'html' => {
        'nmodes'  => 16,
        'parent'  => 'html',
        'options' => {
          'altunits' => {
            'min'     => '',
            'desc'    => 'Units for altitude (f)eet or (m)etres',
            'max'     => '',
            'default' => 'm',
            'type'    => 'string'
          },
          'encrypt' => {
            'min'     => '',
            'desc'    => 'Encrypt hints using ROT13',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'degformat' => {
            'min' => '',
            'desc' =>
             'Degrees output as \'ddd\', \'dmm\'(default) or \'dms\'',
            'max'     => '',
            'default' => 'dmm',
            'type'    => 'string'
          },
          'stylesheet' => {
            'min'     => '',
            'desc'    => 'Path to HTML style sheet',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'logs' => {
            'min'     => '',
            'desc'    => 'Include groundspeak logs if present',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'HTML Output',
        'modes' => '-w----',
        'ext'   => 'html'
      },
      'coto' => {
        'nmodes'  => 56,
        'parent'  => 'coto',
        'options' => {
          'zerocat' => {
            'min'     => '',
            'desc'    => 'Name of the \'unassigned\' category',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'cotoGPS for Palm/OS',
        'modes' => 'rwr---',
        'ext'   => 'pdb'
      },
      'text' => {
        'nmodes'  => 16,
        'parent'  => 'text',
        'options' => {
          'altunits' => {
            'min'     => '',
            'desc'    => 'Units for altitude (f)eet or (m)etres',
            'max'     => '',
            'default' => 'm',
            'type'    => 'string'
          },
          'encrypt' => {
            'min'     => '',
            'desc'    => 'Encrypt hints using ROT13',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'degformat' => {
            'min' => '',
            'desc' =>
             'Degrees output as \'ddd\', \'dmm\'(default) or \'dms\'',
            'max'     => '',
            'default' => 'dmm',
            'type'    => 'string'
          },
          'nosep' => {
            'min'     => '',
            'desc'    => 'Suppress separator lines between waypoints',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'logs' => {
            'min'     => '',
            'desc'    => 'Include groundspeak logs if present',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Textual Output',
        'modes' => '-w----',
        'ext'   => 'txt'
      },
      'geoniche' => {
        'nmodes'  => 48,
        'parent'  => 'geoniche',
        'options' => {
          'category' => {
            'min'     => '',
            'desc'    => 'Category name (Cache)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name (filename)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'GeoNiche .pdb',
        'modes' => 'rw----',
        'ext'   => 'pdb'
      },
      'garmin_poi' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Garmin POI database',
        'modes' => 'rw----'
      },
      'tpo3' => {
        'nmodes' => 42,
        'parent' => 'tpo3',
        'desc'   => 'National Geographic Topo 3.x/4.x .tpo',
        'modes'  => 'r-r-r-',
        'ext'    => 'tpo'
      },
      'raymarine' => {
        'nmodes'  => 51,
        'parent'  => 'raymarine',
        'options' => {
          'location' => {
            'min'     => '',
            'desc'    => 'Default location',
            'max'     => '',
            'default' => 'New location',
            'type'    => 'string'
          }
        },
        'desc'  => 'Raymarine Waypoint File (.rwf)',
        'modes' => 'rw--rw',
        'ext'   => 'rwf'
      },
      'garmin_txt' => {
        'nmodes'  => 63,
        'parent'  => 'garmin_txt',
        'options' => {
          'grid' => {
            'min'     => '',
            'desc'    => 'Write position using this grid.',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'temp' => {
            'min'     => '',
            'desc'    => 'Temperature unit [c=Celsius, f=Fahrenheit]',
            'max'     => '',
            'default' => 'c',
            'type'    => 'string'
          },
          'prec' => {
            'min'     => '',
            'desc'    => 'Precision of coordinates',
            'max'     => '',
            'default' => '3',
            'type'    => 'integer'
          },
          'time' => {
            'min'     => '',
            'desc'    => 'Read/Write time format (i.e. HH:mm:ss xx)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'date' => {
            'min'     => '',
            'desc'    => 'Read/Write date format (i.e. yyyy/mm/dd)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'utc' => {
            'min'     => '-23',
            'desc'    => 'Write timestamps with offset x to UTC time',
            'max'     => '+23',
            'default' => '',
            'type'    => 'integer'
          },
          'dist' => {
            'min'     => '',
            'desc'    => 'Distance unit [m=metric, s=statute]',
            'max'     => '',
            'default' => 'm',
            'type'    => 'string'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string'
          }
        },
        'desc'  => 'Garmin MapSource - txt (tab delimited)',
        'modes' => 'rwrwrw',
        'ext'   => 'txt'
      },
      'magellanx' => {
        'nmodes'  => 63,
        'parent'  => 'magellanx',
        'options' => {
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'maxcmts' => {
            'min'  => '',
            'desc' => 'Max number of comments to write (maxcmts=200)',
            'max'  => '',
            'default' => '',
            'type'    => 'integer'
          }
        },
        'desc'  => 'Magellan SD files (as for eXplorist)',
        'modes' => 'rwrwrw',
        'ext'   => 'upt'
      },
      'magnav' => {
        'nmodes' => 48,
        'parent' => 'magnav',
        'desc'   => 'Magellan NAV Companion for Palm/OS',
        'modes'  => 'rw----',
        'ext'    => 'pdb'
      },
      'maggeo' => {
        'nmodes' => 16,
        'parent' => 'maggeo',
        'desc'   => 'Magellan Explorist Geocaching',
        'modes'  => '-w----',
        'ext'    => 'gs'
      },
      'cambridge' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Cambridge/Winpilot glider software',
        'modes' => 'rw----',
        'ext'   => 'dat'
      },
      'pathaway' => {
        'nmodes'  => 63,
        'parent'  => 'pathaway',
        'options' => {
          'date' => {
            'min'     => '',
            'desc'    => 'Read/Write date format (i.e. DDMMYYYY)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Length of generated shortnames',
            'max'     => '',
            'default' => '10',
            'type'    => 'integer'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'PathAway Database for Palm/OS',
        'modes' => 'rwrwrw',
        'ext'   => 'pdb'
      },
      'gdb' => {
        'nmodes'  => 63,
        'parent'  => 'gdb',
        'options' => {
          'via' => {
            'min' => '',
            'desc' =>
             'Drop route points that do not have an equivalent waypoint (hidden points)',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'cat' => {
            'min'     => '1',
            'desc'    => 'Default category on output (1..16)',
            'max'     => '16',
            'default' => '',
            'type'    => 'integer'
          },
          'ver' => {
            'min'     => '1',
            'desc'    => 'Version of gdb file to generate (1,2)',
            'max'     => '2',
            'default' => '2',
            'type'    => 'integer'
          }
        },
        'desc'  => 'Garmin MapSource - gdb',
        'modes' => 'rwrwrw',
        'ext'   => 'gdb'
      },
      'wbt' => {
        'options' => {
          'erase' => {
            'min'     => '',
            'desc'    => 'Erase device data after download',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        }
      },
      'gpsutil' => {
        'nmodes' => 48,
        'parent' => 'gpsutil',
        'desc'   => 'gpsutil',
        'modes'  => 'rw----'
      },
      'vitosmt' => {
        'nmodes' => 63,
        'parent' => 'vitosmt',
        'desc'   => 'Vito Navigator II tracks',
        'modes'  => 'rwrwrw',
        'ext'    => 'smt'
      },
      'tiger' => {
        'nmodes'  => 48,
        'parent'  => 'tiger',
        'options' => {
          'oldthresh' => {
            'min'     => '',
            'desc'    => 'Days after which points are considered old',
            'max'     => '',
            'default' => '14',
            'type'    => 'integer'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max shortname length when used with -s',
            'max'     => '',
            'default' => '10',
            'type'    => 'integer'
          },
          'ypixels' => {
            'min'     => '',
            'desc'    => 'Height in pixels of map',
            'max'     => '',
            'default' => '768',
            'type'    => 'integer'
          },
          'xpixels' => {
            'min'     => '',
            'desc'    => 'Width in pixels of map',
            'max'     => '',
            'default' => '768',
            'type'    => 'integer'
          },
          'newmarker' => {
            'min'     => '',
            'desc'    => 'Marker type for new points',
            'max'     => '',
            'default' => 'greenpin',
            'type'    => 'string'
          },
          'iconismarker' => {
            'min'     => '',
            'desc'    => 'The icon description is already the marker',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'oldmarker' => {
            'min'     => '',
            'desc'    => 'Marker type for old points',
            'max'     => '',
            'default' => 'redpin',
            'type'    => 'string'
          },
          'genurl' => {
            'min'     => '',
            'desc'    => 'Generate file with lat/lon for centering map',
            'max'     => '',
            'default' => '',
            'type'    => 'outfile'
          },
          'suppresswhite' => {
            'min'     => '',
            'desc'    => 'Suppress whitespace in generated shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'unfoundmarker' => {
            'min'     => '',
            'desc'    => 'Marker type for unfound points',
            'max'     => '',
            'default' => 'bluepin',
            'type'    => 'string'
          },
          'nolabels' => {
            'min'     => '',
            'desc'    => 'Suppress labels on generated pins',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'margin' => {
            'min'     => '',
            'desc'    => 'Margin for map.  Degrees or percentage',
            'max'     => '',
            'default' => '15%',
            'type'    => 'float'
          }
        },
        'desc'  => 'U.S. Census Bureau Tiger Mapping Service',
        'modes' => 'rw----'
      },
      'alanwpr' => {
        'nmodes' => 51,
        'parent' => 'alanwpr',
        'desc'   => 'Alan Map500 waypoints and routes (.wpr)',
        'modes'  => 'rw--rw',
        'ext'    => 'wpr'
      },
      'gpsman' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'GPSman',
        'modes' => 'rw----'
      },
      'gpl' => {
        'nmodes' => 12,
        'parent' => 'gpl',
        'desc'   => 'DeLorme GPL',
        'modes'  => '--rw--',
        'ext'    => 'gpl'
      },
      'vcard' => {
        'nmodes'  => 16,
        'parent'  => 'vcard',
        'options' => {
          'encrypt' => {
            'min'     => '',
            'desc'    => 'Encrypt hints using ROT13',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Vcard Output (for iPod)',
        'modes' => '-w----',
        'ext'   => 'vcf'
      },
      'tef' => {
        'nmodes'  => 2,
        'parent'  => 'tef',
        'options' => {
          'routevia' => {
            'min'     => '',
            'desc'    => 'Include only via stations in route',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Map&Guide \'TourExchangeFormat\' XML',
        'modes' => '----r-',
        'ext'   => 'xml'
      },
      'arc' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'GPSBabel arc filter file',
        'modes' => 'rw----',
        'ext'   => 'txt'
      },
      'kwf2' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Kartex 5 Waypoint File',
        'modes' => 'rw----',
        'ext'   => 'kwf'
      },
      'cup' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'See You flight analysis data',
        'modes' => 'rw----',
        'ext'   => 'cup'
      },
      'quovadis' => {
        'nmodes'  => 48,
        'parent'  => 'quovadis',
        'options' => {
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'Quovadis',
        'modes' => 'rw----',
        'ext'   => 'pdb'
      },
      's_and_t' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Microsoft Streets and Trips 2002-2006',
        'modes' => 'rw----',
        'ext'   => 'txt'
      },
      'tpo2' => {
        'nmodes' => 8,
        'parent' => 'tpo2',
        'desc'   => 'National Geographic Topo 2.x .tpo',
        'modes'  => '--r---',
        'ext'    => 'tpo'
      },
      'cst' => {
        'nmodes' => 42,
        'parent' => 'cst',
        'desc'   => 'CarteSurTable data file',
        'modes'  => 'r-r-r-',
        'ext'    => 'cst'
      },
      'stmwpp' => {
        'nmodes'  => 63,
        'parent'  => 'stmwpp',
        'options' => {
          'index' => {
            'min' => '1',
            'desc' =>
             'Index of route/track to write (if more the one in source)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          }
        },
        'desc'  => 'Suunto Trek Manager (STM) WaypointPlus files',
        'modes' => 'rwrwrw',
        'ext'   => 'txt'
      },
      'ignrando' => {
        'nmodes'  => 12,
        'parent'  => 'ignrando',
        'options' => {
          'index' => {
            'min' => '1',
            'desc' =>
             'Index of track to write (if more the one in source)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          }
        },
        'desc'  => 'IGN Rando track files',
        'modes' => '--rw--',
        'ext'   => 'rdn'
      },
      'navicache' => {
        'nmodes'  => 32,
        'parent'  => 'navicache',
        'options' => {
          'noretired' => {
            'min'     => '',
            'desc'    => 'Suppress retired geocaches',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Navicache.com XML',
        'modes' => 'r-----'
      },
      'psitrex' => {
        'nmodes' => 63,
        'parent' => 'psitrex',
        'desc'   => 'KuDaTa PsiTrex text',
        'modes'  => 'rwrwrw'
      },
      'unicsv' => {
        'nmodes' => 32,
        'parent' => 'unicsv',
        'desc'   => 'Universal csv with field structure in first line',
        'modes'  => 'r-----'
      },
      'tmpro' => {
        'nmodes' => 48,
        'parent' => 'tmpro',
        'desc'   => 'TopoMapPro Places File',
        'modes'  => 'rw----',
        'ext'    => 'tmpro'
      },
      'shape' => {
        'options' => {
          'url' => {
            'min'     => '',
            'desc'    => 'Index of URL field in .dbf',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'name' => {
            'min'     => '',
            'desc'    => 'Index of name field in .dbf',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        }
      },
      'saplus' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'DeLorme Street Atlas Plus',
        'modes' => 'rw----'
      },
      'dna' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Navitrak DNA marker format',
        'modes' => 'rw----',
        'ext'   => 'dna'
      },
      'gtm' => {
        'nmodes' => 63,
        'parent' => 'gtm',
        'desc'   => 'GPS TrackMaker',
        'modes'  => 'rwrwrw',
        'ext'    => 'gtm'
      },
      'compegps' => {
        'nmodes'  => 63,
        'parent'  => 'compegps',
        'options' => {
          'index' => {
            'min' => '1',
            'desc' =>
             'Index of route/track to write (if more the one in source)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'radius' => {
            'min' => '',
            'desc' =>
             'Give points (waypoints/route points) a default radius (proximity)',
            'max'     => '',
            'default' => '',
            'type'    => 'float'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Length of generated shortnames (default 16)',
            'max'     => '',
            'default' => '16',
            'type'    => 'integer'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'CompeGPS data files (.wpt/.trk/.rte)',
        'modes' => 'rwrwrw'
      },
      'copilot' => {
        'nmodes' => 48,
        'parent' => 'copilot',
        'desc'   => 'CoPilot Flight Planner for Palm/OS',
        'modes'  => 'rw----',
        'ext'    => 'pdb'
      },
      'nmea' => {
        'nmodes'  => 60,
        'parent'  => 'nmea',
        'options' => {
          'gpvtg' => {
            'min'     => '',
            'desc'    => 'Read/write GPVTG sentences',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean'
          },
          'baud' => {
            'min' => '',
            'desc' =>
             'Speed in bits per second of serial port (baud=4800)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'date' => {
            'min' => '',
            'desc' =>
             'Complete date-free tracks with given date (YYYYMMDD).',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max length of waypoint name to write',
            'max'     => '64',
            'default' => '6',
            'type'    => 'integer'
          },
          'get_posn' => {
            'min'     => '',
            'desc'    => 'Return current position as a waypoint',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'pause' => {
            'min' => '',
            'desc' =>
             'Decimal seconds to pause between groups of strings',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'gpgga' => {
            'min'     => '',
            'desc'    => 'Read/write GPGGA sentences',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean'
          },
          'gpgsa' => {
            'min'     => '',
            'desc'    => 'Read/write GPGSA sentences',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean'
          },
          'gprmc' => {
            'min'     => '',
            'desc'    => 'Read/write GPRMC sentences',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'NMEA 0183 sentences',
        'modes' => 'rwrw--'
      },
      'mapsource' => {
        'nmodes'  => 63,
        'parent'  => 'mapsource',
        'options' => {
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'mpsverout' => {
            'min'  => '',
            'desc' => 'Version of mapsource file to generate (3,4,5)',
            'max'  => '',
            'default' => '',
            'type'    => 'integer'
          },
          'mpsusedepth' => {
            'min'  => '',
            'desc' => 'Use depth values on output (default is ignore)',
            'max'  => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'mpsuseprox' => {
            'min' => '',
            'desc' =>
             'Use proximity values on output (default is ignore)',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Length of generated shortnames',
            'max'     => '',
            'default' => '10',
            'type'    => 'integer'
          },
          'mpsmergeout' => {
            'min'     => '',
            'desc'    => 'Merge output with existing file',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Garmin MapSource - mps',
        'modes' => 'rwrwrw',
        'ext'   => 'mps'
      },
      'axim_gpb' => {
        'nmodes' => 8,
        'parent' => 'axim_gpb',
        'desc'   => 'Dell Axim Navigation System (.gpb) file format',
        'modes'  => '--r---',
        'ext'    => 'gpb'
      },
      'gpsdrivetrack' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'GpsDrive Format for Tracks',
        'modes' => 'rw----'
      },
      'hiketech' => {
        'nmodes' => 60,
        'parent' => 'hiketech',
        'desc'   => 'HikeTech',
        'modes'  => 'rwrw--',
        'ext'    => 'gps'
      },
      'psp' => {
        'nmodes' => 48,
        'parent' => 'psp',
        'desc'   => 'MS PocketStreets 2002 Pushpin',
        'modes'  => 'rw----',
        'ext'    => 'psp'
      },
      'sportsim' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Sportsim track files (part of zipped .ssz files)',
        'modes' => 'rw----',
        'ext'   => 'txt'
      },
      'ozi' => {
        'nmodes'  => 63,
        'parent'  => 'ozi',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '32',
            'type'    => 'integer'
          },
          'wptbgcolor' => {
            'min'     => '',
            'desc'    => 'Waypoint background color',
            'max'     => '',
            'default' => 'yellow',
            'type'    => 'string'
          },
          'wptfgcolor' => {
            'min'     => '',
            'desc'    => 'Waypoint foreground color',
            'max'     => '',
            'default' => 'black',
            'type'    => 'string'
          }
        },
        'desc'  => 'OziExplorer',
        'modes' => 'rwrwrw'
      },
      'tabsep' => {
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        }
      },
      'coastexp' => {
        'nmodes' => 51,
        'parent' => 'coastexp',
        'desc'   => 'CoastalExplorer XML',
        'modes'  => 'rw--rw'
      },
      'palmdoc' => {
        'nmodes'  => 16,
        'parent'  => 'palmdoc',
        'options' => {
          'encrypt' => {
            'min'     => '',
            'desc'    => 'Encrypt hints with ROT13',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'nosep' => {
            'min'     => '',
            'desc'    => 'No separator lines between waypoints',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'bookmarks_short' => {
            'min'     => '',
            'desc'    => 'Include short name in bookmarks',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'logs' => {
            'min'     => '',
            'desc'    => 'Include groundspeak logs if present',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'PalmDoc Output',
        'modes' => '-w----',
        'ext'   => 'pdb'
      },
      'xcsv' => {
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'style' => {
            'min'     => '',
            'desc'    => 'Full path to XCSV style file',
            'max'     => '',
            'default' => '',
            'type'    => 'file'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        }
      },
      'mapsend' => {
        'nmodes'  => 63,
        'parent'  => 'mapsend',
        'options' => {
          'trkver' => {
            'min'     => '3',
            'desc'    => 'MapSend version TRK file to generate (3,4)',
            'max'     => '4',
            'default' => '4',
            'type'    => 'integer'
          }
        },
        'desc'  => 'Magellan Mapsend',
        'modes' => 'rwrwrw'
      },
      'garmin301' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'Garmin 301 Custom position and heartrate',
        'modes' => 'rw----'
      },
      'nima' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean'
          }
        },
        'desc'  => 'NIMA/GNIS Geographic Names File',
        'modes' => 'rw----'
      },
      'mag_pdb' => {
        'nmodes' => 34,
        'parent' => 'mag_pdb',
        'desc'   => 'Map&Guide to Palm/OS exported files (.pdb)',
        'modes'  => 'r---r-',
        'ext'    => 'pdb'
      },
      'gpilots' => {
        'nmodes'  => 48,
        'parent'  => 'gpilots',
        'options' => {
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string'
          }
        },
        'desc'  => 'GpilotS',
        'modes' => 'rw----',
        'ext'   => 'pdb'
      }
    },
    'for_ext' => {
      'anr'    => ['saroute'],
      'rwf'    => ['raymarine'],
      'tpg'    => ['tpg'],
      'mxf'    => ['mxf'],
      'sdf'    => ['stmsdf'],
      'gpl'    => ['gpl'],
      'bcr'    => ['bcr'],
      'xml'    => [ 'glogbook', 'google', 'tef', 'wfff' ],
      'gpssim' => ['gpssim'],
      'trl'   => [ 'alantrl', 'dmtlog' ],
      'cup'   => ['cup'],
      'pcx'   => ['pcx'],
      'wpt'   => ['xmap'],
      'rte'   => ['nmn4'],
      'kml'   => ['kml'],
      'cst'   => ['cst'],
      'est'   => ['msroute'],
      'gs'    => ['maggeo'],
      'rdn'   => ['ignrando'],
      'gps'   => ['hiketech'],
      'loc'   => [ 'easygps', 'geo' ],
      'tmpro' => ['tmpro'],
      'ov2'   => ['tomtom'],
      'axe'   => ['msroute'],
      'dna'   => ['dna'],
      'gtm'   => ['gtm'],
      'gpx'   => ['gpx'],
      'an1'   => ['an1'],
      'wpo'   => ['holux'],
      'txt'   => [
        'xmap2006', 'fugawi',       'garmin_txt', 'geonet',
        'arc',      'mapconverter', 's_and_t',    'sportsim',
        'stmwpp',   'text'
      ],
      'vcf'  => ['vcard'],
      'html' => ['html'],
      'dat'  => ['cambridge'],
      'gpb'  => ['axim_gpb'],
      'kwf'  => ['kwf2'],
      'psp'  => ['psp'],
      'usr'  => ['lowranceusr'],
      'mps'  => ['mapsource'],
      'upt'  => ['magellanx'],
      'smt'  => ['vitosmt'],
      'ktf'  => ['ktf2'],
      'pdb'  => [
        'cetus',    'copilot', 'coto',     'gcdb',
        'geoniche', 'gpilots', 'gpspilot', 'magnav',
        'mag_pdb',  'palmdoc', 'pathaway', 'quovadis'
      ],
      'wpr' => ['alanwpr'],
      'tpo' => [ 'tpo2', 'tpo3' ],
      'gdb' => ['gdb']
    },
    'filters' => {
      'transform' => {
        'options' => {
          'del' => {
            'desc'  => 'Delete source data after transformation',
            'type'  => 'boolean',
            'valid' => ['N']
          },
          'wpt' => {
            'desc' =>
             'Transform track(s) or route(s) into waypoint(s) [R/T]',
            'type'  => 'string',
            'valid' => []
          },
          'trk' => {
            'desc' =>
             'Transform waypoint(s) or route(s) into tracks(s) [W/R]',
            'type'  => 'string',
            'valid' => []
          },
          'rte' => {
            'desc' =>
             'Transform waypoint(s) or track(s) into route(s) [W/T]',
            'type'  => 'string',
            'valid' => []
          }
        },
        'desc' =>
         'Transform waypoints into a route, tracks into routes, ...'
      },
      'discard' => {
        'options' => {
          'vdop' => {
            'desc'  => 'Suppress waypoints with higher vdop',
            'type'  => 'float',
            'valid' => ['-1.0']
          },
          'hdopandvdop' => {
            'desc'  => 'Link hdop and vdop supression with AND',
            'type'  => 'boolean',
            'valid' => []
          },
          'hdop' => {
            'desc'  => 'Suppress waypoints with higher hdop',
            'type'  => 'float',
            'valid' => ['-1.0']
          }
        },
        'desc' => 'Remove unreliable points with high hdop or vdop'
      },
      'stack' => {
        'options' => {
          'discard' => {
            'desc'  => '(pop) Discard top of stack',
            'type'  => 'boolean',
            'valid' => []
          },
          'depth' => {
            'desc'  => '(swap) Item to use (default=1)',
            'type'  => 'integer',
            'valid' => [ '', '0' ]
          },
          'append' => {
            'desc'  => '(pop) Append list',
            'type'  => 'boolean',
            'valid' => []
          },
          'copy' => {
            'desc'  => '(push) Copy waypoint list',
            'type'  => 'boolean',
            'valid' => []
          },
          'push' => {
            'desc'  => 'Push waypoint list onto stack',
            'type'  => 'boolean',
            'valid' => []
          },
          'replace' => {
            'desc'  => '(pop) Replace list (default)',
            'type'  => 'boolean',
            'valid' => []
          },
          'swap' => {
            'desc'  => 'Swap waypoint list with <depth> item on stack',
            'type'  => 'boolean',
            'valid' => []
          },
          'pop' => {
            'desc'  => 'Pop waypoint list from stack',
            'type'  => 'boolean',
            'valid' => []
          }
        },
        'desc' => 'Save and restore waypoint lists'
      },
      'track' => {
        'options' => {
          'course' => {
            'desc'  => 'Synthesize course',
            'type'  => 'boolean',
            'valid' => []
          },
          'stop' => {
            'desc'  => 'Use only track points before this timestamp',
            'type'  => 'integer',
            'valid' => []
          },
          'move' => {
            'desc'  => 'Correct trackpoint timestamps by a delta',
            'type'  => 'string',
            'valid' => []
          },
          'fix' => {
            'desc'  => 'Synthesize GPS fixes (PPS, DGPS, 3D, 2D, NONE)',
            'type'  => 'string',
            'valid' => []
          },
          'name' => {
            'desc' =>
             'Use only track(s) where title matches given name',
            'type'  => 'string',
            'valid' => []
          },
          'merge' => {
            'desc'  => 'Merge multiple tracks for the same way',
            'type'  => 'string',
            'valid' => []
          },
          'speed' => {
            'desc'  => 'Synthesize speed',
            'type'  => 'boolean',
            'valid' => []
          },
          'sdistance' => {
            'desc'  => 'Split by distance',
            'type'  => 'string',
            'valid' => []
          },
          'title' => {
            'desc'  => 'Basic title for new track(s)',
            'type'  => 'string',
            'valid' => []
          },
          'pack' => {
            'desc'  => 'Pack all tracks into one',
            'type'  => 'boolean',
            'valid' => []
          },
          'split' => {
            'desc'  => 'Split by date or time interval (see README)',
            'type'  => 'string',
            'valid' => []
          },
          'start' => {
            'desc'  => 'Use only track points after this timestamp',
            'type'  => 'integer',
            'valid' => []
          }
        },
        'desc' => 'Manipulate track lists'
      },
      'radius' => {
        'options' => {
          'nosort' => {
            'desc'  => 'Inhibit sort by distance to center',
            'type'  => 'boolean',
            'valid' => []
          },
          'maxcount' => {
            'desc'  => 'Output no more than this number of points',
            'type'  => 'integer',
            'valid' => [ '', '1' ]
          },
          'asroute' => {
            'desc'  => 'Put resulting waypoints in route of this name',
            'type'  => 'string',
            'valid' => []
          },
          'distance' => {
            'desc'  => 'Maximum distance from center',
            'type'  => 'float',
            'valid' => []
          },
          'lat' => {
            'desc'  => 'Latitude for center point (D.DDDDD)',
            'type'  => 'float',
            'valid' => []
          },
          'lon' => {
            'desc'  => 'Longitude for center point (D.DDDDD)',
            'type'  => 'float',
            'valid' => []
          },
          'exclude' => {
            'desc'  => 'Exclude points close to center',
            'type'  => 'boolean',
            'valid' => []
          }
        },
        'desc' => 'Include Only Points Within Radius'
      },
      'position' => {
        'options' => {
          'distance' => {
            'desc'  => 'Maximum positional distance',
            'type'  => 'float',
            'valid' => []
          },
          'all' => {
            'desc'  => 'Suppress all points close to other points',
            'type'  => 'boolean',
            'valid' => []
          }
        },
        'desc' => 'Remove Points Within Distance'
      },
      'reverse'  => { 'desc' => 'Reverse stops within routes' },
      'simplify' => {
        'options' => {
          'length' => {
            'desc'  => 'Use arclength error',
            'type'  => 'boolean',
            'valid' => []
          },
          'count' => {
            'desc'  => 'Maximum number of points in route',
            'type'  => 'integer',
            'valid' => [ '', '1' ]
          },
          'crosstrack' => {
            'desc'  => 'Use cross-track error (default)',
            'type'  => 'boolean',
            'valid' => []
          },
          'error' => {
            'desc'  => 'Maximum error',
            'type'  => 'string',
            'valid' => [ '', '0' ]
          }
        },
        'desc' => 'Simplify routes'
      },
      'sort' => {
        'options' => {
          'shortname' => {
            'desc'  => 'Sort by waypoint short name',
            'type'  => 'boolean',
            'valid' => []
          },
          'time' => {
            'desc'  => 'Sort by time',
            'type'  => 'boolean',
            'valid' => []
          },
          'gcid' => {
            'desc'  => 'Sort by numeric geocache ID',
            'type'  => 'boolean',
            'valid' => []
          },
          'description' => {
            'desc'  => 'Sort by waypoint description',
            'type'  => 'boolean',
            'valid' => []
          }
        },
        'desc' => 'Rearrange waypoints by resorting'
      },
      'nuketypes' => {
        'options' => {
          'waypoints' => {
            'desc'  => 'Remove all waypoints from data stream',
            'type'  => 'boolean',
            'valid' => ['0']
          },
          'routes' => {
            'desc'  => 'Remove all routes from data stream',
            'type'  => 'boolean',
            'valid' => ['0']
          },
          'tracks' => {
            'desc'  => 'Remove all tracks from data stream',
            'type'  => 'boolean',
            'valid' => ['0']
          }
        },
        'desc' => 'Remove all waypoints, tracks, or routes'
      },
      'interpolate' => {
        'options' => {
          'distance' => {
            'desc'  => 'Distance interval in miles or kilometers',
            'type'  => 'string',
            'valid' => []
          },
          'time' => {
            'desc'  => 'Time interval in seconds',
            'type'  => 'integer',
            'valid' => [ '', '0' ]
          },
          'route' => {
            'desc'  => 'Interpolate routes instead',
            'type'  => 'boolean',
            'valid' => []
          }
        },
        'desc' => 'Interpolate between trackpoints'
      },
      'duplicate' => {
        'options' => {
          'shortname' => {
            'desc'  => 'Suppress duplicate waypoints based on name',
            'type'  => 'boolean',
            'valid' => []
          },
          'correct' => {
            'desc'  => 'Use coords from duplicate points',
            'type'  => 'boolean',
            'valid' => []
          },
          'location' => {
            'desc'  => 'Suppress duplicate waypoint based on coords',
            'type'  => 'boolean',
            'valid' => []
          },
          'all' => {
            'desc'  => 'Suppress all instances of duplicates',
            'type'  => 'boolean',
            'valid' => []
          }
        },
        'desc' => 'Remove Duplicates'
      },
      'polygon' => {
        'options' => {
          'file' => {
            'desc'  => 'File containing vertices of polygon',
            'type'  => 'file',
            'valid' => []
          },
          'exclude' => {
            'desc'  => 'Exclude points inside the polygon',
            'type'  => 'boolean',
            'valid' => []
          }
        },
        'desc' => 'Include Only Points Inside Polygon'
      },
      'arc' => {
        'options' => {
          'distance' => {
            'desc'  => 'Maximum distance from arc',
            'type'  => 'float',
            'valid' => []
          },
          'points' => {
            'desc'  => 'Use distance from vertices not lines',
            'type'  => 'boolean',
            'valid' => []
          },
          'file' => {
            'desc'  => 'File containing vertices of arc',
            'type'  => 'file',
            'valid' => []
          },
          'exclude' => {
            'desc'  => 'Exclude points close to the arc',
            'type'  => 'boolean',
            'valid' => []
          }
        },
        'desc' => 'Include Only Points Within Distance of Arc'
      }
    }
  };

  my $ref_info135 = {
    'formats' => {
      'google' => {
        'nmodes' => 8,
        'parent' => 'google',
        'desc'   => 'Google Maps XML',
        'modes'  => '--r---',
        'ext'    => 'xml',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_google.html'
      },
      'nmn4' => {
        'nmodes'  => 3,
        'parent'  => 'nmn4',
        'options' => {
          'index' => {
            'min' => '1',
            'desc' =>
             'Index of route to write (if more the one in source)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmn4.html#fmt_nmn4_o_index'
          }
        },
        'desc'  => 'Navigon Mobile Navigator .rte files',
        'modes' => '----rw',
        'ext'   => 'rte',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_nmn4.html'
      },
      'tpg' => {
        'nmodes'  => 48,
        'parent'  => 'tpg',
        'options' => {
          'datum' => {
            'min'     => '',
            'desc'    => 'Datum (default=NAD27)',
            'max'     => '',
            'default' => 'N. America 1927 mean',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tpg.html#fmt_tpg_o_datum'
          }
        },
        'desc'  => 'National Geographic Topo .tpg (waypoints)',
        'modes' => 'rw----',
        'ext'   => 'tpg',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_tpg.html'
      },
      'mxf' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_prefer_shortnames'
          }
        },
        'desc'  => 'MapTech Exchange Format',
        'modes' => 'rw----',
        'ext'   => 'mxf',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_mxf.html'
      },
      'igc' => {
        'nmodes'  => 15,
        'parent'  => 'igc',
        'options' => {
          'timeadj' => {
            'min' => '',
            'desc' =>
             '(integer sec or \'auto\') Barograph to GPS time diff',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_igc.html#fmt_igc_o_timeadj'
          }
        },
        'desc'  => 'FAI/IGC Flight Recorder Data Format',
        'modes' => '--rwrw',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_igc.html'
      },
      'magellan' => {
        'nmodes'  => 63,
        'parent'  => 'magellan',
        'options' => {
          'nukewpt' => {
            'min'     => '',
            'desc'    => 'Delete all waypoints',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_nukewpt'
          },
          'noack' => {
            'min'     => '',
            'desc'    => 'Suppress use of handshaking in name of speed',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_noack'
          },
          'baud' => {
            'min'     => '',
            'desc'    => 'Numeric value of bitrate (baud=4800)',
            'max'     => '',
            'default' => '4800',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_baud'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_deficon'
          },
          'maxcmts' => {
            'min'  => '',
            'desc' => 'Max number of comments to write (maxcmts=200)',
            'max'  => '',
            'default' => '200',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_maxcmts'
          }
        },
        'desc'  => 'Magellan SD files (as for Meridian)',
        'modes' => 'rwrwrw',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_magellan.html'
      },
      'lowranceusr' => {
        'nmodes'  => 63,
        'parent'  => 'lowranceusr',
        'options' => {
          'merge' => {
            'min'     => '',
            'desc'    => '(USR output) Merge into one segmented track',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_lowranceusr.html#fmt_lowranceusr_o_merge'
          },
          'writeasicons' => {
            'min'     => '',
            'desc'    => 'Treat waypoints as icons on write',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_lowranceusr.html#fmt_lowranceusr_o_writeasicons'
          },
          'ignoreicons' => {
            'min'     => '',
            'desc'    => 'Ignore event marker icons on read',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_lowranceusr.html#fmt_lowranceusr_o_ignoreicons'
          },
          'break' => {
            'min'  => '',
            'desc' => '(USR input) Break segments into separate tracks',
            'max'  => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_lowranceusr.html#fmt_lowranceusr_o_break'
          }
        },
        'desc'  => 'Lowrance USR',
        'modes' => 'rwrwrw',
        'ext'   => 'usr',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_lowranceusr.html'
      },
      'dmtlog' => {
        'nmodes'  => 60,
        'parent'  => 'dmtlog',
        'options' => {
          'index' => {
            'min'     => '1',
            'desc'    => 'Index of track (if more the one in source)',
            'max'     => '',
            'default' => '1',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_dmtlog.html#fmt_dmtlog_o_index'
          }
        },
        'desc'  => 'TrackLogs digital mapping (.trl)',
        'modes' => 'rwrw--',
        'ext'   => 'trl',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_dmtlog.html'
      },
      'vitovtt' => {
        'nmodes' => 8,
        'parent' => 'vitovtt',
        'desc'   => 'Vito SmartMap tracks (.vtt)',
        'modes'  => '--r---',
        'ext'    => 'vtt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_vitovtt.html'
      },
      'garmin' => {
        'options' => {
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_snwhite'
          },
          'power_off' => {
            'min'     => '',
            'desc'    => 'Command unit to power itself down',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_power_off'
          },
          'category' => {
            'min'     => '1',
            'desc'    => 'Category number to use for written waypoints',
            'max'     => '16',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_category'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_deficon'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Length of generated shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_snlen'
          },
          'get_posn' => {
            'min'     => '',
            'desc'    => 'Return current position as a waypoint',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_get_posn'
          }
        }
      },
      'bcr' => {
        'nmodes'  => 3,
        'parent'  => 'bcr',
        'options' => {
          'index' => {
            'min' => '1',
            'desc' =>
             'Index of route to write (if more the one in source)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_bcr.html#fmt_bcr_o_index'
          },
          'radius' => {
            'min' => '',
            'desc' =>
             'Radius of our big earth (default 6371000 meters)',
            'max'     => '',
            'default' => '6371000',
            'type'    => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_bcr.html#fmt_bcr_o_radius'
          },
          'name' => {
            'min'     => '',
            'desc'    => 'New name for the route',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_bcr.html#fmt_bcr_o_name'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_bcr.html#fmt_bcr_o_prefer_shortnames'
          }
        },
        'desc'  => 'Motorrad Routenplaner (Map&Guide) .bcr files',
        'modes' => '----rw',
        'ext'   => 'bcr',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_bcr.html'
      },
      'msroute' => {
        'nmodes' => 2,
        'parent' => 'msroute',
        'desc'   => 'Microsoft Streets and Trips (pin/route reader)',
        'modes'  => '----r-',
        'ext'    => 'est',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_msroute.html'
      },
      'csv' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_prefer_shortnames'
          }
        },
        'desc'  => 'Comma separated values',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_csv.html'
      },
      'tomtom' => {
        'nmodes' => 48,
        'parent' => 'tomtom',
        'desc'   => 'TomTom POI file (.ov2)',
        'modes'  => 'rw----',
        'ext'    => 'ov2',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom.html'
      },
      'gcdb' => {
        'nmodes' => 48,
        'parent' => 'gcdb',
        'desc'   => 'GeocachingDB for Palm/OS',
        'modes'  => 'rw----',
        'ext'    => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gcdb.html'
      },
      'gpssim' => {
        'nmodes'  => 21,
        'parent'  => 'gpssim',
        'options' => {
          'wayptspd' => {
            'min'     => '',
            'desc'    => 'Default speed for waypoints (knots/hr)',
            'max'     => '',
            'default' => '',
            'type'    => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpssim.html#fmt_gpssim_o_wayptspd'
          },
          'split' => {
            'min'     => '',
            'desc'    => 'Split input into separate files',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpssim.html#fmt_gpssim_o_split'
          }
        },
        'desc'  => 'Franson GPSGate Simulation',
        'modes' => '-w-w-w',
        'ext'   => 'gpssim',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gpssim.html'
      },
      'yahoo' => {
        'nmodes'  => 32,
        'parent'  => 'yahoo',
        'options' => {
          'addrsep' => {
            'min' => '',
            'desc' =>
             'String to separate concatenated address fields (default=", ")',
            'max'     => '',
            'default' => ', ',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_yahoo.html#fmt_yahoo_o_addrsep'
          }
        },
        'desc'  => 'Yahoo Geocode API data',
        'modes' => 'r-----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_yahoo.html'
      },
      'wbt-bin' => {
        'nmodes' => 8,
        'parent' => 'wbt-bin',
        'desc'   => 'Wintec WBT-100/200 Binary File Format',
        'modes'  => '--r---',
        'ext'    => 'bin',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_wbt-bin.html'
      },
      'stmsdf' => {
        'nmodes'  => 15,
        'parent'  => 'stmsdf',
        'options' => {
          'index' => {
            'min'     => '1',
            'desc'    => 'Index of route (if more the one in source)',
            'max'     => '',
            'default' => '1',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_stmsdf.html#fmt_stmsdf_o_index'
          }
        },
        'desc'  => 'Suunto Trek Manager (STM) .sdf files',
        'modes' => '--rwrw',
        'ext'   => 'sdf',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_stmsdf.html'
      },
      'easygps' => {
        'nmodes' => 48,
        'parent' => 'easygps',
        'desc'   => 'EasyGPS binary format',
        'modes'  => 'rw----',
        'ext'    => 'loc',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_easygps.html'
      },
      'tomtom_itn' => {
        'nmodes'  => 3,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_prefer_shortnames'
          }
        },
        'desc'  => 'TomTom Itineraries (.itn)',
        'modes' => '----rw',
        'ext'   => 'itn',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html'
      },
      'openoffice' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_prefer_shortnames'
          }
        },
        'desc' =>
         'Tab delimited fields useful for OpenOffice, Ploticus etc.',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html'
      },
      'ktf2' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_prefer_shortnames'
          }
        },
        'desc'  => 'Kartex 5 Track File',
        'modes' => 'rw----',
        'ext'   => 'ktf',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html'
      },
      'geo' => {
        'nmodes'  => 48,
        'parent'  => 'geo',
        'options' => {
          'nuke_placer' => {
            'min'     => '',
            'desc'    => 'Omit Placer name',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geo.html#fmt_geo_o_nuke_placer'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geo.html#fmt_geo_o_deficon'
          }
        },
        'desc'  => 'Geocaching.com .loc',
        'modes' => 'rw----',
        'ext'   => 'loc',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_geo.html'
      },
      'pcx' => {
        'nmodes'  => 63,
        'parent'  => 'pcx',
        'options' => {
          'cartoexploreur' => {
            'min'     => '',
            'desc'    => 'Write tracks compatible with Carto Exploreur',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_pcx.html#fmt_pcx_o_cartoexploreur'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => 'Waypoint',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_pcx.html#fmt_pcx_o_deficon'
          }
        },
        'desc'  => 'Garmin PCX5',
        'modes' => 'rwrwrw',
        'ext'   => 'pcx',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_pcx.html'
      },
      'xmap' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_prefer_shortnames'
          }
        },
        'desc'  => 'DeLorme XMap HH Native .WPT',
        'modes' => 'rw----',
        'ext'   => 'wpt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_xmap.html'
      },
      'holux' => {
        'nmodes' => 48,
        'parent' => 'holux',
        'desc'   => 'Holux (gm-100) .wpo Format',
        'modes'  => 'rw----',
        'ext'    => 'wpo',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_holux.html'
      },
      'gpspilot' => {
        'nmodes'  => 48,
        'parent'  => 'gpspilot',
        'options' => {
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpspilot.html#fmt_gpspilot_o_dbname'
          }
        },
        'desc'  => 'GPSPilot Tracker for Palm/OS',
        'modes' => 'rw----',
        'ext'   => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gpspilot.html'
      },
      'wbt-tk1' => {
        'nmodes' => 8,
        'parent' => 'wbt-tk1',
        'desc'   => 'Wintec WBT-201/G-Rays 2 Binary File Format',
        'modes'  => '--r---',
        'ext'    => 'tk1',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_wbt-tk1.html'
      },
      'kml' => {
        'nmodes'  => 63,
        'parent'  => 'kml',
        'options' => {
          'max_position_points' => {
            'min' => '',
            'desc' =>
             'Retain at most this number of position points  (0 = unlimited)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_max_position_points'
          },
          'line_color' => {
            'min'     => '',
            'desc'    => 'Line color, specified in hex AABBGGRR',
            'max'     => '',
            'default' => '64eeee17',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_line_color'
          },
          'trackdata' => {
            'min' => '',
            'desc' =>
             'Include extended data for trackpoints (default = 1)',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_trackdata'
          },
          'line_width' => {
            'min'     => '',
            'desc'    => 'Width of lines, in pixels',
            'max'     => '',
            'default' => '6',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_line_width'
          },
          'points' => {
            'min'     => '',
            'desc'    => 'Export placemarks for tracks and routes',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_points'
          },
          'lines' => {
            'min'     => '',
            'desc'    => 'Export linestrings for tracks and routes',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_lines'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_deficon'
          },
          'floating' => {
            'min' => '',
            'desc' =>
             'Altitudes are absolute and not clamped to ground',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_floating'
          },
          'labels' => {
            'min' => '',
            'desc' =>
             'Display labels on track and routepoints  (default = 1)',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_labels'
          },
          'extrude' => {
            'min'  => '',
            'desc' => 'Draw extrusion line from trackpoint to ground',
            'max'  => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_extrude'
          },
          'units' => {
            'min' => '',
            'desc' =>
             'Units used when writing comments (\'s\'tatute or \'m\'etric)',
            'max'     => '',
            'default' => 's',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_units'
          }
        },
        'desc'  => 'Google Earth (Keyhole) Markup Language',
        'modes' => 'rwrwrw',
        'ext'   => 'kml',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_kml.html'
      },
      'wfff' => {
        'nmodes'  => 32,
        'parent'  => 'wfff',
        'options' => {
          'snmac' => {
            'min'     => '',
            'desc'    => 'Shortname is MAC address',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_wfff.html#fmt_wfff_o_snmac'
          },
          'ahcicon' => {
            'min'     => '',
            'desc'    => 'Ad-hoc closed icon name',
            'max'     => '',
            'default' => 'Red Diamond',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_wfff.html#fmt_wfff_o_ahcicon'
          },
          'ahoicon' => {
            'min'     => '',
            'desc'    => 'Ad-hoc open icon name',
            'max'     => '',
            'default' => 'Green Diamond',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_wfff.html#fmt_wfff_o_ahoicon'
          },
          'aicicon' => {
            'min'     => '',
            'desc'    => 'Infrastructure closed icon name',
            'max'     => '',
            'default' => 'Red Square',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_wfff.html#fmt_wfff_o_aicicon'
          },
          'aioicon' => {
            'min'     => '',
            'desc'    => 'Infrastructure open icon name',
            'max'     => '',
            'default' => 'Green Square',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_wfff.html#fmt_wfff_o_aioicon'
          }
        },
        'desc'  => 'WiFiFoFum 2.0 for PocketPC XML',
        'modes' => 'r-----',
        'ext'   => 'xml',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_wfff.html'
      },
      'mapconverter' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_prefer_shortnames'
          }
        },
        'desc'  => 'Mapopolis.com Mapconverter CSV',
        'modes' => 'rw----',
        'ext'   => 'txt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html'
      },
      'cetus' => {
        'nmodes'  => 56,
        'parent'  => 'cetus',
        'options' => {
          'appendicon' => {
            'min'     => '',
            'desc'    => 'Append icon_descr to description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cetus.html#fmt_cetus_o_appendicon'
          },
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cetus.html#fmt_cetus_o_dbname'
          }
        },
        'desc'  => 'Cetus for Palm/OS',
        'modes' => 'rwr---',
        'ext'   => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_cetus.html'
      },
      'alantrl' => {
        'nmodes' => 12,
        'parent' => 'alantrl',
        'desc'   => 'Alan Map500 tracklogs (.trl)',
        'modes'  => '--rw--',
        'ext'    => 'trl',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_alantrl.html'
      },
      'glogbook' => {
        'nmodes' => 12,
        'parent' => 'glogbook',
        'desc'   => 'Garmin Logbook XML',
        'modes'  => '--rw--',
        'ext'    => 'xml',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_glogbook.html'
      },
      'fugawi' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_prefer_shortnames'
          }
        },
        'desc'  => 'Fugawi',
        'modes' => 'rw----',
        'ext'   => 'txt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html'
      },
      'xmapwpt' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_prefer_shortnames'
          }
        },
        'desc'  => 'DeLorme XMat HH Street Atlas USA .WPT (PPC)',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html'
      },
      'xmap2006' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_prefer_shortnames'
          }
        },
        'desc'  => 'DeLorme XMap/SAHH 2006 Native .TXT',
        'modes' => 'rw----',
        'ext'   => 'txt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html'
      },
      'saroute' => {
        'nmodes'  => 8,
        'parent'  => 'saroute',
        'options' => {
          'controls' => {
            'min'     => '',
            'desc'    => 'Read control points as waypoint/route/none',
            'max'     => '',
            'default' => 'none',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saroute.html#fmt_saroute_o_controls'
          },
          'times' => {
            'min'     => '',
            'desc'    => 'Synthesize track times',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saroute.html#fmt_saroute_o_times'
          },
          'turns_only' => {
            'min'     => '',
            'desc'    => 'Only read turns; skip all other points',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saroute.html#fmt_saroute_o_turns_only'
          },
          'turns_important' => {
            'min'     => '',
            'desc'    => 'Keep turns if simplify filter is used',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saroute.html#fmt_saroute_o_turns_important'
          },
          'split' => {
            'min'     => '',
            'desc'    => 'Split into multiple routes at turns',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saroute.html#fmt_saroute_o_split'
          }
        },
        'desc'  => 'DeLorme Street Atlas Route',
        'modes' => '--r---',
        'ext'   => 'anr',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_saroute.html'
      },
      'gpx' => {
        'nmodes'  => 63,
        'parent'  => 'gpx',
        'options' => {
          'logpoint' => {
            'min'     => '',
            'desc'    => 'Create waypoints from geocache log entries',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpx.html#fmt_gpx_o_logpoint'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Base URL for link tag in output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpx.html#fmt_gpx_o_urlbase'
          },
          'gpxver' => {
            'min'     => '',
            'desc'    => 'Target GPX version for output',
            'max'     => '',
            'default' => '1.0',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpx.html#fmt_gpx_o_gpxver'
          },
          'suppresswhite' => {
            'min'     => '',
            'desc'    => 'No whitespace in generated shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpx.html#fmt_gpx_o_suppresswhite'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Length of generated shortnames',
            'max'     => '',
            'default' => '32',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpx.html#fmt_gpx_o_snlen'
          }
        },
        'desc'  => 'GPX XML',
        'modes' => 'rwrwrw',
        'ext'   => 'gpx',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gpx.html'
      },
      'an1' => {
        'nmodes'  => 55,
        'parent'  => 'an1',
        'options' => {
          'nogc' => {
            'min'     => '',
            'desc'    => 'Do not add geocache data to description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_nogc'
          },
          'radius' => {
            'min'     => '',
            'desc'    => 'Radius for circles',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_radius'
          },
          'zoom' => {
            'min'     => '',
            'desc'    => 'Zoom level to reduce points',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_zoom'
          },
          'nourl' => {
            'min'     => '',
            'desc'    => 'Do not add URLs to description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_nourl'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Symbol to use for point data',
            'max'     => '',
            'default' => 'Red Flag',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_deficon'
          },
          'wpt_type' => {
            'min'     => '',
            'desc'    => 'Waypoint type',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_wpt_type'
          },
          'color' => {
            'min'     => '',
            'desc'    => 'Color for lines or mapnotes',
            'max'     => '',
            'default' => 'red',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_color'
          },
          'type' => {
            'min'     => '',
            'desc'    => 'Type of .an1 file',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_type'
          },
          'road' => {
            'min'     => '',
            'desc'    => 'Road type changes',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_road'
          }
        },
        'desc'  => 'DeLorme .an1 (drawing) file',
        'modes' => 'rw-wrw',
        'ext'   => 'an1',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_an1.html'
      },
      'hsandv' => {
        'nmodes' => 48,
        'parent' => 'hsandv',
        'desc'   => 'HSA Endeavour Navigator export File',
        'modes'  => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_hsandv.html'
      },
      'netstumbler' => {
        'nmodes'  => 32,
        'parent'  => 'netstumbler',
        'options' => {
          'snmac' => {
            'min'     => '',
            'desc'    => 'Shortname is MAC address',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html#fmt_netstumbler_o_snmac'
          },
          'nseicon' => {
            'min'     => '',
            'desc'    => 'Non-stealth encrypted icon name',
            'max'     => '',
            'default' => 'Red Square',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html#fmt_netstumbler_o_nseicon'
          },
          'nsneicon' => {
            'min'     => '',
            'desc'    => 'Non-stealth non-encrypted icon name',
            'max'     => '',
            'default' => 'Green Square',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html#fmt_netstumbler_o_nsneicon'
          },
          'sneicon' => {
            'min'     => '',
            'desc'    => 'Stealth non-encrypted icon name',
            'max'     => '',
            'default' => 'Green Diamond',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html#fmt_netstumbler_o_sneicon'
          },
          'seicon' => {
            'min'     => '',
            'desc'    => 'Stealth encrypted icon name',
            'max'     => '',
            'default' => 'Red Diamond',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html#fmt_netstumbler_o_seicon'
          }
        },
        'desc'  => 'NetStumbler Summary File (text)',
        'modes' => 'r-----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html'
      },
      'custom' => {
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_prefer_shortnames'
          }
        }
      },
      'tomtom_asc' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_prefer_shortnames'
          }
        },
        'desc'  => 'TomTom POI file (.asc)',
        'modes' => 'rw----',
        'ext'   => 'asc',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html'
      },
      'gpsdrive' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_prefer_shortnames'
          }
        },
        'desc'  => 'GpsDrive Format',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html'
      },
      'gtrnctr' => {
        'nmodes' => 4,
        'parent' => 'gtrnctr',
        'desc'   => 'Garmin Training Centerxml',
        'modes'  => '---w--',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gtrnctr.html'
      },
      'geonet' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_prefer_shortnames'
          }
        },
        'desc'  => 'GEOnet Names Server (GNS)',
        'modes' => 'rw----',
        'ext'   => 'txt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_geonet.html'
      },
      'html' => {
        'nmodes'  => 16,
        'parent'  => 'html',
        'options' => {
          'altunits' => {
            'min'     => '',
            'desc'    => 'Units for altitude (f)eet or (m)etres',
            'max'     => '',
            'default' => 'm',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_html.html#fmt_html_o_altunits'
          },
          'encrypt' => {
            'min'     => '',
            'desc'    => 'Encrypt hints using ROT13',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_html.html#fmt_html_o_encrypt'
          },
          'degformat' => {
            'min' => '',
            'desc' =>
             'Degrees output as \'ddd\', \'dmm\'(default) or \'dms\'',
            'max'     => '',
            'default' => 'dmm',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_html.html#fmt_html_o_degformat'
          },
          'stylesheet' => {
            'min'     => '',
            'desc'    => 'Path to HTML style sheet',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_html.html#fmt_html_o_stylesheet'
          },
          'logs' => {
            'min'     => '',
            'desc'    => 'Include groundspeak logs if present',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_html.html#fmt_html_o_logs'
          }
        },
        'desc'  => 'HTML Output',
        'modes' => '-w----',
        'ext'   => 'html',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_html.html'
      },
      'coto' => {
        'nmodes'  => 56,
        'parent'  => 'coto',
        'options' => {
          'zerocat' => {
            'min'     => '',
            'desc'    => 'Name of the \'unassigned\' category',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'extra'   => [
              'http://www.gpsbabel.org/htmldoc-development/fmt_coto.html#fmt_coto_o_internals'
            ],
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_coto.html#fmt_coto_o_zerocat'
          }
        },
        'desc'  => 'cotoGPS for Palm/OS',
        'modes' => 'rwr---',
        'ext'   => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_coto.html'
      },
      'text' => {
        'nmodes'  => 16,
        'parent'  => 'text',
        'options' => {
          'splitoutput' => {
            'min'     => '',
            'desc'    => 'Write each waypoint in a separate file',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_splitoutput'
          },
          'altunits' => {
            'min'     => '',
            'desc'    => 'Units for altitude (f)eet or (m)etres',
            'max'     => '',
            'default' => 'm',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_altunits'
          },
          'encrypt' => {
            'min'     => '',
            'desc'    => 'Encrypt hints using ROT13',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_encrypt'
          },
          'degformat' => {
            'min' => '',
            'desc' =>
             'Degrees output as \'ddd\', \'dmm\'(default) or \'dms\'',
            'max'     => '',
            'default' => 'dmm',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_degformat'
          },
          'nosep' => {
            'min'     => '',
            'desc'    => 'Suppress separator lines between waypoints',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_nosep'
          },
          'logs' => {
            'min'     => '',
            'desc'    => 'Include groundspeak logs if present',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_logs'
          }
        },
        'desc'  => 'Textual Output',
        'modes' => '-w----',
        'ext'   => 'txt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_text.html'
      },
      'kompass_wp' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_prefer_shortnames'
          }
        },
        'desc'  => 'Kompass (DAV) Waypoints (.wp)',
        'modes' => 'rw----',
        'ext'   => 'wp',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html'
      },
      'g7towin' => {
        'nmodes' => 42,
        'parent' => 'g7towin',
        'desc'   => 'G7ToWin data files (.g7t)',
        'modes'  => 'r-r-r-',
        'ext'    => 'g7t',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_g7towin.html'
      },
      'geoniche' => {
        'nmodes'  => 48,
        'parent'  => 'geoniche',
        'options' => {
          'category' => {
            'min'     => '',
            'desc'    => 'Category name (Cache)',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geoniche.html#fmt_geoniche_o_category'
          },
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name (filename)',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_geoniche.html#fmt_geoniche_o_dbname'
          }
        },
        'desc'  => 'GeoNiche .pdb',
        'modes' => 'rw----',
        'ext'   => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_geoniche.html'
      },
      'garmin_poi' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_prefer_shortnames'
          }
        },
        'desc'  => 'Garmin POI database',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html'
      },
      'tpo3' => {
        'nmodes' => 42,
        'parent' => 'tpo3',
        'desc'   => 'National Geographic Topo 3.x/4.x .tpo',
        'modes'  => 'r-r-r-',
        'ext'    => 'tpo',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_tpo3.html'
      },
      'raymarine' => {
        'nmodes'  => 51,
        'parent'  => 'raymarine',
        'options' => {
          'location' => {
            'min'     => '',
            'desc'    => 'Default location',
            'max'     => '',
            'default' => 'My Waypoints',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_raymarine.html#fmt_raymarine_o_location'
          }
        },
        'desc'  => 'Raymarine Waypoint File (.rwf)',
        'modes' => 'rw--rw',
        'ext'   => 'rwf',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_raymarine.html'
      },
      'garmin_txt' => {
        'nmodes'  => 63,
        'parent'  => 'garmin_txt',
        'options' => {
          'grid' => {
            'min'     => '',
            'desc'    => 'Write position using this grid.',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_grid'
          },
          'temp' => {
            'min'     => '',
            'desc'    => 'Temperature unit [c=Celsius, f=Fahrenheit]',
            'max'     => '',
            'default' => 'c',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_temp'
          },
          'prec' => {
            'min'     => '',
            'desc'    => 'Precision of coordinates',
            'max'     => '',
            'default' => '3',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_prec'
          },
          'time' => {
            'min'     => '',
            'desc'    => 'Read/Write time format (i.e. HH:mm:ss xx)',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_time'
          },
          'date' => {
            'min'     => '',
            'desc'    => 'Read/Write date format (i.e. yyyy/mm/dd)',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_date'
          },
          'utc' => {
            'min'     => '-23',
            'desc'    => 'Write timestamps with offset x to UTC time',
            'max'     => '+23',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_utc'
          },
          'dist' => {
            'min'     => '',
            'desc'    => 'Distance unit [m=metric, s=statute]',
            'max'     => '',
            'default' => 'm',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_dist'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_datum'
          }
        },
        'desc'  => 'Garmin MapSource - txt (tab delimited)',
        'modes' => 'rwrwrw',
        'ext'   => 'txt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html'
      },
      'magellanx' => {
        'nmodes'  => 63,
        'parent'  => 'magellanx',
        'options' => {
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_magellanx.html#fmt_magellanx_o_deficon'
          },
          'maxcmts' => {
            'min'  => '',
            'desc' => 'Max number of comments to write (maxcmts=200)',
            'max'  => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_magellanx.html#fmt_magellanx_o_maxcmts'
          }
        },
        'desc'  => 'Magellan SD files (as for eXplorist)',
        'modes' => 'rwrwrw',
        'ext'   => 'upt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_magellanx.html'
      },
      'magnav' => {
        'nmodes' => 48,
        'parent' => 'magnav',
        'desc'   => 'Magellan NAV Companion for Palm/OS',
        'modes'  => 'rw----',
        'ext'    => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_magnav.html'
      },
      'maggeo' => {
        'nmodes' => 16,
        'parent' => 'maggeo',
        'desc'   => 'Magellan Explorist Geocaching',
        'modes'  => '-w----',
        'ext'    => 'gs',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_maggeo.html'
      },
      'cambridge' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_prefer_shortnames'
          }
        },
        'desc'  => 'Cambridge/Winpilot glider software',
        'modes' => 'rw----',
        'ext'   => 'dat',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html'
      },
      'pathaway' => {
        'nmodes'  => 63,
        'parent'  => 'pathaway',
        'options' => {
          'date' => {
            'min'     => '',
            'desc'    => 'Read/Write date format (i.e. DDMMYYYY)',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_pathaway.html#fmt_pathaway_o_date'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Length of generated shortnames',
            'max'     => '',
            'default' => '10',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_pathaway.html#fmt_pathaway_o_snlen'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_pathaway.html#fmt_pathaway_o_deficon'
          },
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_pathaway.html#fmt_pathaway_o_dbname'
          }
        },
        'desc'  => 'PathAway Database for Palm/OS',
        'modes' => 'rwrwrw',
        'ext'   => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_pathaway.html'
      },
      'gdb' => {
        'nmodes'  => 63,
        'parent'  => 'gdb',
        'options' => {
          'via' => {
            'min' => '',
            'desc' =>
             'Drop route points that do not have an equivalent waypoint (hidden points)',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gdb.html#fmt_gdb_o_via'
          },
          'cat' => {
            'min'     => '1',
            'desc'    => 'Default category on output (1..16)',
            'max'     => '16',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gdb.html#fmt_gdb_o_cat'
          },
          'roadbook' => {
            'min' => '',
            'desc' =>
             'Include major turn points (with description) from calculated route',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gdb.html#fmt_gdb_o_roadbook'
          },
          'ver' => {
            'min'     => '1',
            'desc'    => 'Version of gdb file to generate (1..3)',
            'max'     => '3',
            'default' => '2',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gdb.html#fmt_gdb_o_ver'
          }
        },
        'desc'  => 'Garmin MapSource - gdb',
        'modes' => 'rwrwrw',
        'ext'   => 'gdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gdb.html'
      },
      'wbt' => {
        'options' => {
          'erase' => {
            'min'     => '',
            'desc'    => 'Erase device data after download',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_wbt.html#fmt_wbt_o_erase'
          }
        }
      },
      'xol' => {
        'nmodes' => 60,
        'parent' => 'xol',
        'desc'   => 'Swiss Map # (.xol) format',
        'modes'  => 'rwrw--',
        'ext'    => 'xol',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_xol.html'
      },
      'gpsutil' => {
        'nmodes' => 48,
        'parent' => 'gpsutil',
        'desc'   => 'gpsutil',
        'modes'  => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gpsutil.html'
      },
      'vitosmt' => {
        'nmodes' => 63,
        'parent' => 'vitosmt',
        'desc'   => 'Vito Navigator II tracks',
        'modes'  => 'rwrwrw',
        'ext'    => 'smt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_vitosmt.html'
      },
      'ggv_log' => {
        'nmodes' => 12,
        'parent' => 'ggv_log',
        'desc'   => 'Geogrid Viewer tracklogs (.log)',
        'modes'  => '--rw--',
        'ext'    => 'log',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_ggv_log.html'
      },
      'tiger' => {
        'nmodes'  => 48,
        'parent'  => 'tiger',
        'options' => {
          'oldthresh' => {
            'min'     => '',
            'desc'    => 'Days after which points are considered old',
            'max'     => '',
            'default' => '14',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_oldthresh'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max shortname length when used with -s',
            'max'     => '',
            'default' => '10',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_snlen'
          },
          'ypixels' => {
            'min'     => '',
            'desc'    => 'Height in pixels of map',
            'max'     => '',
            'default' => '768',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_ypixels'
          },
          'xpixels' => {
            'min'     => '',
            'desc'    => 'Width in pixels of map',
            'max'     => '',
            'default' => '768',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_xpixels'
          },
          'newmarker' => {
            'min'     => '',
            'desc'    => 'Marker type for new points',
            'max'     => '',
            'default' => 'greenpin',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_newmarker'
          },
          'iconismarker' => {
            'min'     => '',
            'desc'    => 'The icon description is already the marker',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_iconismarker'
          },
          'oldmarker' => {
            'min'     => '',
            'desc'    => 'Marker type for old points',
            'max'     => '',
            'default' => 'redpin',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_oldmarker'
          },
          'genurl' => {
            'min'     => '',
            'desc'    => 'Generate file with lat/lon for centering map',
            'max'     => '',
            'default' => '',
            'type'    => 'outfile',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_genurl'
          },
          'suppresswhite' => {
            'min'     => '',
            'desc'    => 'Suppress whitespace in generated shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_suppresswhite'
          },
          'unfoundmarker' => {
            'min'     => '',
            'desc'    => 'Marker type for unfound points',
            'max'     => '',
            'default' => 'bluepin',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_unfoundmarker'
          },
          'nolabels' => {
            'min'     => '',
            'desc'    => 'Suppress labels on generated pins',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_nolabels'
          },
          'margin' => {
            'min'     => '',
            'desc'    => 'Margin for map.  Degrees or percentage',
            'max'     => '',
            'default' => '15%',
            'type'    => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_margin'
          }
        },
        'desc'  => 'U.S. Census Bureau Tiger Mapping Service',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_tiger.html'
      },
      'alanwpr' => {
        'nmodes' => 51,
        'parent' => 'alanwpr',
        'desc'   => 'Alan Map500 waypoints and routes (.wpr)',
        'modes'  => 'rw--rw',
        'ext'    => 'wpr',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_alanwpr.html'
      },
      'gpsman' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_prefer_shortnames'
          }
        },
        'desc'  => 'GPSman',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html'
      },
      'gpl' => {
        'nmodes' => 12,
        'parent' => 'gpl',
        'desc'   => 'DeLorme GPL',
        'modes'  => '--rw--',
        'ext'    => 'gpl',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gpl.html'
      },
      'vcard' => {
        'nmodes'  => 16,
        'parent'  => 'vcard',
        'options' => {
          'encrypt' => {
            'min'     => '',
            'desc'    => 'Encrypt hints using ROT13',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_vcard.html#fmt_vcard_o_encrypt'
          }
        },
        'desc'  => 'Vcard Output (for iPod)',
        'modes' => '-w----',
        'ext'   => 'vcf',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_vcard.html'
      },
      'tef' => {
        'nmodes'  => 2,
        'parent'  => 'tef',
        'options' => {
          'routevia' => {
            'min'     => '',
            'desc'    => 'Include only via stations in route',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tef.html#fmt_tef_o_routevia'
          }
        },
        'desc'  => 'Map&Guide \'TourExchangeFormat\' XML',
        'modes' => '----r-',
        'ext'   => 'xml',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_tef.html'
      },
      'arc' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_prefer_shortnames'
          }
        },
        'desc'  => 'GPSBabel arc filter file',
        'modes' => 'rw----',
        'ext'   => 'txt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html'
      },
      'kwf2' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_prefer_shortnames'
          }
        },
        'desc'  => 'Kartex 5 Waypoint File',
        'modes' => 'rw----',
        'ext'   => 'kwf',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html'
      },
      'cup' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_prefer_shortnames'
          }
        },
        'desc'  => 'See You flight analysis data',
        'modes' => 'rw----',
        'ext'   => 'cup',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_cup.html'
      },
      'quovadis' => {
        'nmodes'  => 48,
        'parent'  => 'quovadis',
        'options' => {
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_quovadis.html#fmt_quovadis_o_dbname'
          }
        },
        'desc'  => 'Quovadis',
        'modes' => 'rw----',
        'ext'   => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_quovadis.html'
      },
      's_and_t' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_prefer_shortnames'
          }
        },
        'desc'  => 'Microsoft Streets and Trips 2002-2006',
        'modes' => 'rw----',
        'ext'   => 'txt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html'
      },
      'tpo2' => {
        'nmodes' => 8,
        'parent' => 'tpo2',
        'desc'   => 'National Geographic Topo 2.x .tpo',
        'modes'  => '--r---',
        'ext'    => 'tpo',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_tpo2.html'
      },
      'cst' => {
        'nmodes' => 42,
        'parent' => 'cst',
        'desc'   => 'CarteSurTable data file',
        'modes'  => 'r-r-r-',
        'ext'    => 'cst',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_cst.html'
      },
      'stmwpp' => {
        'nmodes'  => 63,
        'parent'  => 'stmwpp',
        'options' => {
          'index' => {
            'min' => '1',
            'desc' =>
             'Index of route/track to write (if more the one in source)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_stmwpp.html#fmt_stmwpp_o_index'
          }
        },
        'desc'  => 'Suunto Trek Manager (STM) WaypointPlus files',
        'modes' => 'rwrwrw',
        'ext'   => 'txt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_stmwpp.html'
      },
      'ignrando' => {
        'nmodes'  => 12,
        'parent'  => 'ignrando',
        'options' => {
          'index' => {
            'min' => '1',
            'desc' =>
             'Index of track to write (if more the one in source)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ignrando.html#fmt_ignrando_o_index'
          }
        },
        'desc'  => 'IGN Rando track files',
        'modes' => '--rw--',
        'ext'   => 'rdn',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_ignrando.html'
      },
      'navicache' => {
        'nmodes'  => 32,
        'parent'  => 'navicache',
        'options' => {
          'noretired' => {
            'min'     => '',
            'desc'    => 'Suppress retired geocaches',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_navicache.html#fmt_navicache_o_noretired'
          }
        },
        'desc'  => 'Navicache.com XML',
        'modes' => 'r-----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_navicache.html'
      },
      'psitrex' => {
        'nmodes' => 63,
        'parent' => 'psitrex',
        'desc'   => 'KuDaTa PsiTrex text',
        'modes'  => 'rwrwrw',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_psitrex.html'
      },
      'unicsv' => {
        'nmodes'  => 63,
        'parent'  => 'unicsv',
        'options' => {
          'grid' => {
            'min'     => '',
            'desc'    => 'Write position using this grid.',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_unicsv.html#fmt_unicsv_o_grid'
          },
          'utc' => {
            'min'     => '-23',
            'desc'    => 'Write timestamps with offset x to UTC time',
            'max'     => '+23',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_unicsv.html#fmt_unicsv_o_utc'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_unicsv.html#fmt_unicsv_o_datum'
          }
        },
        'desc'  => 'Universal csv with field structure in first line',
        'modes' => 'rwrwrw',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_unicsv.html'
      },
      'tmpro' => {
        'nmodes' => 48,
        'parent' => 'tmpro',
        'desc'   => 'TopoMapPro Places File',
        'modes'  => 'rw----',
        'ext'    => 'tmpro',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_tmpro.html'
      },
      'shape' => {
        'options' => {
          'url' => {
            'min'     => '',
            'desc'    => 'Index of URL field in .dbf',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_shape.html#fmt_shape_o_url'
          },
          'name' => {
            'min'     => '',
            'desc'    => 'Index of name field in .dbf',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_shape.html#fmt_shape_o_name'
          }
        }
      },
      'lmx' => {
        'nmodes' => 48,
        'parent' => 'lmx',
        'desc'   => 'Nokia Landmark Exchange',
        'modes'  => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_lmx.html'
      },
      'saplus' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_prefer_shortnames'
          }
        },
        'desc'  => 'DeLorme Street Atlas Plus',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_saplus.html'
      },
      'dna' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_prefer_shortnames'
          }
        },
        'desc'  => 'Navitrak DNA marker format',
        'modes' => 'rw----',
        'ext'   => 'dna',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_dna.html'
      },
      'gtm' => {
        'nmodes' => 63,
        'parent' => 'gtm',
        'desc'   => 'GPS TrackMaker',
        'modes'  => 'rwrwrw',
        'ext'    => 'gtm',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gtm.html'
      },
      'compegps' => {
        'nmodes'  => 63,
        'parent'  => 'compegps',
        'options' => {
          'index' => {
            'min' => '1',
            'desc' =>
             'Index of route/track to write (if more the one in source)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_compegps.html#fmt_compegps_o_index'
          },
          'radius' => {
            'min' => '',
            'desc' =>
             'Give points (waypoints/route points) a default radius (proximity)',
            'max'     => '',
            'default' => '',
            'type'    => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_compegps.html#fmt_compegps_o_radius'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Length of generated shortnames (default 16)',
            'max'     => '',
            'default' => '16',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_compegps.html#fmt_compegps_o_snlen'
          },
          'deficon' => {
            'min'     => '',
            'desc'    => 'Default icon name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_compegps.html#fmt_compegps_o_deficon'
          }
        },
        'desc'  => 'CompeGPS data files (.wpt/.trk/.rte)',
        'modes' => 'rwrwrw',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_compegps.html'
      },
      'copilot' => {
        'nmodes' => 48,
        'parent' => 'copilot',
        'desc'   => 'CoPilot Flight Planner for Palm/OS',
        'modes'  => 'rw----',
        'ext'    => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_copilot.html'
      },
      'nmea' => {
        'nmodes'  => 60,
        'parent'  => 'nmea',
        'options' => {
          'gpvtg' => {
            'min'     => '',
            'desc'    => 'Read/write GPVTG sentences',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_gpvtg'
          },
          'baud' => {
            'min' => '',
            'desc' =>
             'Speed in bits per second of serial port (baud=4800)',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_baud'
          },
          'date' => {
            'min' => '',
            'desc' =>
             'Complete date-free tracks with given date (YYYYMMDD).',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_date'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max length of waypoint name to write',
            'max'     => '64',
            'default' => '6',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_snlen'
          },
          'get_posn' => {
            'min'     => '',
            'desc'    => 'Return current position as a waypoint',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_get_posn'
          },
          'append_positioning' => {
            'min' => '',
            'desc' =>
             'Append realtime positioning data to the output file instead of truncating',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_append_positioning'
          },
          'pause' => {
            'min' => '',
            'desc' =>
             'Decimal seconds to pause between groups of strings',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_pause'
          },
          'gpgga' => {
            'min'     => '',
            'desc'    => 'Read/write GPGGA sentences',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_gpgga'
          },
          'gpgsa' => {
            'min'     => '',
            'desc'    => 'Read/write GPGSA sentences',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_gpgsa'
          },
          'gprmc' => {
            'min'     => '',
            'desc'    => 'Read/write GPRMC sentences',
            'max'     => '',
            'default' => '1',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_gprmc'
          }
        },
        'desc'  => 'NMEA 0183 sentences',
        'modes' => 'rwrw--',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_nmea.html'
      },
      'mapsource' => {
        'nmodes'  => 63,
        'parent'  => 'mapsource',
        'options' => {
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_snwhite'
          },
          'mpsverout' => {
            'min'  => '',
            'desc' => 'Version of mapsource file to generate (3,4,5)',
            'max'  => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_mpsverout'
          },
          'mpsusedepth' => {
            'min'  => '',
            'desc' => 'Use depth values on output (default is ignore)',
            'max'  => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_mpsusedepth'
          },
          'mpsuseprox' => {
            'min' => '',
            'desc' =>
             'Use proximity values on output (default is ignore)',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_mpsuseprox'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Length of generated shortnames',
            'max'     => '',
            'default' => '10',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_snlen'
          },
          'mpsmergeout' => {
            'min'     => '',
            'desc'    => 'Merge output with existing file',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_mpsmergeout'
          }
        },
        'desc'  => 'Garmin MapSource - mps',
        'modes' => 'rwrwrw',
        'ext'   => 'mps',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html'
      },
      'axim_gpb' => {
        'nmodes' => 8,
        'parent' => 'axim_gpb',
        'desc'   => 'Dell Axim Navigation System (.gpb) file format',
        'modes'  => '--r---',
        'ext'    => 'gpb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_axim_gpb.html'
      },
      'gpsdrivetrack' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_prefer_shortnames'
          }
        },
        'desc'  => 'GpsDrive Format for Tracks',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html'
      },
      'hiketech' => {
        'nmodes' => 60,
        'parent' => 'hiketech',
        'desc'   => 'HikeTech',
        'modes'  => 'rwrw--',
        'ext'    => 'gps',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_hiketech.html'
      },
      'random' => {
        'options' => {
          'points' => {
            'min'     => '1',
            'desc'    => 'Generate # points',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_random.html#fmt_random_o_points'
          },
          'seed' => {
            'min'  => '1',
            'desc' => 'Starting seed of the internal number generator',
            'max'  => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_random.html#fmt_random_o_seed'
          }
        }
      },
      'kompass_tk' => {
        'nmodes'  => 12,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_prefer_shortnames'
          }
        },
        'desc'  => 'Kompass (DAV) Track (.tk)',
        'modes' => '--rw--',
        'ext'   => 'wp',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html'
      },
      'dg-100' => {
        'options' => {
          'erase' => {
            'min'     => '',
            'desc'    => 'Erase device data after download',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_dg-100.html#fmt_dg-100_o_erase'
          }
        }
      },
      'psp' => {
        'nmodes' => 48,
        'parent' => 'psp',
        'desc'   => 'MS PocketStreets 2002 Pushpin',
        'modes'  => 'rw----',
        'ext'    => 'psp',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_psp.html'
      },
      'sportsim' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_prefer_shortnames'
          }
        },
        'desc'  => 'Sportsim track files (part of zipped .ssz files)',
        'modes' => 'rw----',
        'ext'   => 'txt',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html'
      },
      'ozi' => {
        'nmodes'  => 63,
        'parent'  => 'ozi',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_snwhite'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_snupper'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '32',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_snlen'
          },
          'pack' => {
            'min'     => '',
            'desc'    => 'Write all tracks into one file',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_pack'
          },
          'wptbgcolor' => {
            'min'     => '',
            'desc'    => 'Waypoint background color',
            'max'     => '',
            'default' => 'yellow',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_wptbgcolor'
          },
          'wptfgcolor' => {
            'min'     => '',
            'desc'    => 'Waypoint foreground color',
            'max'     => '',
            'default' => 'black',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_wptfgcolor'
          }
        },
        'desc'  => 'OziExplorer',
        'modes' => 'rwrwrw',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_ozi.html'
      },
      'tabsep' => {
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_prefer_shortnames'
          }
        }
      },
      'coastexp' => {
        'nmodes' => 51,
        'parent' => 'coastexp',
        'desc'   => 'CoastalExplorer XML',
        'modes'  => 'rw--rw',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_coastexp.html'
      },
      'palmdoc' => {
        'nmodes'  => 16,
        'parent'  => 'palmdoc',
        'options' => {
          'encrypt' => {
            'min'     => '',
            'desc'    => 'Encrypt hints with ROT13',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html#fmt_palmdoc_o_encrypt'
          },
          'nosep' => {
            'min'     => '',
            'desc'    => 'No separator lines between waypoints',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html#fmt_palmdoc_o_nosep'
          },
          'bookmarks_short' => {
            'min'     => '',
            'desc'    => 'Include short name in bookmarks',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html#fmt_palmdoc_o_bookmarks_short'
          },
          'logs' => {
            'min'     => '',
            'desc'    => 'Include groundspeak logs if present',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html#fmt_palmdoc_o_logs'
          },
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html#fmt_palmdoc_o_dbname'
          }
        },
        'desc'  => 'PalmDoc Output',
        'modes' => '-w----',
        'ext'   => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html'
      },
      'xcsv' => {
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_snunique'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_urlbase'
          },
          'style' => {
            'min'     => '',
            'desc'    => 'Full path to XCSV style file',
            'max'     => '',
            'default' => '',
            'type'    => 'file',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_style'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_prefer_shortnames'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_snwhite'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_datum'
          }
        }
      },
      'mapsend' => {
        'nmodes'  => 63,
        'parent'  => 'mapsend',
        'options' => {
          'trkver' => {
            'min'     => '3',
            'desc'    => 'MapSend version TRK file to generate (3,4)',
            'max'     => '4',
            'default' => '4',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_mapsend.html#fmt_mapsend_o_trkver'
          }
        },
        'desc'  => 'Magellan Mapsend',
        'modes' => 'rwrwrw',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_mapsend.html'
      },
      'garmin301' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_prefer_shortnames'
          }
        },
        'desc'  => 'Garmin 301 Custom position and heartrate',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html'
      },
      'nima' => {
        'nmodes'  => 48,
        'parent'  => 'xcsv',
        'options' => {
          'snunique' => {
            'min'     => '',
            'desc'    => 'Make synth. shortnames unique',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_snunique'
          },
          'snwhite' => {
            'min'     => '',
            'desc'    => 'Allow whitespace synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_snwhite'
          },
          'urlbase' => {
            'min'     => '',
            'desc'    => 'Basename prepended to URL on output',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_urlbase'
          },
          'snupper' => {
            'min'     => '',
            'desc'    => 'UPPERCASE synth. shortnames',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_snupper'
          },
          'datum' => {
            'min'     => '',
            'desc'    => 'GPS datum (def. WGS 84)',
            'max'     => '',
            'default' => 'WGS 84',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_datum'
          },
          'snlen' => {
            'min'     => '1',
            'desc'    => 'Max synthesized shortname length',
            'max'     => '',
            'default' => '',
            'type'    => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_snlen'
          },
          'prefer_shortnames' => {
            'min'     => '',
            'desc'    => 'Use shortname instead of description',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_prefer_shortnames'
          }
        },
        'desc'  => 'NIMA/GNIS Geographic Names File',
        'modes' => 'rw----',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_nima.html'
      },
      'mag_pdb' => {
        'nmodes' => 34,
        'parent' => 'mag_pdb',
        'desc'   => 'Map&Guide to Palm/OS exported files (.pdb)',
        'modes'  => 'r---r-',
        'ext'    => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_mag_pdb.html'
      },
      'garmin_gpi' => {
        'nmodes'  => 48,
        'parent'  => 'garmin_gpi',
        'options' => {
          'notes' => {
            'min'     => '',
            'desc'    => 'Write notes to address field',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_notes'
          },
          'hide' => {
            'min'     => '',
            'desc'    => 'Don\'t show gpi bitmap on device',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_hide'
          },
          'position' => {
            'min'     => '',
            'desc'    => 'Write position to address field',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_position'
          },
          'category' => {
            'min'     => '',
            'desc'    => 'Default category on output',
            'max'     => '',
            'default' => 'My points',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_category'
          },
          'bitmap' => {
            'min'     => '',
            'desc'    => 'Use specified bitmap on output',
            'max'     => '',
            'default' => '',
            'type'    => 'file',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_bitmap'
          },
          'descr' => {
            'min'     => '',
            'desc'    => 'Write description to address field',
            'max'     => '',
            'default' => '',
            'type'    => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_descr'
          }
        },
        'desc'  => 'Garmin Points of Interest (.gpi)',
        'modes' => 'rw----',
        'ext'   => 'gpi',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html'
      },
      'gpilots' => {
        'nmodes'  => 48,
        'parent'  => 'gpilots',
        'options' => {
          'dbname' => {
            'min'     => '',
            'desc'    => 'Database name',
            'max'     => '',
            'default' => '',
            'type'    => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_gpilots.html#fmt_gpilots_o_dbname'
          }
        },
        'desc'  => 'GpilotS',
        'modes' => 'rw----',
        'ext'   => 'pdb',
        'doclink' =>
         'http://www.gpsbabel.org/htmldoc-development/fmt_gpilots.html'
      }
    },
    'for_ext' => {
      'anr'    => ['saroute'],
      'xol'    => ['xol'],
      'rwf'    => ['raymarine'],
      'tpg'    => ['tpg'],
      'mxf'    => ['mxf'],
      'bin'    => ['wbt-bin'],
      'tk1'    => ['wbt-tk1'],
      'sdf'    => ['stmsdf'],
      'gpl'    => ['gpl'],
      'bcr'    => ['bcr'],
      'xml'    => [ 'glogbook', 'google', 'tef', 'wfff' ],
      'gpssim' => ['gpssim'],
      'trl'   => [ 'alantrl',    'dmtlog' ],
      'vtt'   => ['vitovtt'],
      'cup'   => ['cup'],
      'pcx'   => ['pcx'],
      'wpt'   => ['xmap'],
      'rte'   => ['nmn4'],
      'kml'   => ['kml'],
      'cst'   => ['cst'],
      'est'   => ['msroute'],
      'gs'    => ['maggeo'],
      'rdn'   => ['ignrando'],
      'gps'   => ['hiketech'],
      'loc'   => [ 'easygps',    'geo' ],
      'wp'    => [ 'kompass_tk', 'kompass_wp' ],
      'tmpro' => ['tmpro'],
      'ov2'   => ['tomtom'],
      'axe'   => ['msroute'],
      'dna'   => ['dna'],
      'gpi'   => ['garmin_gpi'],
      'gtm'   => ['gtm'],
      'gpx'   => ['gpx'],
      'an1'   => ['an1'],
      'wpo'   => ['holux'],
      'txt'   => [
        'xmap2006', 'fugawi',       'garmin_txt', 'geonet',
        'arc',      'mapconverter', 's_and_t',    'sportsim',
        'stmwpp',   'text'
      ],
      'vcf'  => ['vcard'],
      'asc'  => ['tomtom_asc'],
      'html' => ['html'],
      'itn'  => ['tomtom_itn'],
      'dat'  => ['cambridge'],
      'gpb'  => ['axim_gpb'],
      'log'  => ['ggv_log'],
      'kwf'  => ['kwf2'],
      'psp'  => ['psp'],
      'usr'  => ['lowranceusr'],
      'mps'  => ['mapsource'],
      'upt'  => ['magellanx'],
      'smt'  => ['vitosmt'],
      'ktf'  => ['ktf2'],
      'g7t'  => ['g7towin'],
      'pdb'  => [
        'cetus',    'copilot', 'coto',     'gcdb',
        'geoniche', 'gpilots', 'gpspilot', 'magnav',
        'mag_pdb',  'palmdoc', 'pathaway', 'quovadis'
      ],
      'wpr' => ['alanwpr'],
      'tpo' => [ 'tpo2', 'tpo3' ],
      'gdb' => ['gdb']
    },
    'filters' => {
      'transform' => {
        'options' => {
          'del' => {
            'desc' => 'Delete source data after transformation',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_transform.html#fmt_transform_o_del',
            'valid' => [ 'N', '', '' ]
          },
          'wpt' => {
            'desc' =>
             'Transform track(s) or route(s) into waypoint(s) [R/T]',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_transform.html#fmt_transform_o_wpt',
            'valid' => [ '', '', '' ]
          },
          'trk' => {
            'desc' =>
             'Transform waypoint(s) or route(s) into tracks(s) [W/R]',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_transform.html#fmt_transform_o_trk',
            'valid' => [ '', '', '' ]
          },
          'rte' => {
            'desc' =>
             'Transform waypoint(s) or track(s) into route(s) [W/T]',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_transform.html#fmt_transform_o_rte',
            'valid' => [ '', '', '' ]
          }
        },
        'desc' =>
         'Transform waypoints into a route, tracks into routes, ...'
      },
      'discard' => {
        'options' => {
          'vdop' => {
            'desc' => 'Suppress waypoints with higher vdop',
            'type' => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_discard.html#fmt_discard_o_vdop',
            'valid' => [ '-1.0', '', '' ]
          },
          'hdopandvdop' => {
            'desc' => 'Link hdop and vdop supression with AND',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_discard.html#fmt_discard_o_hdopandvdop',
            'valid' => [ '', '', '' ]
          },
          'hdop' => {
            'desc' => 'Suppress waypoints with higher hdop',
            'type' => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_discard.html#fmt_discard_o_hdop',
            'valid' => [ '-1.0', '', '' ]
          }
        },
        'desc' => 'Remove unreliable points with high hdop or vdop'
      },
      'stack' => {
        'options' => {
          'discard' => {
            'desc' => '(pop) Discard top of stack',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_discard',
            'valid' => [ '', '', '' ]
          },
          'depth' => {
            'desc' => '(swap) Item to use (default=1)',
            'type' => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_depth',
            'valid' => [ '', '0', '' ]
          },
          'append' => {
            'desc' => '(pop) Append list',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_append',
            'valid' => [ '', '', '' ]
          },
          'copy' => {
            'desc' => '(push) Copy waypoint list',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_copy',
            'valid' => [ '', '', '' ]
          },
          'push' => {
            'desc' => 'Push waypoint list onto stack',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_push',
            'valid' => [ '', '', '' ]
          },
          'replace' => {
            'desc' => '(pop) Replace list (default)',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_replace',
            'valid' => [ '', '', '' ]
          },
          'swap' => {
            'desc' => 'Swap waypoint list with <depth> item on stack',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_swap',
            'valid' => [ '', '', '' ]
          },
          'pop' => {
            'desc' => 'Pop waypoint list from stack',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_pop',
            'valid' => [ '', '', '' ]
          }
        },
        'desc' => 'Save and restore waypoint lists'
      },
      'track' => {
        'options' => {
          'course' => {
            'desc' => 'Synthesize course',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_course',
            'valid' => [ '', '', '' ]
          },
          'stop' => {
            'desc' => 'Use only track points before this timestamp',
            'type' => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_stop',
            'valid' => [ '', '', '' ]
          },
          'move' => {
            'desc' => 'Correct trackpoint timestamps by a delta',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_move',
            'valid' => [ '', '', '' ]
          },
          'fix' => {
            'desc' => 'Synthesize GPS fixes (PPS, DGPS, 3D, 2D, NONE)',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_fix',
            'valid' => [ '', '', '' ]
          },
          'name' => {
            'desc' =>
             'Use only track(s) where title matches given name',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_name',
            'valid' => [ '', '', '' ]
          },
          'merge' => {
            'desc' => 'Merge multiple tracks for the same way',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_merge',
            'valid' => [ '', '', '' ]
          },
          'speed' => {
            'desc' => 'Synthesize speed',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_speed',
            'valid' => [ '', '', '' ]
          },
          'sdistance' => {
            'desc' => 'Split by distance',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_sdistance',
            'valid' => [ '', '', '' ]
          },
          'title' => {
            'desc' => 'Basic title for new track(s)',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_title',
            'valid' => [ '', '', '' ]
          },
          'pack' => {
            'desc' => 'Pack all tracks into one',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_pack',
            'valid' => [ '', '', '' ]
          },
          'split' => {
            'desc' => 'Split by date or time interval (see README)',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_split',
            'valid' => [ '', '', '' ]
          },
          'start' => {
            'desc' => 'Use only track points after this timestamp',
            'type' => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_start',
            'valid' => [ '', '', '' ]
          }
        },
        'desc' => 'Manipulate track lists'
      },
      'radius' => {
        'options' => {
          'nosort' => {
            'desc' => 'Inhibit sort by distance to center',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_nosort',
            'valid' => [ '', '', '' ]
          },
          'maxcount' => {
            'desc' => 'Output no more than this number of points',
            'type' => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_maxcount',
            'valid' => [ '', '1', '' ]
          },
          'asroute' => {
            'desc' => 'Put resulting waypoints in route of this name',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_asroute',
            'valid' => [ '', '', '' ]
          },
          'distance' => {
            'desc' => 'Maximum distance from center',
            'type' => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_distance',
            'valid' => [ '', '', '' ]
          },
          'lat' => {
            'desc' => 'Latitude for center point (D.DDDDD)',
            'type' => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_lat',
            'valid' => [ '', '', '' ]
          },
          'lon' => {
            'desc' => 'Longitude for center point (D.DDDDD)',
            'type' => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_lon',
            'valid' => [ '', '', '' ]
          },
          'exclude' => {
            'desc' => 'Exclude points close to center',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_exclude',
            'valid' => [ '', '', '' ]
          }
        },
        'desc' => 'Include Only Points Within Radius'
      },
      'position' => {
        'options' => {
          'distance' => {
            'desc' => 'Maximum positional distance',
            'type' => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_position.html#fmt_position_o_distance',
            'valid' => [ '', '', '' ]
          },
          'all' => {
            'desc' => 'Suppress all points close to other points',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_position.html#fmt_position_o_all',
            'valid' => [ '', '', '' ]
          }
        },
        'desc' => 'Remove Points Within Distance'
      },
      'reverse'  => { 'desc' => 'Reverse stops within routes' },
      'simplify' => {
        'options' => {
          'length' => {
            'desc' => 'Use arclength error',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_simplify.html#fmt_simplify_o_length',
            'valid' => [ '', '', '' ]
          },
          'count' => {
            'desc' => 'Maximum number of points in route',
            'type' => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_simplify.html#fmt_simplify_o_count',
            'valid' => [ '', '1', '' ]
          },
          'crosstrack' => {
            'desc' => 'Use cross-track error (default)',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_simplify.html#fmt_simplify_o_crosstrack',
            'valid' => [ '', '', '' ]
          },
          'error' => {
            'desc' => 'Maximum error',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_simplify.html#fmt_simplify_o_error',
            'valid' => [ '', '0', '' ]
          }
        },
        'desc' => 'Simplify routes'
      },
      'sort' => {
        'options' => {
          'shortname' => {
            'desc' => 'Sort by waypoint short name',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sort.html#fmt_sort_o_shortname',
            'valid' => [ '', '', '' ]
          },
          'time' => {
            'desc' => 'Sort by time',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sort.html#fmt_sort_o_time',
            'valid' => [ '', '', '' ]
          },
          'gcid' => {
            'desc' => 'Sort by numeric geocache ID',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sort.html#fmt_sort_o_gcid',
            'valid' => [ '', '', '' ]
          },
          'description' => {
            'desc' => 'Sort by waypoint description',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_sort.html#fmt_sort_o_description',
            'valid' => [ '', '', '' ]
          }
        },
        'desc' => 'Rearrange waypoints by resorting'
      },
      'nuketypes' => {
        'options' => {
          'waypoints' => {
            'desc' => 'Remove all waypoints from data stream',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nuketypes.html#fmt_nuketypes_o_waypoints',
            'valid' => [ '0', '', '' ]
          },
          'routes' => {
            'desc' => 'Remove all routes from data stream',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nuketypes.html#fmt_nuketypes_o_routes',
            'valid' => [ '0', '', '' ]
          },
          'tracks' => {
            'desc' => 'Remove all tracks from data stream',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_nuketypes.html#fmt_nuketypes_o_tracks',
            'valid' => [ '0', '', '' ]
          }
        },
        'desc' => 'Remove all waypoints, tracks, or routes'
      },
      'interpolate' => {
        'options' => {
          'distance' => {
            'desc' => 'Distance interval in miles or kilometers',
            'type' => 'string',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_interpolate.html#fmt_interpolate_o_distance',
            'valid' => [ '', '', '' ]
          },
          'time' => {
            'desc' => 'Time interval in seconds',
            'type' => 'integer',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_interpolate.html#fmt_interpolate_o_time',
            'valid' => [ '', '0', '' ]
          },
          'route' => {
            'desc' => 'Interpolate routes instead',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_interpolate.html#fmt_interpolate_o_route',
            'valid' => [ '', '', '' ]
          }
        },
        'desc' => 'Interpolate between trackpoints'
      },
      'duplicate' => {
        'options' => {
          'shortname' => {
            'desc' => 'Suppress duplicate waypoints based on name',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_duplicate.html#fmt_duplicate_o_shortname',
            'valid' => [ '', '', '' ]
          },
          'correct' => {
            'desc' => 'Use coords from duplicate points',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_duplicate.html#fmt_duplicate_o_correct',
            'valid' => [ '', '', '' ]
          },
          'location' => {
            'desc' => 'Suppress duplicate waypoint based on coords',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_duplicate.html#fmt_duplicate_o_location',
            'valid' => [ '', '', '' ]
          },
          'all' => {
            'desc' => 'Suppress all instances of duplicates',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_duplicate.html#fmt_duplicate_o_all',
            'valid' => [ '', '', '' ]
          }
        },
        'desc' => 'Remove Duplicates'
      },
      'polygon' => {
        'options' => {
          'file' => {
            'desc' => 'File containing vertices of polygon',
            'type' => 'file',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_polygon.html#fmt_polygon_o_file',
            'valid' => [ '', '', '' ]
          },
          'exclude' => {
            'desc' => 'Exclude points inside the polygon',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_polygon.html#fmt_polygon_o_exclude',
            'valid' => [ '', '', '' ]
          }
        },
        'desc' => 'Include Only Points Inside Polygon'
      },
      'arc' => {
        'options' => {
          'distance' => {
            'desc' => 'Maximum distance from arc',
            'type' => 'float',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_distance',
            'valid' => [ '', '', '' ]
          },
          'points' => {
            'desc' => 'Use distance from vertices not lines',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_points',
            'valid' => [ '', '', '' ]
          },
          'file' => {
            'desc' => 'File containing vertices of arc',
            'type' => 'file',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_file',
            'valid' => [ '', '', '' ]
          },
          'exclude' => {
            'desc' => 'Exclude points close to the arc',
            'type' => 'boolean',
            'doclink' =>
             'http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_exclude',
            'valid' => [ '', '', '' ]
          }
        },
        'desc' => 'Include Only Points Within Distance of Arc'
      }
    }
  };

  @tests = (
    {
      name    => 'Broken gpsbabel',
      args    => [ 'bork', 0 ],
      version => '0.0.0',
      info    => {
        formats => {},
        for_ext => {},
        filters => {},
      },
    },
    {
      name    => 'gpsbabel 1.2.5',
      args    => [ '1.2.5', 0 ],
      version => '1.2.5',
      info    => {
        formats => {},
        for_ext => {},
        filters => {},
      },
      actions => [
        {
          comment => 'No auto conversion',
          method  => 'convert',
          args    => [ 'in.kml', 'out.gpx' ],
          error   => qr/No format handles/,
        },
        {
          comment => 'Format specified',
          method  => 'convert',
          args    => [
            'in.kml', 'out.gpx',
            { in_format => 'kml', out_format => 'gpx' }
          ],
          expect => [
            '-p',  '',   '-r',     '-t', '-w',  '-i',
            'kml', '-f', 'in.kml', '-o', 'gpx', '-F',
            'out.gpx'
          ],
        },
      ],
    },
    {
      name    => 'gpsbabel 1.3.0',
      args    => [ '1.3.0', 0 ],
      version => '1.3.0',
      info    => $ref_info,
      actions => [
        {
          comment => 'Format guessed',
          method  => 'convert',
          args    => [ 'in.kml', 'out.gpx', ],
          expect  => [
            '-p',  '',   '-r',     '-t', '-w',  '-i',
            'kml', '-f', 'in.kml', '-o', 'gpx', '-F',
            'out.gpx'
          ],
        },
        {
          comment => 'Format specified',
          method  => 'convert',
          args    => [
            'in.kml', 'out.gpx',
            { in_format => 'kml', out_format => 'gpx' }
          ],
          expect => [
            '-p',  '',   '-r',     '-t', '-w',  '-i',
            'kml', '-f', 'in.kml', '-o', 'gpx', '-F',
            'out.gpx'
          ],
        },
      ],
    },
    {
      name    => 'gpsbabel 1.3.5',
      args    => [ '1.3.5', 0 ],
      version => '1.3.5',
      info    => $ref_info135,
      actions => [
        {
          comment => 'Format guessed',
          method  => 'convert',
          args    => [ 'in.kml', 'out.gpx', ],
          expect  => [
            '-p',  '',   '-r',     '-t', '-w',  '-i',
            'kml', '-f', 'in.kml', '-o', 'gpx', '-F',
            'out.gpx'
          ],
        },
        {
          comment => 'Format specified',
          method  => 'convert',
          args    => [
            'in.kml', 'out.gpx',
            { in_format => 'kml', out_format => 'gpx' }
          ],
          expect => [
            '-p',  '',   '-r',     '-t', '-w',  '-i',
            'kml', '-f', 'in.kml', '-o', 'gpx', '-F',
            'out.gpx'
          ],
        },
      ],
    },
  );

  my $count = 4 + @tests * 7;

  for my $test ( @tests ) {
    $count += 2 * @{ $test->{actions} || [] };
  }

  plan tests => $count;
}

my $dump = File::Spec->catfile( File::Spec->tmpdir, "babel-test-$$" );

sub get_fake {
  return [ $^X, File::Spec->catfile( 't', 'fake-babel.pl' ), $dump,
    @_ ];
}

sub deeply {
  my ( $got, $want, $msg ) = @_;
  unless ( is_deeply $got, $want, $msg ) {
    diag( Data::Dumper->Dump( [$got],  ['$got'] ) );
    diag( Data::Dumper->Dump( [$want], ['$want'] ) );
  }
}

# Get the arguments that were passed to gpsbabel
sub get_args {
  our $args;
  eval "require '$dump'";
  die "Can't require $dump ($@)" if $@;
  return $args;
}

{
  ok my $babel
   = GPS::Babel->new( { exename => get_fake( 'bork', 1 ) } ),
   'create ok';
  isa_ok $babel, 'GPS::Babel';
  eval { $babel->check_exe };
  ok !$@, 'check exe OK';

  my $version = eval { $babel->version };
  like $@, qr/failed/, 'error OK';
}

for my $test ( @tests ) {
  my $name = $test->{name};
  my $exe  = get_fake( @{ $test->{args} } );
  ok my $babel = GPS::Babel->new( { exename => $exe } ),
   "$name: create OK";
  isa_ok $babel, "GPS::Babel";
  eval { $babel->check_exe };
  ok !$@, "$name: check exe OK";

  my $version = $babel->version;
  is $version, $test->{version}, "$name: version OK";

  my $info = $babel->get_info;
  ok defined delete $info->{banner},  "$name: got banner OK";
  ok defined delete $info->{version}, "$name: got banner OK";

  deeply( $info, $test->{info}, "$name: get_info OK" );

  if ( my $actions = $test->{actions} ) {
    for my $spec ( @$actions ) {
      my $method  = delete $spec->{method};
      my $comment = delete $spec->{comment};
      my $result  = eval { $babel->$method( @{ $spec->{args} } ) };
      if ( my $error = $spec->{error} ) {
        like $@, $error, "$name, $comment: $method throws error";
        pass "$name: arg check skipped";
      }
      else {
        unless ( ok !$@, "$name, $comment: $method OK" ) {
          diag "Got error: $@";
        }
        deeply(
          get_args(),
          $spec->{expect} || {},
          "$name, $comment: gpsbabel args match"
        );
      }
    }
  }
}

unlink $dump;
