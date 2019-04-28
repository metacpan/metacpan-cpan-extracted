use Test2::Require::EnvVar 'EXTRA_CI';
use Test2::V0 -no_srand => 1;
use FFI::CheckLib qw( find_lib );
use FFI::Platypus;

# This test should only run under ci in a docker container with
# libffi and libyaml development packages installed

subtest 'libffi' => sub {

  my @ffi;

  is(
    [@ffi = find_lib lib => 'ffi'],
    bag {
      item match qr/libffi\.so/;
      etc;
    },
    'have ffi',
  );

  note "lib = $_" for @ffi;

  my $ffi = FFI::Platypus->new;
  $ffi->lib(@ffi);

  my $ffi_raw_call = eval { $ffi->function('ffi_raw_call' => [] => 'void') };
  ok $ffi_raw_call, "has symbol ffi_raw_call";

};

subtest 'yaml' => sub {

  my @yaml;

  is(
    [@yaml = find_lib lib => 'yaml', try_linker_script => 1],
    bag {
      item match qr/libyaml.*\.so/;
      etc;
    },
    'have yaml',
  );

  note "lib = $_" for @yaml;

  my $ffi = FFI::Platypus->new;
  $ffi->lib(@yaml);

  my $yaml_get_version_string = eval { $ffi->function('yaml_get_version_string' => [] => 'string') };
  ok $yaml_get_version_string, "has symbol yaml_get_version_string";
  return unless $yaml_get_version_string;
  ok $yaml_get_version_string->(), "has a version yo";
  note "yaml_get_version_string = ", $yaml_get_version_string->();

};

done_testing;
