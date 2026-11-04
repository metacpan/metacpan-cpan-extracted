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
int f(int a, int b)
{
    if (g(a,
          b))
        return 1;
    return a;
}
int h(int x) { return x; } int k(int x) { return x; }
int m(int x)
{
    if (x) {
        return 1;
    }
    else {
        return 2;
    }
}
C
close $fh;
my $writer = Devel::XSCover::DB->new(dir => "$dir", silent => 1);
my $term = sub { { true => 1, false => 1 } };

my ($files, $generated) = $writer->merge(
    { object => 'helper.gcda', files => { 'm.c' => { lines => { 3 => 1 }, functions => [], blocks => [] } } },
    { object => 'M.gcda', generated => { 'M.c' => { lines => {}, functions => [ { name => 'XS_M_f', line => 3, count => 1 } ], blocks => [] } } },
);
is_deeply([ sort keys %$files ], ['m.c'], 'an object with no generated files adds its source files');
is_deeply([ sort keys %$generated ], ['M.c'], 'and one with no source files adds its generated file');

($files) = $writer->merge(
    { object => 'a.gcda', files => { 'm.c' => { lines => {}, functions => [], blocks => [ { line => 3, arms => [1, 2] } ], conditions => [ { line => 3, covered => 2, total => 4, terms => [ $term->(), $term->() ] } ] } } },
    { object => 'b.gcda', files => { 'm.c' => { lines => {}, functions => [], blocks => [ { line => 3, arms => [1, 2, 3] } ], conditions => [ { line => 3, covered => 1, total => 2, terms => [ $term->() ] } ] } } },
);
is_deeply($files->{'m.c'}{blocks}, [ { line => 3, arms => [1, 2] }, { line => 3, arms => [1, 2, 3] } ], 'a block on the same line with another arm count is another block');
is_deeply([ map { scalar @{ $_->{terms} } } @{ $files->{'m.c'}{conditions} } ], [2, 1], 'a decision on the same line with another term count is another decision');

($files) = $writer->merge({ object => 'a.gcda', files => { 'm.c' => {
    lines      => { 3 => 5, 8 => 3 },
    functions  => [ { name => 'k', line => 8, count => 1 }, { name => 'h', line => 8, count => 2 } ],
    blocks     => [ { line => 3, arms => [5] } ],
    conditions => [ { line => 3, covered => 2, total => 2, terms => [ $term->() ] } ],
} } });
my $e = $writer->entries($files, {})->{'m.c'};
is_deeply($e->{branch}, [], 'a block with a single arm is no branch');
is_deeply($e->{condition}, [ [3, { type => 'and_2', left => 'term 1', op => 'of', right => 'if (g(a,' }, [1, 1]] ],
    'a decision whose parentheses span two lines with no && or || is one term, and is kept');
is_deeply($e->{subroutine}, [ [8, 'h', 2], [8, 'k', 1] ], 'two functions on one line are ordered by name');

my $map = { c => 'M.c', xsubs => {
    XS_M_f       => { file => 'm.c', line => 1, names => ['M::f'] },
    XS_M_no_line => { file => 'm.c', line => undef, names => ['M::no_line'] },
    XS_M_no_name => { file => 'm.c', line => 8, names => [] },
} };
is_deeply($writer->entries({}, {}, $map)->{'m.c'}{subroutine}, [ [1, 'M::f', 0] ],
    'a map whose generated c no object reported keeps every XSUB uncalled, and one without a declaration line or a Perl name is no subroutine');

my $gone = { 'gone.c' => {
    lines      => { 3 => 1 },
    functions  => [],
    blocks     => [ { line => 3, arms => [1, 0] } ],
    conditions => [ { line => 3, covered => 1, total => 2, terms => [ { true => 1, false => 0 } ] } ],
} };
($files) = $writer->merge({ object => 'a.gcda', files => { 'm.c' => { lines => { 11 => 1, 12 => 1, 13 => 0, 14 => 1, 15 => 1, 16 => 0, 17 => 1 }, functions => [], blocks => [] } } });
is_deeply($writer->entries($files, {})->{'m.c'}{statement}, [[11, 1], [12, 1], [14, 1], [15, 1]],
    'a line of nothing but braces, or braces and else, is no statement, whatever count clang gave it');

$e = $writer->entries($gone, {})->{'gone.c'};
is_deeply($e->{statement}, [[3, 1]], 'a file whose source is not under dir keeps its statements');
is_deeply($e->{branch}, [], 'but its blocks give no branches, since no text can show a decision');
is_deeply($e->{condition}, [], 'and no conditions');
$gone->{'gone.c'}{decisions} = [ { line => 3, arms => [1, 0] } ];
is_deeply($writer->entries($gone, {})->{'gone.c'}{branch}, [ [3, '', [1, 0]] ], 'a decision the flow graph found keeps its arms, with an empty text');

done_testing;
