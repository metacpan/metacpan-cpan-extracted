use strict;
use warnings;
use Test::More tests => 2;

use Log::Any::Adapter;
use Log::Any '$log';

use FindBin;
use lib $FindBin::RealBin;
use TestAdapters;

sub create_normal_log_lines {
    my ($log) = @_;

    $log->info('some info');
    $log->infof( 'more %s', 'info' );
    $log->infof( 'info %s %s', { with => 'data' }, 'and more text' );
    $log->debug( "program started",
        { progname => "foo.pl", pid => 1234, perl_version => "5.20.0" } );

}

Log::Any::Adapter->set('+TestAdapters::Normal');
create_normal_log_lines($log);

Log::Any::Adapter->set('+TestAdapters::Structured');
create_normal_log_lines($log);
$log->info(
    'text',
    { and => [ 'structured', 'data', of => [ arbitrary => 'depth' ] ] },
    'and some more text'
);

is_deeply(
    \@TestAdapters::TEXT_LOG, [

        "some info",
        "more info",
        "info {with => \"data\"} and more text",
        "program started {perl_version => \"5.20.0\",pid => 1234,progname => \"foo.pl\"}"
    ],
    'text log correct'
);

is_deeply(
    \@TestAdapters::STRUCTURED_LOG,
    [   { messages => ['some info'], level => 'info', category => 'main' },
        { messages => ['more info'], level => 'info', category => 'main' },
        { messages => ['info {with => "data"} and more text'],
          level    => 'info',
          category => 'main'
        },
        {   messages => ['program started'],
            level    => 'debug',
            category => 'main',
            data     => [
                { perl_version => "5.20.0", progname => "foo.pl", pid => 1234 }
                ]
        },
        {   messages => [ 'text', 'and some more text' ],
            data     => [
                {   and =>
                        [ 'structured', 'data', of => [ arbitrary => 'depth' ] ]
                }
                ],
            level    => 'info',
            category => 'main'
        }
    ],
    'identical output of normal log lines when using structured log adapter'
    );
