use Modern::Perl;

use Module::Build;

my $build = Module::Build->new(
  module_name => 'KeywordsSpider',
  license => 'perl',
  dist_author => 'Katarina Durechova <durechova@ynet.sk>',
  dist_abstract => 'web spider searching for keywords',
  dist_version => '0.02',
  meta_merge => {
    resources => {
      repository => 'https://github.com/katkad/KeywordsSpider',
    }
  },
  requires => {
    'Modern::Perl' => 0,
    'Parallel::ForkManager' => 0,
    'Moose' => 0,
    'MooseX::UndefTolerant' => 0,
    'Data::Dumper' => 0,
    'LWP::UserAgent' => 0,
    'HTTP::Request::Common' => 0,
    'HTTP::Cookies' => 0,
    'HTML::TreeBuilder' => 0,
  },
  build_requires => {
    'Test::Spec' => 0,
    'Test::MockObject' => 0,
    'Test::Spec::Mocks' => 0,
  },
);

$build->create_build_script;
