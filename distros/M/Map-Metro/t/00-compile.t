use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 28 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Map/Metro.pm',
    'Map/Metro/Cmd.pm',
    'Map/Metro/Cmd/AllRoutes.pm',
    'Map/Metro/Cmd/Available.pm',
    'Map/Metro/Cmd/Graphviz.pm',
    'Map/Metro/Cmd/Lines.pm',
    'Map/Metro/Cmd/MetroToTube.pm',
    'Map/Metro/Cmd/Route.pm',
    'Map/Metro/Cmd/Stations.pm',
    'Map/Metro/Elk.pm',
    'Map/Metro/Emitter.pm',
    'Map/Metro/Exceptions.pm',
    'Map/Metro/Graph.pm',
    'Map/Metro/Graph/Connection.pm',
    'Map/Metro/Graph/Line.pm',
    'Map/Metro/Graph/LineStation.pm',
    'Map/Metro/Graph/Route.pm',
    'Map/Metro/Graph/Routing.pm',
    'Map/Metro/Graph/Segment.pm',
    'Map/Metro/Graph/Station.pm',
    'Map/Metro/Graph/Step.pm',
    'Map/Metro/Graph/Transfer.pm',
    'Map/Metro/Hook.pm',
    'Map/Metro/Plugin/Hook/PrettyPrinter.pm',
    'Map/Metro/Plugin/Hook/StreamStations.pm',
    'Map/Metro/Plugin/Map.pm',
    'Map/Metro/Shim.pm',
    'Map/Metro/Types.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


