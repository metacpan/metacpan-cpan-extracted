
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Device::SerialPins',
  license             => 'perl',
  dist_version_from   => 'lib/Device/SerialPins.pm',
  requires => {
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Device-SerialPins-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-SerialPins',
      #MailingList => 'mailto:...',
      repository =>
        'http://scratchcomputing.com/svn/Device-SerialPins/trunk',
    }
  },
);

unless(eval("package foo; require('sys/ioctl.ph'); 1")) {
  warn "ERROR:  Your perl build has no 'sys/ioctl.ph' file.\n",
    "  Perhaps try rebuilding it or running 'h2ph' (see perlfaq8.)\n",
    "  (Or maybe we can't do ioctl on your OS?)\n";
  exit 0;
}

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
