#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin ();

# A second extension, written as a stranger would write one, that knows HAMT
# only through the header ExtUtils::Depends points it at: built here, loaded
# beside HAMT, and made to do real work through the table. It is a separate
# compilation, so it is also what proves the header and the table agree
# about where every entry is.

plan skip_all => 'Author tests not required for installation' unless $ENV{RELEASE_TESTING};
plan skip_all => 'no compiler recorded in Config' unless $Config{cc} && $Config{make};

# Named, and resolved from where this file is, not from wherever the test was
# started or by counting directories up.
my $xt_dir       = abs_path($FindBin::Bin);
my $consumer_src = File::Spec->catdir($xt_dir, 'abi-consumer');
my $dist_root    = abs_path(File::Spec->catdir($xt_dir, File::Spec->updir));
my $blib_arch    = File::Spec->catdir($dist_root, 'blib', 'arch');
my $blib_lib     = File::Spec->catdir($dist_root, 'blib', 'lib');

plan skip_all => "no consumer source at $consumer_src" unless -f File::Spec->catfile($consumer_src, 'Consumer.xs');
plan skip_all => 'HAMT is not built: run make first'
    unless -f File::Spec->catfile($blib_arch, 'HAMT', 'Install', 'Files.pm');

my $build = tempdir(CLEANUP => 1);
make_path(File::Spec->catdir($build, 'lib', 'HAMT', 'ABI'));
copy(File::Spec->catfile($consumer_src, $_), File::Spec->catfile($build, $_)) or die "copy $_: $!"
    for 'Makefile.PL', 'Consumer.xs';
copy(File::Spec->catfile($consumer_src, 'lib', 'HAMT', 'ABI', 'Consumer.pm'),
     File::Spec->catfile($build, 'lib', 'HAMT', 'ABI', 'Consumer.pm')) or die "copy: $!";

# The consumer sees HAMT as an installed module would be seen: through @INC.
local $ENV{PERL5LIB} = join $Config{path_sep}, $blib_arch, $blib_lib, grep { defined && length } $ENV{PERL5LIB};

my $log = `cd "$build" && "$^X" Makefile.PL 2>&1 && "$Config{make}" 2>&1`;
is($?, 0, 'a consumer that knows only hamt_abi.h configures and builds') or do {
    diag($log);
    done_testing;
    exit;
};
unlike($log, qr/warning:/, 'without a compiler warning') or diag($log);

unshift @INC, File::Spec->catdir($build, 'blib', 'arch'), File::Spec->catdir($build, 'blib', 'lib');
require HAMT::Map;
require HAMT::Set;
require HAMT::Vector;
ok(eval { require HAMT::ABI::Consumer; 1 }, 'and loads beside HAMT') or do { diag($@); done_testing; exit };

my $C = 'HAMT::ABI::Consumer';
my $blocks = HAMT::_live_blocks();

is($C->can('abi_version')->(), HAMT::_abi_version(), 'it resolved the table, at the version HAMT reports');

# ---- maps -------------------------------------------------------------------
{
    my $m = HAMT::Map->new(map { ("k$_" => $_) } 1 .. 500);
    is(HAMT::ABI::Consumer::sum_values($m), 500 * 501 / 2, 'it walks a map Perl built and sums its values');

    my $m2 = HAMT::ABI::Consumer::with_pair($m, 'extra', 'x');
    isa_ok($m2, 'HAMT::Map', 'the map it returns');
    is($m2->count, 501, 'has one more pair');
    is($m2->get('extra'), 'x', 'the one it stored');
    is($m->count, 500, 'and the map it started from is unchanged');
    is($m2->_check, 0, 'in a valid trie');

    my $latin = chr(0xe9);
    my $up = $latin; utf8::upgrade($up);
    my $m3 = HAMT::ABI::Consumer::with_pair(HAMT::Map->new($latin => 1), $up, 2);
    is($m3->count, 1, 'a key it passes as UTF-8 is the key Perl stored as bytes');
    is($m3->get($latin), 2, 'and replaces its value');

    my $t = HAMT::Map->new(seed => 1)->transient;
    is(HAMT::ABI::Consumer::fill($t, 1000), 1001, 'it fills a Perl transient in place');
    is($t->get('c999'), 999, 'and Perl sees what it stored there');
    my $p = $t->persistent;
    is($p->count, 1001, 'and so does the map the transient closes into');
    ok(!eval { HAMT::ABI::Consumer::fill($t, 1); 1 } && $@ =~ /not an open HAMT::Map::Transient/,
       'a closed transient is not offered to it');
    ok(!eval { HAMT::ABI::Consumer::fill($p, 1); 1 }, 'nor is a map, which must not be changed in place');

    my $a = HAMT::Map->new(x => 1, y => 9, only_a => 5);
    my $b = HAMT::Map->new(x => 4, y => 2, only_b => 6);
    is_deeply({ HAMT::ABI::Consumer::merge_larger($a, $b)->pairs },
              { x => 4, y => 9, only_a => 5, only_b => 6 }, 'it merges two maps with a resolver of its own');

    ok(!eval { HAMT::ABI::Consumer::sum_values(HAMT::Set->new('a')); 1 } && $@ =~ /not a HAMT::Map/,
       'a set is not a map to it either');
    ok(!eval { HAMT::ABI::Consumer::sum_values(bless \(my $n = 12345), 'HAMT::Map'); 1 },
       'and a forged map is refused');
}

# ---- sets -------------------------------------------------------------------
{
    my $s = HAMT::ABI::Consumer::set_of(qw(a b c d));
    isa_ok($s, 'HAMT::Set', 'the set it builds');
    ok($s->equals(HAMT::Set->new(qw(a b c d))), 'equals the same set built in Perl');
    my $c = HAMT::ABI::Consumer::common($s, HAMT::Set->new(qw(c d e)));
    is(join(',', sort $c->members), 'c,d', 'it intersects two sets');
    is(join(',', sort split /,/, HAMT::ABI::Consumer::members($s)), 'a,b,c,d', 'and walks one, whose entries carry no value');
}

# ---- vectors ------------------------------------------------------------------
{
    my $v = HAMT::Vector->new(1 .. 2000);
    my $r = HAMT::ABI::Consumer::reversed($v);
    isa_ok($r, 'HAMT::Vector', 'the vector it builds');
    is_deeply([ $r->list ], [ reverse 1 .. 2000 ], 'is the one it was given, reversed');
    is($r->_check, 0, 'in a valid tree');

    my $rot = HAMT::ABI::Consumer::rotate($v, 500, 300);
    is_deeply([ $rot->list ], [ 1 .. 500, 801 .. 2000, 501 .. 800 ], 'it slices, removes and joins');
    is($rot->_check, 0, 'into a valid tree');
    is($v->count, 2000, 'leaving the vector it started from alone');
    ok(!eval { HAMT::ABI::Consumer::rotate($v, 1900, 300); 1 } && $@ =~ /slice failed with -2/,
       'and is told when a slice does not fit, by the documented code');
}

is(HAMT::_live_blocks(), $blocks, 'when everything it made is gone, nothing is left allocated');

done_testing;
