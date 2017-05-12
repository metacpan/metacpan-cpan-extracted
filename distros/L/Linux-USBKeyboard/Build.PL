use strict;
use warnings;
use Module::Build;
use inc::InlineBuild;

my $build_class = 'inc::InlineBuild';

my $builder = $build_class->new(
  module_name         => 'Linux::USBKeyboard',
  license             => 'perl',
  dist_version_from   => 'lib/Linux/USBKeyboard.pm',
  inline_modules      => [qw(
    Linux::USBKeyboard
  )],
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  requires => {
    'Inline::C'     => 0,
    perl            => 5.008002
  },
  add_to_cleanup      => [ qw(
    Linux-USBKeyboard-*
    META.yml
    _Inline
    USBKeyboard.inl
  )],
);

use lib qw(inc);
require Devel::CheckLib;
# uh... is it really worth it
eval { Devel::CheckLib::assert_lib(lib => 'usb') };
if(my $err = $@) {
  $err = "ERROR we need to be able to link against libusb!\n$err";
  if($ENV{AUTOMATED_TESTING}) {
    warn $err;
    exit 0; # because cpantesters are special!
  }
  else {
    die $err;
  }

}

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
