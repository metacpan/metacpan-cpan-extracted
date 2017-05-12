# vim:set et sw=2:
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Lingua::Klingon::Collate',
    license => 'bsd',
    requires => {
      'perl' => '5.005_03',
    },
    build_requires => {
      'Module::Build' => 0,
      'Test::More' => '0.19',
      'Test::Differences' => 0,
    },
    create_makefile_pl => 'passthrough',
);

my $failures = $build->prereq_failures();
if($failures) {
  while (my ($type, $list) = each %$failures) {
    while (my ($name, $hash) = each %$list) {
      print "Failure for $name: $hash->{message}\n";
    }
  }
} else {
  $build->create_build_script;
}
