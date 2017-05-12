use strict;
use Module::Build;
my ($build, $params);


$params = {
            'module_name' => 'JSON::Relaxed',
            'requires' => {
                            'Test::Most' => '0.34'
                          },
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'dist_version_from' => 'lib/JSON/Relaxed.pm',
            'dist_abstract' => 'JSON::Relaxed -- An extension of JSON that allows for better human-readability.',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
