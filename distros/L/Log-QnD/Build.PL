use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Log::QnD - Quick and dirty logging system',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Log::QnD',
            'requires' => {
                            'IO::Scalar' => 0,
                            'String::Util' => 0,
                            'Test' => 0,
                            'Class::PublicPrivate' => 0,
                            'JSON' => 0,
                            'File::ReadBackwards' => 0
                          },
            'dist_version_from' => 'lib/Log/QnD.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
