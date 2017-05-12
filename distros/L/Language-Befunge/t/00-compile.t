use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 37 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Language/Befunge.pm',
    'Language/Befunge/Debug.pm',
    'Language/Befunge/IP.pm',
    'Language/Befunge/Interpreter.pm',
    'Language/Befunge/Ops.pm',
    'Language/Befunge/Ops/Befunge98.pm',
    'Language/Befunge/Ops/GenericFunge98.pm',
    'Language/Befunge/Ops/Unefunge98.pm',
    'Language/Befunge/Storage.pm',
    'Language/Befunge/Storage/2D/Sparse.pm',
    'Language/Befunge/Storage/Generic/AoA.pm',
    'Language/Befunge/Storage/Generic/Sparse.pm',
    'Language/Befunge/Storage/Generic/Vec.pm',
    'Language/Befunge/Vector.pm',
    'Language/Befunge/Wrapping.pm',
    'Language/Befunge/Wrapping/LaheySpace.pm',
    'Language/Befunge/lib/BASE.pm',
    'Language/Befunge/lib/BOOL.pm',
    'Language/Befunge/lib/CPLI.pm',
    'Language/Befunge/lib/DIRF.pm',
    'Language/Befunge/lib/EVAR.pm',
    'Language/Befunge/lib/FILE.pm',
    'Language/Befunge/lib/FIXP.pm',
    'Language/Befunge/lib/FOO.pm',
    'Language/Befunge/lib/HELO.pm',
    'Language/Befunge/lib/HRTI.pm',
    'Language/Befunge/lib/MODU.pm',
    'Language/Befunge/lib/NULL.pm',
    'Language/Befunge/lib/ORTH.pm',
    'Language/Befunge/lib/PERL.pm',
    'Language/Befunge/lib/REFC.pm',
    'Language/Befunge/lib/ROMA.pm',
    'Language/Befunge/lib/STRN.pm',
    'Language/Befunge/lib/SUBR.pm',
    'Language/Befunge/lib/TEST.pm',
    'Language/Befunge/lib/TIME.pm'
);

my @scripts = (
    'bin/jqbef98'
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

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    my @flags = $1 ? split(' ', $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


