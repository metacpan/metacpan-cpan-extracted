use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.057

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;

plan tests => 22 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Dist/Zilla/Plugin/Hook.pm',
    'Dist/Zilla/Plugin/Hook/AfterBuild.pm',
    'Dist/Zilla/Plugin/Hook/AfterMint.pm',
    'Dist/Zilla/Plugin/Hook/AfterRelease.pm',
    'Dist/Zilla/Plugin/Hook/BeforeArchive.pm',
    'Dist/Zilla/Plugin/Hook/BeforeBuild.pm',
    'Dist/Zilla/Plugin/Hook/BeforeMint.pm',
    'Dist/Zilla/Plugin/Hook/BeforeRelease.pm',
    'Dist/Zilla/Plugin/Hook/FileGatherer.pm',
    'Dist/Zilla/Plugin/Hook/FileMunger.pm',
    'Dist/Zilla/Plugin/Hook/FilePruner.pm',
    'Dist/Zilla/Plugin/Hook/Init.pm',
    'Dist/Zilla/Plugin/Hook/InstallTool.pm',
    'Dist/Zilla/Plugin/Hook/LicenseProvider.pm',
    'Dist/Zilla/Plugin/Hook/MetaProvider.pm',
    'Dist/Zilla/Plugin/Hook/ModuleMaker.pm',
    'Dist/Zilla/Plugin/Hook/NameProvider.pm',
    'Dist/Zilla/Plugin/Hook/PrereqSource.pm',
    'Dist/Zilla/Plugin/Hook/ReleaseStatusProvider.pm',
    'Dist/Zilla/Plugin/Hook/Releaser.pm',
    'Dist/Zilla/Plugin/Hook/VersionProvider.pm',
    'Dist/Zilla/Role/Hooker.pm'
);



# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


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
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


