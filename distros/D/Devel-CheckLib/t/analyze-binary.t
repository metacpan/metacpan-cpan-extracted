use strict;
# compatible use warnings
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }

use lib 't/lib';
use Capture::Tiny qw(capture);
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

sub analyze_binary {
    my ($lib, $bin, $expected_rc, @args) = @_;
    $bin = File::Spec->rel2abs($bin);
    system $bin, @args;
    warn "\$?: $?, expected: ".($expected_rc << 8)."\n";
    return ($? == ($expected_rc << 8));
}

my %common = ( debug => $debug,
               incpath => 't/inc',
               libpath => $libdir,
               lib => 'bazbam',
               header => 'headerfile.h',
               function => 'return (argc - 1);',
             );

my $error;
($stdout, $stderr) = capture {
    eval { assert_lib(%common,
                            analyze_binary => sub { analyze_binary @_, 3, qw(foo  bar doz) } ) };
    $error = $@;
};
is($error, '', "analyze_binary ok") or diagout;

($stdout, $stderr) = capture {
    eval { assert_lib(%common,
                            analyze_binary => sub { analyze_binary @_, 3, qw(foo) } ) };
    $error = $@;
};
like($error, qr/wrong analysis/i, "analyze_binary wrong") or diagout;

done_testing;
