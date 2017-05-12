use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Log::Dump::Test::Class;

BEGIN {
  for my $package (qw/IO::Capture::Stderr Time::Piece/) {
    eval "require $package; 1"
      or plan skip_all => "requires $package";
  }
}

my $capture = IO::Capture::Stderr->new;
my $package = 'Log::Dump::Test::Class';
my $object  = $package->new;

subtest 'time' => sub {
  for my $target ($package, $object) {
    $target->logtime(1);
    $capture->start;
    $target->log( time => 'message' );
    $capture->stop;

    my $with_time = $capture->read;
    like $with_time => qr/^\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2} \[time\] message/, 'captured';
    $target->logtime(0); # no more time

    $capture->start;
    $target->log( time => 'message' );
    $capture->stop;

    my $without_time = $capture->read;
    like $without_time => qr/^\[time\] message/, 'captured';

    ok $with_time ne $without_time, 'both are different';

    # custom format
    $target->logtime('%Y-%m-%d');
    $capture->start;
    $target->log( time => 'message' );
    $capture->stop;

    $with_time = $capture->read;
    like $with_time => qr/^\d{4}\-\d{2}\-\d{2} \[time\] message/, 'captured';
    $target->logtime(0); # no more time
  }
};

done_testing;
