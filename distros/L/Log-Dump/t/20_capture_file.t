use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp;
use Log::Dump::Test::Class;

BEGIN {
  eval { require IO::Capture::Stderr; 1 }
    or plan skip_all => 'requires IO::Capture::Stderr';
}

my $capture = IO::Capture::Stderr->new;
my $package = 'Log::Dump::Test::Class';
my $object  = $package->new;

subtest 'file' => sub {
  my $logfile = File::Temp::tmpnam();

  for my $target ($package, $object) {
    unlink $logfile if -f $logfile;

    ok !-f $logfile, 'logfile does not exist';
    $target->logfile($logfile);
    $capture->start;
    $target->log( debug => 'message' );
    $capture->stop;

    like $capture->read => qr/\[debug\] message/, 'captured';

    $target->logfile(''); # this should close the file

    ok -f $logfile, 'logfile does exist';
    open my $fh, '<', $logfile;
    my $read = <$fh>;
    like $read => qr/\[debug\] message/, 'captured from logfile';
    close $fh;

    unlink $logfile;
    ok !-f $logfile, 'logfile is removed';

    $capture->start;
    $target->log( debug => 'message' );
    $capture->stop;

    like $capture->read => qr/\[debug\] message/, 'captured';

    ok !-f $logfile, 'logfile does not exist';
  }
};

done_testing;
