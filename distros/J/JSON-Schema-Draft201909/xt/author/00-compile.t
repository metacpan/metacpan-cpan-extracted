use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More 0.94;

plan tests => 14;

my @module_files = (
    'JSON/Schema/Draft201909.pm',
    'JSON/Schema/Draft201909/Annotation.pm',
    'JSON/Schema/Draft201909/Document.pm',
    'JSON/Schema/Draft201909/Error.pm',
    'JSON/Schema/Draft201909/Result.pm',
    'JSON/Schema/Draft201909/Utilities.pm',
    'JSON/Schema/Draft201909/Vocabulary.pm',
    'JSON/Schema/Draft201909/Vocabulary/Applicator.pm',
    'JSON/Schema/Draft201909/Vocabulary/Content.pm',
    'JSON/Schema/Draft201909/Vocabulary/Core.pm',
    'JSON/Schema/Draft201909/Vocabulary/Format.pm',
    'JSON/Schema/Draft201909/Vocabulary/MetaData.pm',
    'JSON/Schema/Draft201909/Vocabulary/Validation.pm'
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
    or diag 'got warnings: ', explain(\@warnings);

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
