use Module::Build;
my $build = Module::Build->new
 (
  module_name => 'Lingua::Slavic::Numbers',
  dist_author => 'Ted Zlatanov <tzz@lifelogs.com>',
  license  => 'perl',
  requires => {
	       'perl'          => '5.6.1',
	       'List::Util'  => 0,
	       'Regexp::Common'  => 0,
	      },
 );
$build->create_build_script;
