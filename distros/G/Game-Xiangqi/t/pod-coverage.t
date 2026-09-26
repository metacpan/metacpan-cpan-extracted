#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# THE STOCK all_pod_coverage_ok() IS NOT USED HERE, and the reason is a decision
# rather than an evasion.
#
# Five of the six modules are what somebody installing this from CPAN actually
# calls, and every method of all five is documented: `Game::Xiangqi`,
# `::Bot`, `::Error`, `::Notation` and `::Terminal` are checked at 100% below and
# fail if a new method arrives without an entry.
#
# `Game::Xiangqi::Engine` is exempt, with its reason: it is a THIN PERL SKIN OVER
# THE C ABI, sixty-odd one-line methods that each forward to one function in
# include/xq_abi.h, and that header is where the contract for each of them actually
# lives. The module's POD documents the things a Perl caller can get wrong, which
# are the ones no per-method list would tell them: that a point is opaque, that the
# key is a string because a 64-bit number is not portable, that the search is
# bounded in nodes, and what the four evaluation terms are for. Sixty stub entries
# reading "=head2 rank_of / The rank of a point." would satisfy this test and tell
# a reader nothing, and the test would then be measuring the stubs.
#
# It is NOT exempt from having POD at all: t/pod.t checks that separately, and the
# assertion below pins the exemption to one named module so a seventh module cannot
# join it by accident.

my @PUBLIC = qw(
    Game::Xiangqi
    Game::Xiangqi::Bot
    Game::Xiangqi::Error
    Game::Xiangqi::Notation
    Game::Xiangqi::Terminal
);

my @EXEMPT = qw( Game::Xiangqi::Engine );

# THE FOUR NAMES OBJECT::PROTO INSTALLS ARE EXEMPT, and nothing else is. `new`,
# `prototype`, `set_prototype` and the `BUILD`/`DEMOLISH` pair are Object::Proto's
# own, not this distribution's, and documenting them here would be documenting
# somebody else's module. Every attribute declared with `has` is ours and is
# checked: an accessor added without an entry in the POD fails this test.
my $GENERATED = qr/\A(?:new|prototype|set_prototype|BUILD|DEMOLISH)\z/;

for my $module (@PUBLIC) {
    pod_coverage_ok($module, { also_private => [$GENERATED] },
                    "$module documents every method it offers");
}

# The exemption is asserted rather than assumed: if somebody documents Engine.pm
# method by method after all, this fails and the exemption gets deleted, which is
# the right outcome. And a module in neither list is a module nobody decided about.
subtest 'the exemption is exactly one named module, and it is still needed' => sub {
    my $pc = Pod::Coverage->new(package => $EXEMPT[0]);
    my @naked = $pc->naked;
    cmp_ok(scalar @naked, '>', 20,
           "$EXEMPT[0] is still the thin ABI skin it was exempted for ("
           . scalar(@naked) . ' undocumented methods)');

    my %known = map { $_ => 1 } @PUBLIC, @EXEMPT;
    my @found;
    for my $path (glob 'lib/Game/Xiangqi.pm lib/Game/Xiangqi/*.pm') {
        my $m = $path;
        $m =~ s{\Alib/}{}; $m =~ s{\.pm\z}{}; $m =~ s{/}{::}g;
        push @found, $m;
    }
    my @undecided = grep { !$known{$_} } @found;
    is_deeply(\@undecided, [],
              'every module is either checked or named in the exemption')
        or diag('  undecided: ' . join ', ', @undecided);
};

done_testing();
