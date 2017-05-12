use Module::Build;
my $build = Module::Build->new
(
  module_name => 'Math::Fractal::DLA',
  license => 'perl',
  requires =>
  {
    'perl' => '>= 5',
    'GD' => '>= 1.30',
    'Log::LogLite' => '>= 0.8',
    'Test::More' => '>= 0.54'
  },
);
$build->create_build_script;

