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

subtest 'filter' => sub {
  for my $target ($package, $object) {
    $target->logfilter(qw/debug info/);
    $capture->start;
    $target->log( array => 'message', 'array' );
    $capture->stop;

    ok !$capture->read, 'filtered out';

    $capture->start;
    $target->log( debug => 'debug' );
    $target->log( info  => 'info' );
    $capture->stop;

    like $capture->read => qr/\[debug\] debug/, 'captured';
    like $capture->read => qr/\[info\] info/, 'captured';

    $target->logfilter('');
    $capture->start;
    $target->log( array => 'message', 'array' );
    $capture->stop;

    my $read = join "\n", $capture->read;

    like $read => qr/\[array\] messagearray/, 'captured again';
  }
};

subtest 'negative_filter' => sub {
  for my $target ($package, $object) {
    $target->logfilter(qw/!debug !info/);
    $capture->start;
    $target->log( debug => 'debug' );
    $target->log( info  => 'info' );
    $capture->stop;

    is $capture->read => undef, 'filtered out';

    $capture->start;
    $target->log( array => 'message', 'array' );
    $capture->stop;

    like $capture->read => qr/\[array\] messagearray/, 'captured';

    $target->logfilter('');
    $capture->start;
    $target->log( debug => 'debug' );
    $target->log( info  => 'info' );
    $capture->stop;

    my $read = join "\n", $capture->read;

    like $read => qr/\[debug\] debug/, 'captured again';
    like $read => qr/\[info\] info/, 'captured again';
  }
};

subtest 'mixed_filter' => sub {
  for my $target ($package, $object) {
    $target->logfilter(qw/!debug !info warn error/);
    $capture->start;
    $target->log( debug => 'debug' );
    $target->log( info  => 'info' );
    $target->log( array => 'message', 'array' );
    $capture->stop;

    is $capture->read => undef, 'filtered out';

    $capture->start;
    $target->log( warn  => 'warn' );
    $target->log( error => 'error' );
    $capture->stop;

    like $capture->read => qr/\[warn\] warn/, 'captured';
    like $capture->read => qr/\[error\] error/, 'captured';

    $target->logfilter('');
    $capture->start;
    $target->log( debug => 'debug' );
    $target->log( info  => 'info' );
    $capture->stop;

    my $read = join "\n", $capture->read;

    like $read => qr/\[debug\] debug/, 'captured again';
    like $read => qr/\[info\] info/, 'captured again';
  }
};

done_testing;
