use Module::Build;

my $builder = Module::Build->new(

  module_name       => 'Egg::Release::XML::FeedPP',
  dist_version_from => 'lib/Egg/Release/XML/FeedPP.pm',
  dist_author       => 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>',
  license           => 'perl',

  requires => {

    'Egg::Release'        => 2.20,
    'Egg::Plugin::Cache'  => 2.01,
    'XML::FeedPP'         => 0.22,

    'Test::More'          => 0,
    'Test::Pod'           => 0,
    'Test::Perl::Critic'  => 0,
    'Test::Pod::Coverage' => 0,
    },

  );

$builder->create_build_script();
