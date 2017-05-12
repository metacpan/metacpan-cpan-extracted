use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Log::Dump::Test::Class;

BEGIN {
  eval { require IO::Capture::Stderr; 1 }
    or plan skip_all => 'requires IO::Capture::Stderr';
}

my $capture = IO::Capture::Stderr->new;
my $package = 'Log::Dump::Test::Class';
my $object = $package->new;

subtest 'log' => sub {
  for my $target ($package, $object) {
    $capture->start;
    $target->log( debug => 'message' );
    $capture->stop;
    my $captured = join "\n", $capture->read;

    like $captured => qr/\[debug\] message/, 'captured';
    unlike $captured => qr{Log.Dump(?!.Test)}, 'not from Log::Dump';
  }
};

subtest 'dump' => sub {
  for my $target ($package, $object) {
    $capture->start;
    $target->log( dump => ['message', 'array'] );
    $capture->stop;
    my $captured = join "\n", $capture->read;

    like $captured => qr/\[dump\] \["message", "array"\]/, 'captured';
    unlike $captured => qr{Log.Dump(?!.Test)}, 'not from Log::Dump';
  }
};

subtest 'error' => sub {
  for my $target ($package, $object) {
    $capture->start;
    $target->log( error => 'message' );
    $capture->stop;
    my $captured = $capture->read;

    like $captured => qr/\[error\] message at/, 'captured';
    unlike $captured => qr{Log.Dump(?!.Test)}, 'not from Log::Dump';
  }
};

subtest 'fatal' => sub {
  for my $target ($package, $object) {
    eval { $target->log( fatal => 'message' ) };

    like $@ => qr/\[fatal\] message at/, 'captured';
    unlike $@ => qr{Log.Dump(?!.Test)}, 'not from Log::Dump';
  }
};

subtest 'array' => sub {
  for my $target ($package, $object) {
    $capture->start;
    $target->log( array => 'message', 'array' );
    $capture->stop;
    my $captured = join "\n", $capture->read;

    like $captured => qr/\[array\] messagearray/, 'captured';
    unlike $captured => qr{Log.Dump(?!.Test)}, 'not from Log::Dump';
  }
};

subtest 'logger' => sub {
  for my $target ($package, $object) {
    $capture->start;
    $target->log( debug => 'message' );
    $capture->stop;
    my $captured = join "\n", $capture->read;

    like $captured => qr/\[debug\] message/, 'captured';
    unlike $captured => qr{Log.Dump(?!.Test)}, 'not from Log::Dump';

    $target->logger(0);
    is $target->logger => 0, 'logger value is correct';

    $capture->start;
    $target->log( debug => 'logger is disabled' );
    $capture->stop;
    $captured = join "\n", $capture->read;

    ok !$captured, 'logger is disabled';

    $target->logger(1);
    is $target->logger => 1, 'logger value is correct';

    $capture->start;
    $target->log( debug => 'logger is enabled' );
    $capture->stop;
    $captured = join "\n", $capture->read;

    like $captured => qr/\[debug\] logger is enabled/, 'captured';
    unlike $captured => qr{Log.Dump(?!.Test)}, 'not from Log::Dump';
  }
};

subtest 'custom_logger' => sub {
  for my $target ($package, $object) {
    $capture->start;
    $target->log( debug => 'message' );
    $capture->stop;
    my $captured = join "\n", $capture->read;

    like $captured => qr/\[debug\] message/, 'captured';
    unlike $captured => qr{Log.Dump(?!.Test)}, 'not from Log::Dump';

    $target->logger(0);
    is $target->logger => 0, 'logger value is correct';

    $capture->start;
    $target->log( debug => 'logger is disabled' );
    $capture->stop;
    $captured = join "\n", $capture->read;

    ok !$captured, 'logger is disabled';

    $target->logger('Log::Dump::Test::CustomLogger');
    is $target->logger => 'Log::Dump::Test::CustomLogger', 'logger value is correct';

    $capture->start;
    $target->log( debug => 'custom logger is enabled' );
    $capture->stop;
    $captured = join "\n", $capture->read;

    like $captured => qr/debug custom logger is enabled/, 'captured';
    unlike $captured => qr{Log.Dump(?!.Test)}, 'not from Log::Dump';

    my $logger_object = Log::Dump::Test::CustomLogger->new;
    $target->logger($logger_object);

    $capture->start;
    $target->log( debug => 'custom logger object is enabled' );
    $capture->stop;
    $captured = join "\n", $capture->read;

    like $captured => qr/debug custom logger object is enabled/, 'captured';
    unlike $captured => qr{Log.Dump(?!.Test)}, 'not from Log::Dump';

    $target->logger(1);  # back to the default
  }
};

done_testing;

package #
  Log::Dump::Test::CustomLogger;

sub new { bless {}, shift }
sub log { shift; print STDERR join ' ', @_ }

1;
