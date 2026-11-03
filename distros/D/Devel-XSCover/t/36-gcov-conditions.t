use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Gcov ();

my $f = File::Spec->catfile(qw(t fixtures gcov gcc conditions.gcov.txt));
open my $fh, '<', $f or die "$f: $!";
my $text = do { local $/; <$fh> };
close $fh;

my $files = Devel::XSCover::Gcov->new(silent => 1)->parse($text);
my $c = $files->{'cond.c'};
is(scalar @{ $c->{blocks} }, 4, 'the blocks are read as before');
is(scalar @{ $c->{conditions} }, 2, 'two decisions');
is_deeply($c->{conditions}[0], {
    line => 3, covered => 3, total => 6,
    terms => [ { true => 1, false => 0 }, { true => 0, false => 1 }, { true => 0, false => 0 } ],
}, 'a && (b || c): three terms, each outcome as gcov reported it, (true false) read as both');
is_deeply($c->{conditions}[1], { line => 5, covered => 2, total => 2, terms => [ { true => 1, false => 1 } ] }, 'a fully covered one-term decision');

my $dir = File::Temp->newdir;
my $out = '';
{
    open my $o, '>', \$out or die;
    my $old = select $o;
    Devel::XSCover::Gcov->new(dir => "$dir", dry => 1, gcov => ['gcov-14'], conditions => 1)->run_gcov('cond.gcda');
    select $old;
}
is($out, "xs_cover: running gcov-14 -abct --conditions -o cond.gcda cond\n", 'gcov is asked for conditions');

done_testing;
