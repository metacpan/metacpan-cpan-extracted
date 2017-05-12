use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'File::Find::Rule::DirCompare',
    license           => 'perl',
    dist_author       => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from => 'lib/File/Find/Rule/DirCompare.pm',
    build_requires    => {
                        'File::Touch' => 0,    # test requires
                        'Test::More'  => 0,
                      },
    requires => {
                  'File::Find::Rule' => 0.30,
                  'Params::Util'     => 1.00,
                  'Text::Glob'       => 0,
                },
    add_to_cleanup => ['File-Find-Rule-DirCompare-*'],
    meta_merge     => {
                    no_index => {
                                  directory => [qw(t/samples)],
                                },
                    resources => {
                               repository => "https://github.com/rehsack/File-Find-Rule-DirCompare",
                    },
                  },
    test_files => join( ' ' => 't/*.t xt/*.t' ),

                                );

$builder->create_build_script();
