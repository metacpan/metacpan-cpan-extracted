use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 51;

my @module_files = (
    'Iterator/Flex.pm',
    'Iterator/Flex/Array.pm',
    'Iterator/Flex/ArrayLike.pm',
    'Iterator/Flex/Base.pm',
    'Iterator/Flex/Buffer.pm',
    'Iterator/Flex/Cache.pm',
    'Iterator/Flex/Cat.pm',
    'Iterator/Flex/Chunk.pm',
    'Iterator/Flex/Common.pm',
    'Iterator/Flex/Cycle.pm',
    'Iterator/Flex/Factory.pm',
    'Iterator/Flex/Failure.pm',
    'Iterator/Flex/Freeze.pm',
    'Iterator/Flex/Gather.pm',
    'Iterator/Flex/Gather/Constants.pm',
    'Iterator/Flex/Grep.pm',
    'Iterator/Flex/Map.pm',
    'Iterator/Flex/Method.pm',
    'Iterator/Flex/Permute.pm',
    'Iterator/Flex/Product.pm',
    'Iterator/Flex/Role.pm',
    'Iterator/Flex/Role/Current/Closure.pm',
    'Iterator/Flex/Role/Current/Method.pm',
    'Iterator/Flex/Role/Error/Throw.pm',
    'Iterator/Flex/Role/Exhaustion/ImportedReturn.pm',
    'Iterator/Flex/Role/Exhaustion/ImportedThrow.pm',
    'Iterator/Flex/Role/Exhaustion/PassthroughThrow.pm',
    'Iterator/Flex/Role/Exhaustion/Return.pm',
    'Iterator/Flex/Role/Exhaustion/Throw.pm',
    'Iterator/Flex/Role/Freeze.pm',
    'Iterator/Flex/Role/Next/ClosedSelf.pm',
    'Iterator/Flex/Role/Next/Closure.pm',
    'Iterator/Flex/Role/Prev/Closure.pm',
    'Iterator/Flex/Role/Prev/Method.pm',
    'Iterator/Flex/Role/Reset/Closure.pm',
    'Iterator/Flex/Role/Reset/Method.pm',
    'Iterator/Flex/Role/Rewind/Closure.pm',
    'Iterator/Flex/Role/Rewind/Method.pm',
    'Iterator/Flex/Role/State.pm',
    'Iterator/Flex/Role/State/Closure.pm',
    'Iterator/Flex/Role/State/Registry.pm',
    'Iterator/Flex/Role/Utils.pm',
    'Iterator/Flex/Role/Wrap/Return.pm',
    'Iterator/Flex/Role/Wrap/Self.pm',
    'Iterator/Flex/Role/Wrap/Throw.pm',
    'Iterator/Flex/Sequence.pm',
    'Iterator/Flex/Stack.pm',
    'Iterator/Flex/Take.pm',
    'Iterator/Flex/Utils.pm',
    'Iterator/Flex/Zip.pm'
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
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


