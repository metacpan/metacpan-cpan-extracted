use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Log::Dump::Test::Child;

BEGIN {
  eval { require IO::Capture::Stderr; 1 }
    or plan skip_all => 'requires IO::Capture::Stderr';
}

my $capture = IO::Capture::Stderr->new;
my $package = 'Log::Dump::Test::Child';
my $object  = $package->new;

subtest 'disable' => sub {
  for my $target ($package, $object) {
    $target->logger(0);
    $capture->start;
    $target->log( array => 'message', 'array' );
    $capture->stop;

    ok !$capture->read, 'log is disabled';

    $target->logger(1);
    $capture->start;
    $target->log( debug => 'debug' );
    $capture->stop;

    like $capture->read => qr/\[debug\] debug/, 'captured';
  }
};

done_testing;
