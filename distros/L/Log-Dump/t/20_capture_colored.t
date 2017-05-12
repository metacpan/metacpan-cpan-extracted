use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Log::Dump::Test::Class;

BEGIN {
  for my $package (qw/Term::ANSIColor IO::Capture::Stderr/) {
    eval "require $package; 1"
      or plan skip_all => "requires $package";
  }
}

my $capture = IO::Capture::Stderr->new;
my $package = 'Log::Dump::Test::Class';
my $object  = $package->new;

subtest 'color' => sub {
  for my $target ($package, $object) {
    $target->logcolor( color => 'bold red on_white' );
    $capture->start;
    $target->log( color => 'message' );
    $capture->stop;

    # Let's see a colored message to see if it actually works
    $target->log( color => 'message' );

    my $colored = $capture->read;
    like $colored => qr/\[color\] .+message.+/, 'captured';
    $target->logcolor(''); # no more color

    $capture->start;
    $target->log( color => 'message' );
    $capture->stop;

    my $uncolored = $capture->read;
    like $uncolored => qr/\[color\] message/, 'captured';

    ok $colored ne $uncolored, 'colored and uncolored are different';
  }
};

done_testing;
