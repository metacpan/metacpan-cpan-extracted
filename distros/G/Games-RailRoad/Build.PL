
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
                       'dist_abstract' => 'a train simulation game',
                       'script_files' => [
                                           'bin/railsim'
                                         ],
                       'license' => 'perl',
                       'build_requires' => {
                                             'Scalar::Util' => '0',
                                             'Test::More' => '0.88',
                                             'English' => '0',
                                             'File::Find' => '0',
                                             'File::Temp' => '0',
                                             'Module::Build' => '0.3601',
                                             'Carp' => '0'
                                           },
                       'dist_name' => 'Games-RailRoad',
                       'dist_author' => [
                                          'Jerome Quelin'
                                        ],
                       'share_dir' => 'share',
                       'module_name' => 'Games::RailRoad',
                       'requires' => {
                                       'MooseX::Has::Sugar' => '0',
                                       'MooseX::Types::Moose' => '0',
                                       'YAML' => '0',
                                       'Tk::ToolBar' => '0',
                                       'Tk::PNG' => '0',
                                       'FindBin' => '0',
                                       'File::ShareDir' => '0',
                                       'File::Path' => '0',
                                       'File::Spec::Functions' => '0',
                                       'Tk' => '0',
                                       'MooseX::SemiAffordanceAccessor' => '0',
                                       'Moose' => '0',
                                       'Module::Pluggable' => '0',
                                       'Getopt::Euclid' => '0',
                                       'File::HomeDir' => '0',
                                       'POE::Kernel' => '0',
                                       'overload' => '0',
                                       'Readonly' => '0',
                                       'perl' => '5.010',
                                       'POE::Loop::Tk' => '0',
                                       'MooseX::Types' => '0',
                                       'File::Basename' => '0',
                                       'UNIVERSAL::require' => '0',
                                       'POE' => '0'
                                     },
                       'recommends' => {},
                       'configure_requires' => {
                                                 'Module::Build' => '0.3601'
                                               },
                       'dist_version' => '1.101330'
                     );


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
