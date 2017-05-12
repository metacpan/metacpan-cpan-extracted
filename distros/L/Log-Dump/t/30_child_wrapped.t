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

subtest 'debug' => sub {
  for my $target ($package, $object) {
    $capture->start;
    $target->debug;
    $capture->stop;

    like $capture->read => qr/\[debug\] debug/, 'captured';
  }
};

subtest 'child' => sub {
  for my $target ($package, $object) {
    $capture->start;
    $target->child;
    $capture->stop;

    like $capture->read => qr/\[child\] child/, 'captured';
  }
};

done_testing;
