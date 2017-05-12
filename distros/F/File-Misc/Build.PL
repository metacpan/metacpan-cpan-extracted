use strict;
use Module::Build;
my ($build, $params);


$params = {
            'module_name' => 'File::Misc',
            'license' => 'perl',
            'dist_version_from' => 'lib/File/Misc.pm',
            'requires' => {
                            'File::chdir' => 0,
                            'File::Path' => 0,
                            'File::Copy' => 0,
                            'File::Compare' => 0,
                            'File::Find' => 0,
                            'String::Util' => '1.24',
                            'Test::Toolbox' => '0.2',
                            'Class::ISA' => 0,
                            'File::Copy::Recursive' => 0
                          },
            'dist_abstract' => 'File::Misc -- handy file tools',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
