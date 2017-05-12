use strict;
use warnings;
use Capture::Tiny qw( capture_stdout );
use Path::Class qw( file );

exit if $ENV{TRAVIS};
exit if $ENV{APPVEYOR};

my($out ) = capture_stdout {
  system(
    $^X, 
      '-Ilib', 
      '-MDevel::Hide=Dist::Zilla::Plugin::ACPS::RPM',
      'example/unbundle.pl', '--default',
    );
  die "failed" unless $? == 0;
};

file('example', 'default_dist.ini')->spew($out);
