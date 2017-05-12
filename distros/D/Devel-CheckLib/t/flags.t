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

sub diagout { diag "\tSTDOUT: $stdout\n\tSTDERR: $stderr\n" }

my %common = ( debug => $debug,
               incpath => 't/inc',
               libpath => $libdir,
               lib => 'bazbam',
               header => 'headerfile.h',
               function => <<EOF);

#ifdef FOO1234
return 0;
#else
return 1;
#endif

EOF

capture
    sub { eval { assert_lib(%common, ccflags => '-DFOO1234') } },
    \$stdout, \$stderr;
is($@, '', "ccflags ok") or diagout;

capture
    sub { eval { assert_lib(%common) } },
    \$stdout, \$stderr;
like($@, qr/wrong/i, "ccflags wrong") or diagout;

done_testing;
