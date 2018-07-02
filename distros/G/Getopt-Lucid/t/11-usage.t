use strict;
use Test::More;
use Data::Dumper;
use Exception::Class::TryCatch;
use File::Basename;

use Getopt::Lucid ':all';
use Getopt::Lucid::Exception;

# Work around win32 console buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

#--------------------------------------------------------------------------#
# Test cases
#--------------------------------------------------------------------------#

my $prog = basename($0);

my $spec = [
    Counter("--verbose|v")->doc("turn on verbose output")->default(2),
    Switch("--test")->doc("run in test mode"),
    Param("--input")->default("test.txt"),
    Switch("-r")->doc("recursive"),
    Param("bare"),
    List("libs")->default(qw/one two/),
    Keypair("define")->default( isize => 4, arch => "i386" ),
];

my @expectations = (
    qr/^Usage: \Q$prog\E \[-rv] \[long options] \[arguments]$/,
    qr/^\s+--bare\s*$/,
    qr/^\s+--define\s+\(default: arch=i386, isize=4\)$/,
    qr/^\s+--input\s+\(default: test\.txt\)$/,
    qr/^\s+--libs\s+\(default: one, two\)$/,
    qr/^\s+-r\s+recursive$/,
    qr/^\s+--test\s+run in test mode$/,
    qr/^\s+-v, --verbose\s+turn on verbose output \(default: 2\)$/,
);

plan tests => 2 + @expectations;

my $gl;
try eval { $gl = Getopt::Lucid->new($spec) };
catch my $err;
is( $err, undef, "spec should validate" );

my $usage = $gl->usage;
my @lines = split /\n/, $usage;

is( scalar @lines, scalar @expectations, "got right line count" ) or diag $usage;

for my $i (0 .. $#expectations) {
    like( $lines[$i], $expectations[$i], "line $i" );
}
