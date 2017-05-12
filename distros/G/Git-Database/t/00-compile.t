use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 23 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Git/Database.pm',
    'Git/Database/Actor.pm',
    'Git/Database/Backend/Cogit.pm',
    'Git/Database/Backend/Git.pm',
    'Git/Database/Backend/Git/PurePerl.pm',
    'Git/Database/Backend/Git/Raw/Repository.pm',
    'Git/Database/Backend/Git/Repository.pm',
    'Git/Database/Backend/Git/Sub.pm',
    'Git/Database/Backend/Git/Wrapper.pm',
    'Git/Database/Backend/None.pm',
    'Git/Database/DirectoryEntry.pm',
    'Git/Database/Object/Blob.pm',
    'Git/Database/Object/Commit.pm',
    'Git/Database/Object/Raw.pm',
    'Git/Database/Object/Tag.pm',
    'Git/Database/Object/Tree.pm',
    'Git/Database/Role/Backend.pm',
    'Git/Database/Role/Object.pm',
    'Git/Database/Role/ObjectReader.pm',
    'Git/Database/Role/ObjectWriter.pm',
    'Git/Database/Role/PurePerlBackend.pm',
    'Git/Database/Role/RefReader.pm',
    'Git/Database/Role/RefWriter.pm'
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


