use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.059

use Test::More 0.94;

plan tests => 141;

my @module_files = (
    'Dist/Zilla.pm',
    'Dist/Zilla/App.pm',
    'Dist/Zilla/App/Command.pm',
    'Dist/Zilla/App/Command/add.pm',
    'Dist/Zilla/App/Command/authordeps.pm',
    'Dist/Zilla/App/Command/build.pm',
    'Dist/Zilla/App/Command/clean.pm',
    'Dist/Zilla/App/Command/install.pm',
    'Dist/Zilla/App/Command/listdeps.pm',
    'Dist/Zilla/App/Command/new.pm',
    'Dist/Zilla/App/Command/nop.pm',
    'Dist/Zilla/App/Command/release.pm',
    'Dist/Zilla/App/Command/run.pm',
    'Dist/Zilla/App/Command/setup.pm',
    'Dist/Zilla/App/Command/smoke.pm',
    'Dist/Zilla/App/Command/test.pm',
    'Dist/Zilla/App/Command/version.pm',
    'Dist/Zilla/App/Tester.pm',
    'Dist/Zilla/Chrome/Term.pm',
    'Dist/Zilla/Chrome/Test.pm',
    'Dist/Zilla/Dist/Builder.pm',
    'Dist/Zilla/Dist/Minter.pm',
    'Dist/Zilla/File/FromCode.pm',
    'Dist/Zilla/File/InMemory.pm',
    'Dist/Zilla/File/OnDisk.pm',
    'Dist/Zilla/MVP/Assembler.pm',
    'Dist/Zilla/MVP/Assembler/GlobalConfig.pm',
    'Dist/Zilla/MVP/Assembler/Zilla.pm',
    'Dist/Zilla/MVP/Reader/Finder.pm',
    'Dist/Zilla/MVP/Reader/Perl.pm',
    'Dist/Zilla/MVP/RootSection.pm',
    'Dist/Zilla/MVP/Section.pm',
    'Dist/Zilla/MintingProfile/Default.pm',
    'Dist/Zilla/Path.pm',
    'Dist/Zilla/Plugin/AutoPrereqs.pm',
    'Dist/Zilla/Plugin/AutoVersion.pm',
    'Dist/Zilla/Plugin/CPANFile.pm',
    'Dist/Zilla/Plugin/ConfirmRelease.pm',
    'Dist/Zilla/Plugin/DistINI.pm',
    'Dist/Zilla/Plugin/Encoding.pm',
    'Dist/Zilla/Plugin/ExecDir.pm',
    'Dist/Zilla/Plugin/ExtraTests.pm',
    'Dist/Zilla/Plugin/FakeRelease.pm',
    'Dist/Zilla/Plugin/FileFinder/ByName.pm',
    'Dist/Zilla/Plugin/FileFinder/Filter.pm',
    'Dist/Zilla/Plugin/FinderCode.pm',
    'Dist/Zilla/Plugin/GatherDir.pm',
    'Dist/Zilla/Plugin/GatherDir/Template.pm',
    'Dist/Zilla/Plugin/GatherFile.pm',
    'Dist/Zilla/Plugin/GenerateFile.pm',
    'Dist/Zilla/Plugin/InlineFiles.pm',
    'Dist/Zilla/Plugin/License.pm',
    'Dist/Zilla/Plugin/MakeMaker.pm',
    'Dist/Zilla/Plugin/MakeMaker/Runner.pm',
    'Dist/Zilla/Plugin/Manifest.pm',
    'Dist/Zilla/Plugin/ManifestSkip.pm',
    'Dist/Zilla/Plugin/MetaConfig.pm',
    'Dist/Zilla/Plugin/MetaJSON.pm',
    'Dist/Zilla/Plugin/MetaNoIndex.pm',
    'Dist/Zilla/Plugin/MetaResources.pm',
    'Dist/Zilla/Plugin/MetaTests.pm',
    'Dist/Zilla/Plugin/MetaYAML.pm',
    'Dist/Zilla/Plugin/ModuleBuild.pm',
    'Dist/Zilla/Plugin/ModuleShareDirs.pm',
    'Dist/Zilla/Plugin/NextRelease.pm',
    'Dist/Zilla/Plugin/PkgDist.pm',
    'Dist/Zilla/Plugin/PkgVersion.pm',
    'Dist/Zilla/Plugin/PodCoverageTests.pm',
    'Dist/Zilla/Plugin/PodSyntaxTests.pm',
    'Dist/Zilla/Plugin/PodVersion.pm',
    'Dist/Zilla/Plugin/Prereqs.pm',
    'Dist/Zilla/Plugin/PruneCruft.pm',
    'Dist/Zilla/Plugin/PruneFiles.pm',
    'Dist/Zilla/Plugin/Readme.pm',
    'Dist/Zilla/Plugin/RemovePrereqs.pm',
    'Dist/Zilla/Plugin/ShareDir.pm',
    'Dist/Zilla/Plugin/TemplateModule.pm',
    'Dist/Zilla/Plugin/TestRelease.pm',
    'Dist/Zilla/Plugin/UploadToCPAN.pm',
    'Dist/Zilla/PluginBundle/Basic.pm',
    'Dist/Zilla/PluginBundle/Classic.pm',
    'Dist/Zilla/PluginBundle/FakeClassic.pm',
    'Dist/Zilla/PluginBundle/Filter.pm',
    'Dist/Zilla/Pragmas.pm',
    'Dist/Zilla/Prereqs.pm',
    'Dist/Zilla/Role/AfterBuild.pm',
    'Dist/Zilla/Role/AfterMint.pm',
    'Dist/Zilla/Role/AfterRelease.pm',
    'Dist/Zilla/Role/ArchiveBuilder.pm',
    'Dist/Zilla/Role/BeforeArchive.pm',
    'Dist/Zilla/Role/BeforeBuild.pm',
    'Dist/Zilla/Role/BeforeMint.pm',
    'Dist/Zilla/Role/BeforeRelease.pm',
    'Dist/Zilla/Role/BuildPL.pm',
    'Dist/Zilla/Role/BuildRunner.pm',
    'Dist/Zilla/Role/Chrome.pm',
    'Dist/Zilla/Role/ConfigDumper.pm',
    'Dist/Zilla/Role/EncodingProvider.pm',
    'Dist/Zilla/Role/ExecFiles.pm',
    'Dist/Zilla/Role/File.pm',
    'Dist/Zilla/Role/FileFinder.pm',
    'Dist/Zilla/Role/FileFinderUser.pm',
    'Dist/Zilla/Role/FileGatherer.pm',
    'Dist/Zilla/Role/FileInjector.pm',
    'Dist/Zilla/Role/FileMunger.pm',
    'Dist/Zilla/Role/FilePruner.pm',
    'Dist/Zilla/Role/InstallTool.pm',
    'Dist/Zilla/Role/LicenseProvider.pm',
    'Dist/Zilla/Role/MetaProvider.pm',
    'Dist/Zilla/Role/MintingProfile.pm',
    'Dist/Zilla/Role/MintingProfile/ShareDir.pm',
    'Dist/Zilla/Role/ModuleMaker.pm',
    'Dist/Zilla/Role/MutableFile.pm',
    'Dist/Zilla/Role/NameProvider.pm',
    'Dist/Zilla/Role/PPI.pm',
    'Dist/Zilla/Role/Plugin.pm',
    'Dist/Zilla/Role/PluginBundle.pm',
    'Dist/Zilla/Role/PluginBundle/Easy.pm',
    'Dist/Zilla/Role/PrereqScanner.pm',
    'Dist/Zilla/Role/PrereqSource.pm',
    'Dist/Zilla/Role/ReleaseStatusProvider.pm',
    'Dist/Zilla/Role/Releaser.pm',
    'Dist/Zilla/Role/ShareDir.pm',
    'Dist/Zilla/Role/Stash.pm',
    'Dist/Zilla/Role/Stash/Authors.pm',
    'Dist/Zilla/Role/Stash/Login.pm',
    'Dist/Zilla/Role/StubBuild.pm',
    'Dist/Zilla/Role/TestRunner.pm',
    'Dist/Zilla/Role/TextTemplate.pm',
    'Dist/Zilla/Role/VersionProvider.pm',
    'Dist/Zilla/Stash/Mint.pm',
    'Dist/Zilla/Stash/PAUSE.pm',
    'Dist/Zilla/Stash/Rights.pm',
    'Dist/Zilla/Stash/User.pm',
    'Dist/Zilla/Tester.pm',
    'Dist/Zilla/Types.pm',
    'Dist/Zilla/Util.pm',
    'Dist/Zilla/Util/AuthorDeps.pm',
    'Test/DZil.pm'
);

my @scripts = (
    'bin/dzil'
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

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'}.$str.q{'} }
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

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*(?:env )?perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    close $fh and skip("$file uses -T; not testable with PERL5LIB", 1)
        if grep $_ eq '-T', @switches and $ENV{PERL5LIB};

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'}.$str.q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep !/\bsyntax OK$/,
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found') or diag 'got warnings: ', explain(\@warnings);

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
