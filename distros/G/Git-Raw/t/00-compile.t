use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 59 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Git/Raw.pm',
    'Git/Raw/AnnotatedCommit.pm',
    'Git/Raw/Blame.pm',
    'Git/Raw/Blame/Hunk.pm',
    'Git/Raw/Blob.pm',
    'Git/Raw/Branch.pm',
    'Git/Raw/Cert.pm',
    'Git/Raw/Cert/HostKey.pm',
    'Git/Raw/Cert/X509.pm',
    'Git/Raw/Commit.pm',
    'Git/Raw/Config.pm',
    'Git/Raw/Cred.pm',
    'Git/Raw/Diff.pm',
    'Git/Raw/Diff/Delta.pm',
    'Git/Raw/Diff/File.pm',
    'Git/Raw/Diff/Hunk.pm',
    'Git/Raw/Diff/Stats.pm',
    'Git/Raw/Error.pm',
    'Git/Raw/Error/Category.pm',
    'Git/Raw/Filter.pm',
    'Git/Raw/Filter/List.pm',
    'Git/Raw/Filter/Source.pm',
    'Git/Raw/Graph.pm',
    'Git/Raw/Index.pm',
    'Git/Raw/Index/Conflict.pm',
    'Git/Raw/Index/Entry.pm',
    'Git/Raw/Indexer.pm',
    'Git/Raw/Mempack.pm',
    'Git/Raw/Merge/File/Result.pm',
    'Git/Raw/Note.pm',
    'Git/Raw/Object.pm',
    'Git/Raw/Odb.pm',
    'Git/Raw/Odb/Backend.pm',
    'Git/Raw/Odb/Backend/Loose.pm',
    'Git/Raw/Odb/Backend/OnePack.pm',
    'Git/Raw/Odb/Backend/Pack.pm',
    'Git/Raw/Odb/Object.pm',
    'Git/Raw/Packbuilder.pm',
    'Git/Raw/Patch.pm',
    'Git/Raw/PathSpec.pm',
    'Git/Raw/PathSpec/MatchList.pm',
    'Git/Raw/Rebase.pm',
    'Git/Raw/Rebase/Operation.pm',
    'Git/Raw/RefSpec.pm',
    'Git/Raw/Reference.pm',
    'Git/Raw/Reflog.pm',
    'Git/Raw/Reflog/Entry.pm',
    'Git/Raw/Remote.pm',
    'Git/Raw/Repository.pm',
    'Git/Raw/Signature.pm',
    'Git/Raw/Stash.pm',
    'Git/Raw/Stash/Progress.pm',
    'Git/Raw/Tag.pm',
    'Git/Raw/TransferProgress.pm',
    'Git/Raw/Tree.pm',
    'Git/Raw/Tree/Builder.pm',
    'Git/Raw/Tree/Entry.pm',
    'Git/Raw/Walker.pm',
    'Git/Raw/Worktree.pm'
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
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


