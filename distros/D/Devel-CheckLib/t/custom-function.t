use strict;
# compatible use warnings
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }

use lib 't/lib';
use IO::CaptureOutput qw(capture);
use Config;

use File::Spec;
use Test::More;

eval "use Devel::CheckLib";
if($@ =~ /Couldn't find your C compiler/) {
    plan skip_all => "Couldn't find your C compiler";
}
my $libdir;
eval "use Helper qw(create_testlib)";
unless($libdir = create_testlib("bazbam")) {
    plan skip_all => "Couldn't build a library to test against";
};

my($debug, $stdout, $stderr) = ($ENV{DEVEL_CHECKLIB_DEBUG} || 0);

# cases are strings to interpolate into the assert_lib call
my %failcases = (
    qq{
        incpath => 't/inc',
        libpath => '$libdir',
        lib => 'bazbam',
        header => 'headerfile.h',
        # bar() doesn't exist
        function => 'bar();'
    } => 'Can\'t link/include',
    qq{
        incpath => 't/inc',
        libpath => '$libdir',
        lib => 'bazbam',
        header => 'headerfile.h',
        # libversion returns wrong result
        function => 'foo();if(libversion() < 5) return 0; else return 1;'
    } => 'wrong result',
);
my %passcases = (
    qq{
        incpath => 't/inc',
        libpath => '$libdir',
        lib => 'bazbam',
        header => 'headerfile.h',
        functionbody => 'foo(); return 0;'
    }, "function exists",
    qq{
        incpath => 't/inc',
        libpath => '$libdir',
        lib => 'bazbam',
        header => 'headerfile.h',
        functionbody => 'if(libversion() > 5) return 0; else return 1;'
    }, "function returns right value",
    qq{
        incpath => 't/inc',
        libpath => '$libdir',
        lib => 'bazbam',
        header => 'headerfile.h',
        functionbody => 'foo();if(libversion() > 5) return 0; else return 1;'
    }, "function exists and other function returns right value",
);

plan tests => scalar(keys %failcases) + scalar(keys %passcases);

for my $c (keys %failcases) {
    capture(
        sub { eval "assert_lib(debug => $debug, $c)"; },
        \$stdout,
        \$stderr
    );
    ok($@ =~ /^$failcases{$c}/, "failed to build: $failcases{$c}") ||
        diag("$c\n$@\n\tSTDOUT: $stdout\n\tSTDERR: $stderr\n");
}
for my $c ( keys %passcases ) {
    capture(
        sub { eval "assert_lib(debug => $debug, $c)"; },
        \$stdout,
        \$stderr
    );
    is($@, q{}, "$passcases{$c}") ||
        diag("\tSTDOUT: $stdout\n\tSTDERR: $stderr\n");
}
