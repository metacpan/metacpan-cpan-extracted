use 5.020;
use strict;
use warnings;
use Test::More;
use Cwd ();
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Gcov ();
use Devel::XSCover::DB ();

my $dir = 't/fixtures/gcc14';
my $f = File::Spec->catfile(qw(t fixtures gcov gcc conditions.gcov.txt));
open my $fh, '<', $f or die "$f: $!";
my $text = do { local $/; <$fh> };
close $fh;
my $reader = Devel::XSCover::Gcov->new(dir => $dir, silent => 1);
my ($kept) = $reader->filter($reader->parse($text));
my $writer = Devel::XSCover::DB->new(dir => $dir, silent => 1, db => 'unused');
my ($files) = $writer->merge({ object => 'cond.gcda', files => $kept, generated => {} });
my $entries = $writer->entries($files, {});
my $cond = $entries->{'cond.c'}{condition};
is(scalar @$cond, 4, 'three terms on line 3 and one on line 5');
is_deeply($cond->[0], [3, { type => 'and_2', left => 'term 1', op => 'of', right => 'if (a && (b || c))' }, [1, 0]], 'term 1: true outcome decided, false never');
is_deeply($cond->[2][2], [0, 0], 'term 3: neither outcome');
is_deeply($cond->[3], [5, { type => 'and_2', left => 'term 1', op => 'of', right => 'return a > 0 ? 2 : 3;' }, [1, 1]], 'the one-term decision, both');

my ($a, $b) = map { { object => $_, files => { 'cond.c' => { lines => {}, functions => [], blocks => [], conditions => [ { line => 3, covered => 3, total => 6, terms => [ { true => 1, false => 0 }, { true => 0, false => 1 }, { true => 0, false => 0 } ] } ] } }, generated => {} } } qw(a.gcda b.gcda);
$b->{files}{'cond.c'}{conditions}[0]{terms} = [ { true => 0, false => 1 }, { true => 1, false => 0 }, { true => 1, false => 0 } ];
my ($merged) = $writer->merge($a, $b);
is_deeply($merged->{'cond.c'}{conditions}[0]{terms}, [ { true => 1, false => 1 }, { true => 1, false => 1 }, { true => 1, false => 0 } ], 'two objects merge a decision by or');

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
my $tmp = File::Temp->newdir;
my $db  = Cwd::abs_path("$tmp");
$writer = Devel::XSCover::DB->new(dir => $dir, silent => 1, db => $db);
my $run = $writer->write($entries);
is($run->{condition}, 4, 'four conditions written');
my $here = Cwd::getcwd();
chdir $dir or die;
my $cover = Devel::Cover::DB->new(db => $db)->merge_runs->cover;
chdir $here;
my $loc = $cover->file('cond.c')->condition->location(3);
is(scalar @$loc, 3, 'three conditions on line 3 read back');
is_deeply([ $loc->[0]->values ], [1, 0], 'with their outcomes');
is($loc->[0]->text, 'term 1 of if (a && (b || c))', 'and the text');
ok($loc->[0]->error, 'a missing outcome is an error');
ok(!$cover->file('cond.c')->condition->location(5)->[0]->error, 'a complete one is not');

my $mdir = File::Temp->newdir;
open my $mfh, '>', File::Spec->catfile($mdir, 'mac.c') or die;
print $mfh <<'C';
int g(SV *sv, int a, int b)
{
    if (!SvOK(GvSVn(gv)))
        return 1;
    sv_setiv(GvSVn(gv), 0);
    if (a
        && b)
        return 2;
    return a ? 3 : 4;
}
C
close $mfh;
my $term = sub { { true => 1, false => 0 } };
my $mac = { 'mac.c' => { lines => {}, functions => [], blocks => [], conditions => [
    { line => 3, covered => 1, total => 6, terms => [ $term->(), $term->(), $term->() ] },
    { line => 5, covered => 1, total => 2, terms => [ $term->() ] },
    { line => 6, covered => 2, total => 4, terms => [ $term->(), $term->() ] },
    { line => 9, covered => 1, total => 2, terms => [ $term->() ] },
] } };
my $mw = Devel::XSCover::DB->new(dir => "$mdir", silent => 1, db => 'unused');
is_deeply([ map { $_->[0] } @{ $mw->entries($mac, {})->{'mac.c'}{condition} } ], [6, 6, 9],
    'kept: the two-line && and the ?:, whose terms are all in the source; dropped: the if with a macro inside (three terms for one) and the macro line');
is(scalar @{ Devel::XSCover::DB->new(dir => "$mdir", silent => 1, db => 'unused', macro_branches => 1)->entries($mac, {})->{'mac.c'}{condition} }, 7, 'macro_branches keeps every term');

done_testing;
