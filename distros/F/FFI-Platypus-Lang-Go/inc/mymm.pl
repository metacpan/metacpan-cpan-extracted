use strict;
use warnings;
use Capture::Tiny qw( capture );

my($out, $err, $exit) = capture {
  system 'go' ,'version';
};

unless($exit == 0)
{
  print "This dist requires Google Go to be installed";
  exit;
}

