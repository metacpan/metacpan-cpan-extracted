use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use File::Temp ();
use Devel::XSCover::DB ();

my $dir = File::Temp->newdir;
open my $fh, '>', File::Spec->catfile($dir, 'm.c') or die;
print $fh <<'C';
int f(int x)
{
    if (!SvOK(GvSVn(gv)))
        return 1;
    switch (x) {
    case 1: return 1;
    default: return 2;
    }
}
C
close $fh;

my $with = { object => 'a.gcda', files => { 'm.c' => {
    lines     => { 3 => 40, 4 => 1, 5 => 39 },
    functions => [],
    blocks    => [ { line => 3, arms => [39, 1] }, { line => 3, arms => [40, 0] }, { line => 5, arms => [30, 9] } ],
    decisions => [ { line => 3, arms => [1, 39] }, { line => 5, arms => [30, 9] } ],
} }, generated => {} };
my $more = { object => 'b.gcda', files => { 'm.c' => {
    lines     => { 3 => 2, 4 => 0, 5 => 2 },
    functions => [],
    blocks    => [ { line => 3, arms => [2, 0] }, { line => 3, arms => [2, 0] }, { line => 5, arms => [2, 0] } ],
    decisions => [ { line => 3, arms => [0, 2] }, { line => 5, arms => [2, 0, 0] } ],
} }, generated => {} };
my $without = { object => 'c.gcda', files => { 'm.c' => {
    lines     => { 3 => 40, 4 => 1, 5 => 39 },
    functions => [],
    blocks    => [ { line => 3, arms => [39, 1] }, { line => 3, arms => [40, 0] }, { line => 5, arms => [30, 9] } ],
} }, generated => {} };

my $writer = Devel::XSCover::DB->new(dir => "$dir", silent => 1);
my ($files) = $writer->merge($with, $more);
is_deeply($files->{'m.c'}{decisions}, [ { line => 3, arms => [1, 41] }, { line => 5, arms => [30, 9] }, { line => 5, arms => [2, 0, 0] } ],
    'decisions merge by line and arm count, summed, a different arm count kept apart');
is_deeply($with->{files}{'m.c'}{decisions}, [ { line => 3, arms => [1, 39] }, { line => 5, arms => [30, 9] } ], 'the input untouched');

my $e = $writer->entries($files, {});
is_deeply($e->{'m.c'}{branch}, [
    [3, 'if (!SvOK(GvSVn(gv)))', [1, 41]],
    [5, 'switch (x) {', [30, 9]],
    [5, 'arm 1 of 3', [2, 0]],
    [5, 'arm 2 of 3', [0, 2]],
    [5, 'arm 3 of 3', [0, 2]],
], 'the branches come from the decisions: the macro block is gone, two arms get the text, more get arm k of N');

($files) = $writer->merge($without);
ok(!exists $files->{'m.c'}{decisions}, 'an object without a flow graph has no decisions');
is_deeply([ map { [ $_->[0], $_->[2] ] } @{ $writer->entries($files, {})->{'m.c'}{branch} } ], [ [3, [39, 1]], [3, [40, 0]], [5, [30, 9]] ],
    'and its branches come from the blocks, every block of the if line included');

($files) = $writer->merge($with);
is(scalar @{ Devel::XSCover::DB->new(dir => "$dir", silent => 1, macro_branches => 1)->entries($files, {})->{'m.c'}{branch} }, 3,
    'macro_branches takes every block even when there are decisions');

$with->{files}{'m.c'}{decisions} = [];
($files) = $writer->merge($with);
is_deeply($files->{'m.c'}{decisions}, [], 'a file the graph covered with no decision of its own keeps an empty list');
is_deeply($writer->entries($files, {})->{'m.c'}{branch}, [], 'and gets no branches from its blocks');

my $map = { c => 'm.c', xsubs => { XS_M_seen => { file => 'm.c', line => 3, names => ['M::seen'] }, XS_M_ifdef => { file => 'm.c', line => 5, names => ['M::ifdef'] } } };
my $generated = { 'm.c' => { lines => {}, blocks => [], functions => [ { name => 'XS_M_seen', line => 3, count => 2 } ] } };
is_deeply($writer->entries({}, $generated, $map)->{'m.c'}{subroutine}, [ [3, 'M::seen', 2] ], 'an XSUB the compiler never saw, under an ifdef the build left out, is not a subroutine of this build');
is_deeply($writer->entries({}, { 'm.c' => { lines => {}, blocks => [], functions => [] } }, $map)->{'m.c'}{subroutine}, [ [3, 'M::seen', 0], [5, 'M::ifdef', 0] ], 'with no function counts at all every XSUB stays, uncalled');

done_testing;
