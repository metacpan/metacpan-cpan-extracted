use strict;
use warnings;
use utf8;

use Test::More;

use Log::Fmt;
use Log::Fmt::XS;

unless ($^O eq 'linux') {
    plan skip_all => 'test relies on Linux /proc';
}

plan tests => 1;

sub get_rss {
    open my $fh, '<', "/proc/$$/status" or die "Can't open /proc/$$/status: $!";
    while (<$fh>) {
        if (/^VmRSS:\s+(\d+)\s+kB/) {
            close $fh;
            return $1 * 1024;
        }
    }
    close $fh;
    die "VmRSS not found in /proc/$$/status";
}

# Build an input that exercises all code paths
my $coderef = sub { "lazy_value" };
my $nested_hash = { alpha => 1, beta => "hello world" };
my $nested_array = [ 'done', 'in-progress', 'pending' ];
my $refref = \{ json => "data" };
my $recursive = {};
$recursive->{self} = $recursive;

my @input = (
    bare       => 'simple',
    number     => 42,
    quoted     => 'has spaces',
    equals     => '0=1',
    backslash  => 'foo\\bar',
    dquote     => 'say "hi"',
    tab        => "\there",
    newline    => "line1\nline2",
    cr         => "a\rb",
    utf8       => "J\x{fc}rgen",
    zwj        => "a\x{200D}b",
    linesep    => "x\x{2028}y",
    empty_val  => '',
    ''         => 'empty_key',
    'bad key'  => 'sanitized',
    undef_val  => undef,
    lazy       => $coderef,
    hash       => $nested_hash,
    array      => $nested_array,
    flogged    => $refref,
    recurse    => $recursive,
);

# Warmup: one iteration to let Perl settle its arenas
my $result = Log::Fmt->_pairs_to_kvstr_aref(\@input);
undef $result;

my $before = get_rss();

for (1 .. 100_000) {
    my $r = Log::Fmt->_pairs_to_kvstr_aref(\@input);
}

my $after = get_rss();
my $growth = $after - $before;

# Allow up to 128 KB of growth for noise (arena rounding, etc.)
my $max_growth = 128 * 1024;

cmp_ok($growth, '<=', $max_growth,
    sprintf("memory growth after 100k iterations: %d bytes (limit %d)",
            $growth, $max_growth));

if ($growth > $max_growth) {
    diag sprintf("before: %d bytes, after: %d bytes, growth: %d bytes",
                 $before, $after, $growth);
}
