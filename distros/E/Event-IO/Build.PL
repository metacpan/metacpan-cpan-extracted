# dbr 20040315

use Module::Build;

my $build = Module::Build->new(
 dist_name    => 'Event-IO',
 dist_version => '0.01',
 license => 'perl',
 requires     => {
  perl                => '5.6.0',
  'Event'             => 0,
 },
);

$build->create_build_script();
