use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Log::Dump::Functions;

BEGIN {
  eval { require IO::Capture::Stderr; 1 }
    or plan skip_all => 'requires IO::Capture::Stderr';
}

my $capture = IO::Capture::Stderr->new;

subtest 'plain_usage' => sub {
  $capture->start;
  log( debug => 'message' );
  $capture->stop;
  my $captured = join "\n", $capture->read;

  like $captured => qr/\[debug\] message/, 'captured';
  unlike $captured => qr{Log.Dump.Functions}, 'not from Log::Dump::Functions';
};

subtest 'error' => sub {
  $capture->start;
  log( error => 'message' );
  $capture->stop;
  my $captured = join "\n", $capture->read;

  like $captured => qr/\[error\] message/, 'captured';
  unlike $captured => qr{Log.Dump.Functions}, 'not from Log::Dump::Functions';
};

subtest 'fatal' => sub {
  eval { log( fatal => 'message' ) };

  like $@ => qr/\[fatal\] message/, 'captured';
  unlike $@ => qr{Log.Dump.Functions}, 'not from Log::Dump::Functions';
};

done_testing;
