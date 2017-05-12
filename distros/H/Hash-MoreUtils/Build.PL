use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Hash::MoreUtils',
    license           => 'perl',
    dist_version_from => 'lib/Hash/MoreUtils.pm',
    build_requires    => {
                        'Test::More' => '0.90',
                      },
    dist_author => [ 'Hans Dieter Pearcey <hdp@cpan.org>', 'Jens Rehsack <rehsack@cpan.org>' ],
    meta_merge  => {
                    resources => {
                                   repository => "https://github.com/perl5-utils/Hash-MoreUtils",
                                 },
                  },
    add_to_cleanup => ['Hash-MoreUtils-*'],
    test_files     => [ "t/*.t", "xt/*.t" ],
                                );

$builder->create_build_script();
