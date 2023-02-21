use strict;
use warnings;
use Test::More tests => 1;
use Log::Any::Test;
use Log::Any qw($log);
use File::Temp qw(tempdir);
use File::Path;
use HTML::Mason::Interp;

sub write_file {
    my ( $file, $content ) = @_;
    open( my $fh, ">$file" );
    $fh->print($content);
}

my $comp_root = tempdir( 'mason-log-t-XXXX', TMPDIR => 1, CLEANUP => 1 );
mkpath( "$comp_root/bar", 0, 0775 );

my $interp = HTML::Mason::Interp->new( comp_root => $comp_root );
write_file( "$comp_root/foo", "% \$m->log->debug('in foo');\n<& /bar/baz &>" );
write_file( "$comp_root/bar/baz", "% \$m->log->error('in bar/baz')" );
$interp->exec('/foo');

is_deeply(
    $log->msgs,
    [
        {
            category => 'HTML::Mason::Request',
            level    => 'debug',
            message  => 'top path is \'/foo\''
        },
        {
            category => 'HTML::Mason::Request',
            level    => 'debug',
            message  => 'starting request for \'/foo\''
        },
        {
            category => 'HTML::Mason::Request',
            level    => 'debug',
            message  => 'entering component \'/foo\' [depth 0]'
        },
        {
            category => 'HTML::Mason::Component::foo',
            level    => 'debug',
            message  => 'in foo'
        },
        {
            category => 'HTML::Mason::Request',
            level    => 'debug',
            message  => 'entering component \'/bar/baz\' [depth 1]'
        },
        {
            category => 'HTML::Mason::Component::bar::baz',
            level    => 'error',
            message  => 'in bar/baz'
        },
        {
            category => 'HTML::Mason::Request',
            level    => 'debug',
            message  => 'exiting component \'/bar/baz\' [depth 1]'
        },
        {
            category => 'HTML::Mason::Request',
            level    => 'debug',
            message  => 'exiting component \'/foo\' [depth 0]'
        },
        {
            category => 'HTML::Mason::Request',
            level    => 'debug',
            message  => 'finishing request for \'/foo\''
        }
    ]
);
