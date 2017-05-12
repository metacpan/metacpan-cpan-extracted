use strict;
use warnings;

use Test::More 0.88;

use Config;

BEGIN {
    plan skip_all => 'This test only runs on threaded perls'
        unless $Config{usethreads};
}

use Test::Needs {
    'Sys::Syslog' => '0.28',
};

use Log::Dispatch;
use Log::Dispatch::Syslog;

## no critic (TestingAndDebugging::ProhibitNoWarnings)
no warnings 'redefine', 'once';

my @sock;
local *Sys::Syslog::setlogsock = sub { @sock = @_ };

local *Sys::Syslog::openlog  = sub { return 1 };
local *Sys::Syslog::closelog = sub { return 1 };

my @log;
local *Sys::Syslog::syslog = sub { push @log, [@_] };

SKIP:
{
    @log = ();

    my $dispatch = Log::Dispatch->new;
    $dispatch->add(
        Log::Dispatch::Syslog->new(
            name      => 'syslog',
            min_level => 'debug',
            lock      => 1,
        )
    );

    $dispatch->info('Foo thread');

    is_deeply(
        \@log,
        [ [ 'INFO', 'Foo thread' ] ],
        'passed message to syslog (with thread lock, but no preloaded threads module)'
    );
}

done_testing();
