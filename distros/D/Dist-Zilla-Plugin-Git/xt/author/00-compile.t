use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.056

use Test::More 0.94;

plan tests => 14;

my @module_files = (
    'Dist/Zilla/Plugin/Git.pm',
    'Dist/Zilla/Plugin/Git/Check.pm',
    'Dist/Zilla/Plugin/Git/Commit.pm',
    'Dist/Zilla/Plugin/Git/CommitBuild.pm',
    'Dist/Zilla/Plugin/Git/GatherDir.pm',
    'Dist/Zilla/Plugin/Git/Init.pm',
    'Dist/Zilla/Plugin/Git/NextVersion.pm',
    'Dist/Zilla/Plugin/Git/Push.pm',
    'Dist/Zilla/Plugin/Git/Tag.pm',
    'Dist/Zilla/PluginBundle/Git.pm',
    'Dist/Zilla/Role/Git/DirtyFiles.pm',
    'Dist/Zilla/Role/Git/Repo.pm',
    'Dist/Zilla/Role/Git/StringFormatter.pm'
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
    or diag 'got warnings: ', explain(\@warnings);

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
