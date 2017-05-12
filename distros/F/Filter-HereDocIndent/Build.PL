use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Filter::HereDocIndent - Indent here documents',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Filter::HereDocIndent',
            'requires' => {},
            'dist_version_from' => 'lib/Filter/HereDocIndent.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
