use strict;
use warnings;
use Capture::Tiny qw( capture_stdout );
use Path::Tiny qw( path );

exit if $ENV{TRAVIS};
exit if $ENV{APPVEYOR};

my($out ) = capture_stdout {
  system(
    $^X, 
      '-Ilib', 
      'example/unbundle.pl', '--default',
    );
  die "failed" unless $? == 0;
};

path('example/default_dist.ini')->spew_raw($out);
