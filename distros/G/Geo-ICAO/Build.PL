
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
                       'dist_abstract' => 'Airport and ICAO codes lookup',
                       'script_files' => [],
                       'license' => 'perl',
                       'dist_name' => 'Geo-ICAO',
                       'dist_author' => [
                                          'Jerome Quelin'
                                        ],
                       'share_dir' => 'share',
                       'module_name' => 'Geo::ICAO',
                       'requires' => {
                                       'English' => 0,
                                       'charnames' => 0,
                                       'Sub::Exporter' => 0,
                                       'Readonly' => 0,
                                       'Encode' => 0,
                                       'Carp' => 0,
                                       'List::Util' => 0,
                                       'Test::More' => 0,
                                       'perl' => '5.008',
                                       'File::ShareDir' => 0,
                                       'File::Find' => 0,
                                       'Path::Class' => 0
                                     }
                     );


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
