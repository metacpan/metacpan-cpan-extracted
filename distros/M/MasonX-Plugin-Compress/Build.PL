use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MasonX::Plugin::Compress',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/MasonX/Plugin/Compress.pm',
    requires => {
        'Compress::Zlib' => 0,
        'Compress::Bzip2' => 2.0,
        'List::Util' => 0,
        # 'Apache::Constants' => 0,
        
        # for the tests
        'Test::More' => 0,
        # 'Test::Exception' => 0,
        'Class::Accessor' => 0,
        'HTML::Mason' => 1.29,  
        
    },
    add_to_cleanup      => [ 'MasonX-Plugin-Compress-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
