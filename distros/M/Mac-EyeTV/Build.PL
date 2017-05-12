use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license            => 'perl',
  module_name        => 'Mac::EyeTV',
  requires           => {
    'Mac::Glue'                  => '0',
    'DateTime'                   => '0',
    'DateTime::Format::Strptime' => '0',
    'Class::Accessor::Fast'      => '0',
    'URI::file'                  => '0',
    'Mac::AppleScript'           => '0',
  },
);
$build->create_build_script;
