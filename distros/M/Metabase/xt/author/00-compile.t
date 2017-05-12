use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.037

use Test::More  tests => 13 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Metabase.pm',
    'Metabase/Archive.pm',
    'Metabase/Archive/Filesystem.pm',
    'Metabase/Gateway.pm',
    'Metabase/Index.pm',
    'Metabase/Index/FlatFile.pm',
    'Metabase/Librarian.pm',
    'Metabase/Query.pm',
    'Metabase/Test/Archive.pm',
    'Metabase/Test/Archive/Null.pm',
    'Metabase/Test/Fact.pm',
    'Metabase/Test/Factory.pm',
    'Metabase/Test/Index.pm'
);



# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


