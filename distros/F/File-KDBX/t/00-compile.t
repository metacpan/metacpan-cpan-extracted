use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 38 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'File/KDBX.pm',
    'File/KDBX/Cipher.pm',
    'File/KDBX/Cipher/CBC.pm',
    'File/KDBX/Cipher/Stream.pm',
    'File/KDBX/Constants.pm',
    'File/KDBX/Dumper.pm',
    'File/KDBX/Dumper/KDB.pm',
    'File/KDBX/Dumper/Raw.pm',
    'File/KDBX/Dumper/V3.pm',
    'File/KDBX/Dumper/V4.pm',
    'File/KDBX/Dumper/XML.pm',
    'File/KDBX/Entry.pm',
    'File/KDBX/Error.pm',
    'File/KDBX/Group.pm',
    'File/KDBX/IO.pm',
    'File/KDBX/IO/Crypt.pm',
    'File/KDBX/IO/HashBlock.pm',
    'File/KDBX/IO/HmacBlock.pm',
    'File/KDBX/Iterator.pm',
    'File/KDBX/KDF.pm',
    'File/KDBX/KDF/AES.pm',
    'File/KDBX/KDF/Argon2.pm',
    'File/KDBX/Key.pm',
    'File/KDBX/Key/ChallengeResponse.pm',
    'File/KDBX/Key/Composite.pm',
    'File/KDBX/Key/File.pm',
    'File/KDBX/Key/Password.pm',
    'File/KDBX/Key/YubiKey.pm',
    'File/KDBX/Loader.pm',
    'File/KDBX/Loader/KDB.pm',
    'File/KDBX/Loader/Raw.pm',
    'File/KDBX/Loader/V3.pm',
    'File/KDBX/Loader/V4.pm',
    'File/KDBX/Loader/XML.pm',
    'File/KDBX/Object.pm',
    'File/KDBX/Safe.pm',
    'File/KDBX/Transaction.pm',
    'File/KDBX/Util.pm'
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


