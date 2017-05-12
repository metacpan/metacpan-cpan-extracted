use strict;
use Test::More tests => 4;

use Log::Dispatch::Configurator::Perl;
use Log::Dispatch::Config;
use FileHandle;
use IO::Scalar;

sub slurp {
    my $fh = FileHandle->new(shift) or die $!;
    local $/;
    return $fh->getline;
}

my $log;
BEGIN { $log = 't/log.out'; unlink $log if -e $log }
END   { unlink $log if -e $log }

my $config = Log::Dispatch::Configurator::Perl->new('t/conf.pl');
Log::Dispatch::Config->configure($config);

my $err;
{
    tie *STDERR, 'IO::Scalar', \$err;

    my $disp = Log::Dispatch::Config->instance;
    $disp->debug('debug');
    $disp->alert('alert');
}


my $file = slurp $log;
like $file, qr(debug at t[/\\]02_log\.t), 'debug';
like $file, qr(alert at t[/\\]02_log\.t), 'alert';

ok $err !~ qr/debug/, 'no debug';
is $err, "alert %", 'alert %';
