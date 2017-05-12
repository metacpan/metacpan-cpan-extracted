use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Debug::ShowStuff - A collection of handy debugging routines for displaying the values of variables with a minimum of coding.',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Debug::ShowStuff',
            'requires' => {
                            'Text::TabularDisplay' => 0,
                            'Scalar::Util' => 0,
                            'Devel::StackTrace' => 0,
                            'String::Util' => 0,
                            'Tie::IxHash' => 0,
                            'Class::ISA' => 0,
                            'Term::ReadKey' => 0
                          },
            'dist_version_from' => 'lib/Debug/ShowStuff.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
