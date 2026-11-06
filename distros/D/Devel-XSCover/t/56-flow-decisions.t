use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Flow ();

my $dir = File::Temp->newdir;
my $src = <<'C';
int f(int x, int y)
{
    if (!x || !GET(x))
        return 0;
    if (x > 1 && y) {
        x = 1;
    }
    else if (y)
        x = 2;
    if (x < 0) return -1;
    while (y > 0)
        y--;
    for (y = 0; y < 2; y++)
        x++;
    switch (x) {
    case 1: return 1;
    case 2: return 2;
    default: break;
    }
    x = y ? x : 0;
    if (x > 3
        && y < 9)
        x = 4;
    /* if (never) and
       while (not) */
    return x; /* "if (" */ // for (x)
}
#if 0
    if (dead)
#endif
#define GET(p) ((p) && *(p) ? \
    1 : 0)
    z = "if (" + 'x' + '(';
    } while (0);
    if (x) { y; }
    if (x);
    if (x) for (;;) y++;
    if (x
C
open my $fh, '>', File::Spec->catfile($dir, 'd.c') or die;
print $fh $src;
close $fh;
my @lines = split /\n/, $src;

my $flow = Devel::XSCover::Flow->new(dir => "$dir");
my @clean = $flow->clean([ map { "$_\n" } @lines ]);
like($clean[23], qr/^\s*$/, 'a block comment is blanked');
like($clean[24], qr/^\s*$/, 'to its end');
like($clean[25], qr/^\s*return x;\s*$/, 'a comment and a line comment after code are blanked');
is($clean[27], '', 'a preprocessor line is blanked');
is($clean[30], '', 'and a define');
is($clean[31], '', 'with its continuation');
is($clean[32], '    z = "" + \'\' + \'\';', 'strings and character literals are emptied');

is_deeply([ $flow->ranges([ map { "$_\n" } @lines ]) ], [
    { line => 3,  end => 3,  body => 0 },
    { line => 5,  end => 5,  body => 0 },
    { line => 8,  end => 8,  body => 0 },
    { line => 10, end => 10, body => 1 },
    { line => 11, end => 11, body => 0 },
    { line => 13, end => 13, body => 0 },
    { line => 15, end => 15, body => 0 },
    { line => 21, end => 22, body => 0 },
    { line => 29, end => 29, body => 0 },
    { line => 34, end => 34, body => 0 },
    { line => 35, end => 35, body => 1 },
    { line => 36, end => 36, body => 0 },
    { line => 37, end => 37, body => 1 },
], 'the decisions: a one-line body, a two-line condition, one under #if 0 (which has no blocks later), a do while, braces on the line, an empty body, a loop as the body, nothing in comments, strings or directives, and not a parenthesis never closed');

my %complete = (complete => 1, files => { 'd.c' => {
    3  => { blocks => { map { $_ => 1 } 1, 2, 3 }, arcs => [ [1, 2, 5], [1, 4, 0], [2, 3, 3], [2, 5, 2], [3, 4, 0], [3, 5, 3] ], count => undef },
    4  => { blocks => { 4 => 1 }, arcs => [ [4, 99, 0] ], count => undef },
    5  => { blocks => { 6 => 1, 7 => 1 }, arcs => [ [6, 7, 3], [6, 9, 2], [7, 8, 1], [7, 9, 2] ], count => undef },
    6  => { blocks => { 8 => 1 }, arcs => [ [8, 11, 1] ], count => undef },
    8  => { blocks => { 9 => 1 }, arcs => [ [9, 10, 2], [9, 11, 2] ], count => undef },
    9  => { blocks => { 10 => 1 }, arcs => [ [10, 11, 2] ], count => undef },
    10 => { blocks => { 11 => 1, 12 => 1 }, arcs => [ [11, 12, 1], [11, 13, 3], [12, 99, 1] ], count => undef },
    11 => { blocks => { 13 => 1 }, arcs => [ [13, 14, 5], [13, 15, 3] ], count => undef },
    12 => { blocks => { 14 => 1 }, arcs => [ [14, 13, 5] ], count => undef },
    13 => { blocks => { 15 => 1, 16 => 1, 17 => 1 }, arcs => [ [15, 16, 3], [16, 18, 6], [16, 19, 3], [17, 16, 6] ], count => undef },
    14 => { blocks => { 18 => 1 }, arcs => [ [18, 17, 6] ], count => undef },
    15 => { blocks => { 19 => 1 }, arcs => [ [19, 20, 1], [19, 21, 0], [19, 22, 2] ], count => undef },
    20 => { blocks => { 23 => 1, 24 => 1, 25 => 1 }, arcs => [ [23, 24, 1], [23, 25, 1], [24, 26, 1], [25, 26, 1] ], count => undef },
    21 => { blocks => { 26 => 1 }, arcs => [ [26, 27, 2], [26, 29, 1] ], count => undef },
    22 => { blocks => { 27 => 1 }, arcs => [ [27, 28, 1], [27, 29, 1] ], count => undef },
    23 => { blocks => { 28 => 1 }, arcs => [ [28, 29, 1] ], count => undef },
} });
my $expected = [
    { line => 3,  arms => [0, 5] },
    { line => 5,  arms => [1, 4] },
    { line => 8,  arms => [2, 2] },
    { line => 10, arms => [1, 3] },
    { line => 11, arms => [5, 3] },
    { line => 13, arms => [6, 3] },
    { line => 15, arms => [1, 0, 2] },
    { line => 21, arms => [1, 2] },
];
is_deeply($flow->decisions(\%complete)->{'d.c'}, $expected,
    'from a complete graph: the macro tests vanish, the body arm comes first, the loops and the switch have their arms, the ?: line has none');

my %gcc = (complete => 0, files => { 'd.c' => {} });
for my $n (keys %{ $complete{files}{'d.c'} }) {
    my $l = $complete{files}{'d.c'}{$n};
    my %out;
    push @{ $out{ $_->[0] } }, $_ for @{ $l->{arcs} };
    $gcc{files}{'d.c'}{$n} = { blocks => { %{ $l->{blocks} } }, arcs => [ map { @{ $out{$_} } } grep { @{ $out{$_} } > 1 } sort keys %out ], count => undef };
}
$gcc{files}{'d.c'}{10}{count} = 4;
is_deeply($flow->decisions(\%gcc)->{'d.c'}, $expected, 'from gcc\'s conditional arcs and line counts: the same, the one-line body by subtraction');

$gcc{files}{'d.c'}{10}{count} = 2;
is_deeply((grep { $_->{line} == 10 } @{ $flow->decisions(\%gcc)->{'d.c'} })[0]{arms}, [0, 3], 'a line count below the arms seen gives the body nothing, never a negative');
$gcc{files}{'d.c'}{10}{count} = undef;
is_deeply((grep { $_->{line} == 10 } @{ $flow->decisions(\%gcc)->{'d.c'} })[0]{arms}, [0, 3], 'and so does a line without a count');

my %spread = (complete => 1, files => { 'd.c' => {
    21 => { blocks => { 40 => 1 }, arcs => [ [40, 41, 5], [40, 43, 2] ], count => undef },
    22 => { blocks => { 40 => 1, 41 => 1 }, arcs => [ [40, 41, 5], [40, 43, 2], [41, 42, 4], [41, 43, 1] ], count => undef },
} });
is_deeply($flow->decisions(\%spread)->{'d.c'}, [ { line => 21, arms => [4, 3] } ],
    'a block on both lines of a two-line condition has its arcs counted once');

my %callers = (complete => 1, files => { 'd.c' => {
    3 => { blocks => { '1:1' => 1, '2:1' => 1 }, arcs => [ ['1:1', '1:2', 4], ['1:1', '1:3', 1], ['2:1', '2:2', 6], ['2:1', '2:3', 0] ], count => undef },
} });
is_deeply($flow->decisions(\%callers)->{'d.c'}, [ { line => 3, arms => [4, 6, 1, 0] } ],
    'an inline if with blocks from two callers lists the arms of both, the bodies first and the callers in order');

my %noreturn = (complete => 1, files => { 'd.c' => {
    35 => { blocks => { 50 => 1, 51 => 1 }, arcs => [ [50, 51, 3], [50, 52, 1] ], count => undef },
} });
is_deeply($flow->decisions(\%noreturn)->{'d.c'}, [ { line => 35, arms => [3, 1] } ],
    'a block on the line with no way out, a call that never returns, is the body arm itself');

my %loop = (complete => 1, files => { 'd.c' => {
    37 => { blocks => { 60 => 1, 61 => 1 }, arcs => [ [60, 61, 2], [60, 62, 1], [61, 61, 9] ], count => undef },
} });
is_deeply($flow->decisions(\%loop)->{'d.c'}, [ { line => 37, arms => [2, 1] } ],
    'a one-way block that loops to itself on the line, a for loop without a condition as the body, is followed once and not for ever');

my %merge = (complete => 1, files => { 'd.c' => {
    11 => { blocks => { 4 => 1, 6 => 1 }, arcs => [ [4, 5, 10], [4, 6, 2], [6, 7, 12] ], count => undef },
    12 => { blocks => { 5 => 1 }, arcs => [ [5, 6, 10] ], count => undef },
} });
is_deeply($flow->decisions(\%merge)->{'d.c'}, [ { line => 11, arms => [10, 2] } ],
    'a merge block the compiler put on the if line stands for where it goes, so the arm past the body is the arcs into it, not the flow through it');
my %chain = (complete => 1, files => { 'd.c' => {
    3 => { blocks => { map { $_ => 1 } 2, 3, 4, 5 }, arcs => [ [2, 3, 7], [2, 8, 0], [3, 4, 7], [3, 8, 0], [4, 5, 7], [5, 9, 7] ], count => undef },
    4 => { blocks => { 8 => 1 }, arcs => [ [8, 99, 0] ], count => undef },
} });
is_deeply($flow->decisions(\%chain)->{'d.c'}, [ { line => 3, arms => [0, 7] } ],
    'a chain of one-way blocks on the line, the arms of a macro, carries the flow to where the chain ends');

my %nothing = (complete => 1, files => { 'd.c' => { 40 => { blocks => { 1 => 1 }, arcs => [ [1, 2, 1], [1, 3, 1] ], count => undef } } });
is_deeply($flow->decisions(\%nothing)->{'d.c'}, [], 'blocks on lines with no decision give nothing');
is_deeply($flow->decisions({ complete => 1, files => { 'missing.c' => { 1 => { blocks => {}, arcs => [], count => undef } } } }), {}, 'a file that cannot be read is left out');

my $xs = File::Spec->catfile($dir, "m.xs");
open my $xfh, ">", $xs or die;
print $xfh "MODULE = M PACKAGE = M\n\nvoid\nf(x)\n    int x\nCODE:\n    # uncoverable branch false\n    if (x) {\n        x = 0;\n    }\n";
close $xfh;
my %claimed = (complete => 1, files => { "m.xs" => {
    7 => { blocks => { 1 => 1 }, arcs => [ [1, 2, 3], [1, 3, 0] ], count => 3 },
    8 => { blocks => { 2 => 1 }, arcs => [ [2, 3, 3] ], count => 3 },
} });
is_deeply($flow->decisions(\%claimed, { "m.xs" => { 7 => 8, 8 => 9 } })->{"m.xs"}, [ { line => 7, arms => [3, 0] } ],
    "with the XS map's table an XS source is read in the lines gcov reports, so a decision after a mark is found where the graph has it");
is_deeply($flow->decisions(\%claimed)->{"m.xs"}, [], "without it the decision is sought a line down, where the graph has nothing");
is_deeply($flow->dropped([ "MODULE = M\n", "# a\n", "#if X\n", "  # uncoverable statement\n" ]), { 2 => 1, 4 => 1 }, "dropped lists the comment lines after MODULE, not the directives");
is_deeply($flow->dropped([ "# before\n", "MODULE = M\n" ]), {}, "and nothing before MODULE");

done_testing;
