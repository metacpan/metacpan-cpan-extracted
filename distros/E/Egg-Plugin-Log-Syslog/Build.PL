use Module::Build;

my $builder = Module::Build->new(

  module_name       => 'Egg::Plugin::Log::Syslog',
  dist_version_from => 'lib/Egg/Plugin/Log/Syslog.pm',
  dist_abstract     => 'lib/Egg/Plugin/Log/Syslog.pm',
  dist_author       => 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>',
  license           => 'perl',

  requires => {

    'Egg::Release'         => 2.26,

    'Test::More'           => 0,
    'Test::Pod'            => 0,
#    'Test::Perl::Critic'  => 0,
#    'Test::Pod::Coverage' => 0,
    },

  );

$builder->create_build_script();
