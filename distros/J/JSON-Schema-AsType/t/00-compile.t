use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.059

use Test::More;

plan tests => 35 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'JSON/Schema/AsType.pm',
    'JSON/Schema/AsType/Annotations.pm',
    'JSON/Schema/AsType/Draft2019_09.pm',
    'JSON/Schema/AsType/Draft2019_09/Types.pm',
    'JSON/Schema/AsType/Draft2019_09/Vocabulary/Applicator.pm',
    'JSON/Schema/AsType/Draft2019_09/Vocabulary/Content.pm',
    'JSON/Schema/AsType/Draft2019_09/Vocabulary/Core.pm',
    'JSON/Schema/AsType/Draft2019_09/Vocabulary/Format.pm',
    'JSON/Schema/AsType/Draft2019_09/Vocabulary/Metadata.pm',
    'JSON/Schema/AsType/Draft2019_09/Vocabulary/Validation.pm',
    'JSON/Schema/AsType/Draft2020_12.pm',
    'JSON/Schema/AsType/Draft2020_12/Types.pm',
    'JSON/Schema/AsType/Draft2020_12/Vocabulary/Applicator.pm',
    'JSON/Schema/AsType/Draft2020_12/Vocabulary/Content.pm',
    'JSON/Schema/AsType/Draft2020_12/Vocabulary/Core.pm',
    'JSON/Schema/AsType/Draft2020_12/Vocabulary/Format.pm',
    'JSON/Schema/AsType/Draft2020_12/Vocabulary/Formatannotation.pm',
    'JSON/Schema/AsType/Draft2020_12/Vocabulary/Metadata.pm',
    'JSON/Schema/AsType/Draft2020_12/Vocabulary/Unevaluated.pm',
    'JSON/Schema/AsType/Draft2020_12/Vocabulary/Validation.pm',
    'JSON/Schema/AsType/Draft3.pm',
    'JSON/Schema/AsType/Draft3/Keywords.pm',
    'JSON/Schema/AsType/Draft3/Types.pm',
    'JSON/Schema/AsType/Draft4.pm',
    'JSON/Schema/AsType/Draft4/Keywords.pm',
    'JSON/Schema/AsType/Draft4/Types.pm',
    'JSON/Schema/AsType/Draft6.pm',
    'JSON/Schema/AsType/Draft6/Keywords.pm',
    'JSON/Schema/AsType/Draft6/Types.pm',
    'JSON/Schema/AsType/Draft7.pm',
    'JSON/Schema/AsType/Draft7/Keywords.pm',
    'JSON/Schema/AsType/Draft7/Types.pm',
    'JSON/Schema/AsType/Registry.pm',
    'JSON/Schema/AsType/Type.pm',
    'JSON/Schema/AsType/Visit.pm'
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



is(scalar(@warnings), 0, 'no warnings found') or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


