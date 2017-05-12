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

my($debug, $stdout, $stderr) = ($ENV{DEVEL_CHECKLIB_DEBUG} || 0);

# cases are strings to interpolate into the assert_lib call
my %failcases = (
    qq{incpath => '.',  header => 'headerfile.h'} => "Can't link/include",
    qq{INC => '-t/inc', header => 'headerfile.h'} => "INC argument badly-formed"
);
my @passcases = (
    qq{incpath => '.',         header => 't/inc/headerfile.h'},
    qq{incpath => [qw(t/inc)], header => 'headerfile.h'},
    qq{INC => '-I. -It/inc',   header => 'headerfile.h'}
);

plan tests => scalar(keys %failcases) + scalar(@passcases);

for my $c (keys %failcases) {
    capture(
        sub { eval "assert_lib(debug => $debug, $c)"; },
        \$stdout,
        \$stderr
    );
    ok($@ =~ /^$failcases{$c}/, "$c") ||
        diag("$@\n\tSTDOUT: $stdout\n\tSTDERR: $stderr\n");
}
for my $c ( @passcases ) {
    capture(
        sub { eval "assert_lib(debug => $debug, $c)"; },
        \$stdout,
        \$stderr
    );
    is($@, q{}, "$c") || diag("\tSTDOUT: $stdout\n\tSTDERR: $stderr\n");
}
