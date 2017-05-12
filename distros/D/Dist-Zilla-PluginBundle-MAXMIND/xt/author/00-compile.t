use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.056

use Test::More;

plan tests => 10;

my @module_files = (
    'Dist/Zilla/Plugin/MAXMIND/CheckChangesHasContent.pm',
    'Dist/Zilla/Plugin/MAXMIND/Contributors.pm',
    'Dist/Zilla/Plugin/MAXMIND/Git/CheckFor/CorrectBranch.pm',
    'Dist/Zilla/Plugin/MAXMIND/License.pm',
    'Dist/Zilla/Plugin/MAXMIND/TidyAll.pm',
    'Dist/Zilla/Plugin/MAXMIND/VersionProvider.pm',
    'Dist/Zilla/Plugin/MAXMIND/WeaverConfig.pm',
    'Dist/Zilla/PluginBundle/MAXMIND.pm',
    'Pod/Weaver/PluginBundle/MAXMIND.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
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
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


