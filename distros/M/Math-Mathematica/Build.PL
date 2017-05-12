use strict;
use warnings;

use Module::Build;
use File::Which 'which';

unless (defined which 'math') {
  my $message = "Math::Mathematica requires an installed version of Mathematica and the 'math' shell\n";
  if ($ENV{AUTOMATED_TESTING}) {
    print $message;
    exit 0;
  } else {
    die $message;
  }
}

my $build = Module::Build->new(
    module_name       => 'Math::Mathematica',
    dist_author       => 'Joel Berger <joel.a.berger@gmail.com>',
    license           => 'perl',
    requires          => {
      'IO::Pty::Easy' => 0,
    },
    configure_requires => {
      'Module::Build' => 0.38,
      'File::Which'   => 0,
    },
  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Math-Mathematica",
      bugtracker => "http://github.com/jberger/Math-Mathematica/issues",
    },
    no_index => {
      file => [ 'README.pod' ],
    },
  },
);

$build->create_build_script;

