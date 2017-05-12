use strict;
use Test::More tests => 4;

use Log::Dispatch::Config;
use FileHandle;
use IO::Scalar;
use File::Spec;

sub slurp {
    my $fh = FileHandle->new(shift) or die $!;
    local $/;
    return $fh->getline;
}

my $log;
BEGIN { $log = 't/log.out'; unlink $log if -e $log }
END   { unlink $log if -e $log }

Log::Dispatch::Config->configure('t/log.cfg');

my $err;
{
    tie *STDERR, 'IO::Scalar', \$err;

    my $disp = Log::Dispatch::Config->instance;
    $disp->debug('debug');
    $disp->alert('alert');
}

my $filename = __FILE__;
my $file = slurp $log;
like $file, qr(debug at \Q$filename\E), 'debug';
like $file, qr(alert at \Q$filename\E), 'alert';

ok $err !~ qr/debug/, 'no debug';
is $err, "alert %", 'alert %';



