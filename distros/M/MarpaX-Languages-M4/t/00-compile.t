use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.052

use Test::More;

plan tests => 28 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'MarpaX/Languages/M4.pm',
    'MarpaX/Languages/M4/Impl/Default.pm',
    'MarpaX/Languages/M4/Impl/Default/BaseConversion.pm',
    'MarpaX/Languages/M4/Impl/Default/Eval.pm',
    'MarpaX/Languages/M4/Impl/Input.pm',
    'MarpaX/Languages/M4/Impl/Macro.pm',
    'MarpaX/Languages/M4/Impl/Macros.pm',
    'MarpaX/Languages/M4/Impl/Parser.pm',
    'MarpaX/Languages/M4/Impl/Parser/Actions.pm',
    'MarpaX/Languages/M4/Impl/Regexp.pm',
    'MarpaX/Languages/M4/Impl/Value.pm',
    'MarpaX/Languages/M4/Role/Builtin.pm',
    'MarpaX/Languages/M4/Role/Impl.pm',
    'MarpaX/Languages/M4/Role/Input.pm',
    'MarpaX/Languages/M4/Role/Logger.pm',
    'MarpaX/Languages/M4/Role/Macro.pm',
    'MarpaX/Languages/M4/Role/Macros.pm',
    'MarpaX/Languages/M4/Role/Parser.pm',
    'MarpaX/Languages/M4/Role/Regexp.pm',
    'MarpaX/Languages/M4/Role/Value.pm',
    'MarpaX/Languages/M4/Type/Impl.pm',
    'MarpaX/Languages/M4/Type/Input.pm',
    'MarpaX/Languages/M4/Type/Logger.pm',
    'MarpaX/Languages/M4/Type/Macro.pm',
    'MarpaX/Languages/M4/Type/Regexp.pm',
    'MarpaX/Languages/M4/Type/Token.pm',
    'MarpaX/Languages/M4/Type/Value.pm'
);

my @scripts = (
    'bin/m4pp'
);

# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


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


