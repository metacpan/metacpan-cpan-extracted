use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new( module_name        => 'Geo::Privacy',
                                  license            => 'perl_5',
                                  dist_author        => q{Dan Wright <Dan@DWright.Org>},
                                  dist_version_from  => 'lib/Geo/Privacy.pm',
                                  release_status     => 'stable',
                                  configure_requires => { 'Module::Build' => '0', },
                                  build_requires     => { 'Test::More' => '0', },
                                  requires           => {
                                                'Readonly'       => 1,
                                                'Exporter::Lite' => 0.06,
                                  },
                                  add_to_cleanup => ['Geo-Privacy-*'],
                                  meta_merge     => {
                                                  'meta-spec' => { version => '2',
                                                                   url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
                                                  },
                                                  resources => { bugtracker => { web => 'https://github.com/dwright/Geo-Privacy/issues', },
                                                                 repository => { url  => 'https://github.com/dwright/Geo-Privacy.git',
                                                                                 web  => 'https://github.com/dwright/Geo-Privacy',
                                                                                 type => 'git',
                                                                 }
                                                  },
                                  }, );

$builder->create_build_script();
