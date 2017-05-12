use Module::Build;

my $builder = Module::Build->new(

  module_name       => 'HTML::Template::Ex',
  dist_version_from => 'lib/HTML/Template/Ex.pm',
  dist_abstract     => 'lib/HTML/Template/Ex.pm',
  dist_author       => 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>',
  license           => 'perl',

  requires => {

    'HTML::Template'      => 2.9,
    'HTML::Entities'      => 3.5,
    'Digest::MD5'         => 2.3,
    'Devel::StackTrace'   => 1.1,

    'Test::More'          => 0,
    'Test::Perl::Critic'  => 0,
    'Test::Pod'           => 0,
    'Test::Pod::Coverage' => 0,

    },
  );

$builder->create_build_script();
