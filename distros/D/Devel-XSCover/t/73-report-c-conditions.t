use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Cwd ();
use File::Spec ();
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover::Gcov ();
use Devel::XSCover::DB ();

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
plan skip_all => 'no cover script found' unless XSCoverTest::cover_script();

my $dir = 't/fixtures/gcc14';
my $f = File::Spec->catfile(qw(t fixtures gcov gcc conditions.gcov.txt));
open my $fh, '<', $f or die "$f: $!";
my $text = do { local $/; <$fh> };
close $fh;
my $reader = Devel::XSCover::Gcov->new(dir => $dir, silent => 1);
my ($kept) = $reader->filter($reader->parse($text));
my $tmp = File::Temp->newdir;
my $db  = Cwd::abs_path("$tmp");
my $writer = Devel::XSCover::DB->new(dir => $dir, silent => 1, db => $db);
$writer->write($writer->entries($writer->merge({ object => 'cond.gcda', files => $kept, generated => {} })));
XSCoverTest::run_report($db, $dir);

open $fh, '<', File::Spec->catfile($db, 'cond-c.html') or die "no page";
my $page = do { local $/; <$fh> };
close $fh;
like($page, qr/<th class="cd">cond<\/th>/, 'a C file with conditions has the column');
my ($l3) = $page =~ /(<tr id="L3".*?<\/tr>\n<tr class="why">.*?<\/tr>)/s;
ok($l3, 'line 3 is marked');
is(scalar(() = $l3 =~ /<details class="cond">/g), 3, 'three terms, each with its table');
like($l3, qr/title="term 1 of if \(a &amp;&amp; \(b \|\| c\)\)"/, 'named by term');
like($l3, qr/<li>term 1 of the condition if \(a &amp;&amp; \(b \|\| c\)\) never decided the result with its false outcome<\/li>/, 'term 1 in words');
like($l3, qr/<li>term 3 of the condition .*? never decided the result with its true or false outcome<\/li>/, 'term 3, neither outcome, in words');
like($page, qr/a condition \(gcc 14 and later\) shows, for each term of a decision/, 'the legend in the C wording');
open $fh, '<', File::Spec->catfile($db, 'coverage.html') or die;
my $summary = do { local $/; <$fh> };
like($summary, qr/<td class="pc c\d cd" data-v="\d+\.\d" title="conditions: \d+ of \d+">/, 'the summary has a condition cell for the C file');

done_testing;
