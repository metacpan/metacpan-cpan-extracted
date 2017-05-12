use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
       module_name       => 'HTML::ExtractMain',
       license           => 'perl',
       dist_author       => 'Anirvan Chatterjee <anirvan@cpan.org>',
       dist_version_from => 'lib/HTML/ExtractMain.pm',
       meta_merge        => {
           resources =>
               { repository => 'http://github.com/anirvan/html-extractmain' },
           keywords => ['readability'],
       },
       requires => { 'Carp'              => 0,
                     'HTML::TreeBuilder' => 3.23,
                     'Object::Destroyer' => 2.00,
                     'Scalar::Util'      => 1.18,
       },
       build_requires => { 'Test::More'       => 0,
                           'HTML::FormatText' => 2.04,
                           'File::Slurp'      => 9999.12,
       },
       add_to_cleanup     => ['HTML-ExtractMain-*'],
       create_makefile_pl => 'traditional',
);

$builder->create_build_script();

# Local Variables:
# mode: perltidy
# End:
