use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Log::Dump::Test::ClassUserA;

BEGIN {
  eval { require IO::Capture::Stderr; 1 }
    or plan skip_all => 'requires IO::Capture::Stderr';
}

my $capture = IO::Capture::Stderr->new;

Log::Dump::Test::ClassUserA->logger(1);

subtest 'plain_usage' => sub {
  $capture->start;
  Log::Dump::Test::ClassUserA->log( debug => 'message' );
  $capture->stop;
  my $captured = join "\n", $capture->read;

  like $captured => qr/\[debug\] message/, 'captured';
  unlike $captured => qr{Log.Dump.Class}, 'not from Log::Dump::Class';
};

subtest 'error' => sub {
  $capture->start;
  Log::Dump::Test::ClassUserA->log( error => 'message' );
  $capture->stop;
  my $captured = join "\n", $capture->read;

  like $captured => qr/\[error\] message/, 'captured';
  unlike $captured => qr{Log.Dump.Class}, 'not from Log::Dump::Class';
};

subtest 'fatal' => sub {
  eval { Log::Dump::Test::ClassUserA->log( fatal => 'message' ) };

  like $@ => qr/\[fatal\] message/, 'captured';
  unlike $@ => qr{Log.Dump.Class}, 'not from Log::Dump::Class';
};

done_testing;
