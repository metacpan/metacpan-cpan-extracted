use Module::Build;
use strict;

# We need to find imlib2-config
my $CONFIG = "imlib2-config";

my $version = `$CONFIG --version`;
if (!$version) {
  warn 'You must install the imlib2 library before you can install
Image::Imlib2. You can obtain imlib2 from
http://sourceforge.net/projects/enlightenment/

Alternatively, if you have downloaded and installed imlib2 and this
still will not work, modify the $CONFIG variable inside Build.PL to
point to the imlib2-config program that provides.
';
  exit 0;
} else {
  print "Found imlib2 $version";
}

my $libs = `$CONFIG --libs`;
my $cflags = "-DX_DISPLAY_MISSING " . `$CONFIG --cflags`;

my $build = Module::Build->new(
  c_source     => './lib/Image',
  create_makefile_pl => 'passthrough',
  extra_compiler_flags => $cflags,
  extra_linker_flags => $libs,
  license     => 'perl',
  module_name => 'Image::Imlib2',
  requires    => {
    'Module::Build' => '0.20',
    'Test::More' => '0.01',
  },
  add_to_cleanup => [qw( t/test1.jpg t/test2.jpg t/test3.jpg )],
);
$build->create_build_script;
