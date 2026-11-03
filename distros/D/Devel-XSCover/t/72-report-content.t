use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Spec ();
use XSCoverTest ();

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
plan skip_all => 'no cover script found' unless XSCoverTest::cover_script();

my ($tmp, $db, $dir, $perl_tmp, $perl) = XSCoverTest::report_db();
XSCoverTest::run_report($db, $dir);
sub page { my $f = File::Spec->catfile($db, shift); open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }

my $summary = page('coverage.html');
like($summary, qr/<h1>Coverage summary<\/h1>/, 'the title');
like($summary, qr/<div class="tile c\d"><span class="name">statements<\/span>/, 'a tile per criterion');
like($summary, qr/<th data-sort="num" class="st">stmt<\/th>/, 'sortable columns');
for my $f ('Spike.xs', 'include/spike.h', 'src/helper.c', 'xs/more.xs') {
    (my $p = $f) =~ s/\W/-/g;
    like($summary, qr/<a href="$p\.html">\Q$f\E<\/a>/, "$f is linked");
}
like($summary, qr/<td class="pc c\d st" data-v="88\.4" title="statements: 23 of 26"><meter min="0" max="100" value="88\.4"><\/meter><span>88\.4<\/span><\/td>/, 'the Spike.xs statement cell with its bar and ratio');
like($summary, qr/lib\/Spike\.pm<\/a> <a class="xs" href="Spike-xs\.html"/, 'the .pm row links to its .xs');
like($summary, qr/<tfoot><tr><td class="f">Total<\/td>/, 'the total row');
like($summary, qr/class="pc na cd" data-v="-1">n\/a</, 'n/a for a criterion a file has not got');
like($summary, qr/<input id="filter" type="search"/, 'the filter box');

my $xs = page('Spike-xs.html');
like($xs, qr/<h1>Spike\.xs<\/h1>/, 'the file page title');
like($xs, qr/<label><input type="checkbox" data-crit="st" checked> statements<\/label>/, 'a toggle per criterion shown');
my ($switch) = $xs =~ /(<tr id="L47".*?<\/tr>)/s;
ok($switch, 'the switch line');
is(scalar(() = $switch =~ /<span class="branch arm"/g), 5, 'five arm chips on it, one per arm');
like($switch, qr/<b class="c3">1 1<\/b>/, 'the first arm with its count');
like($switch, qr/<b class="c0">4 0<\/b>/, 'the fourth arm never taken, marked');
my ($why47) = $xs =~ /<tr id="L47".*?<\/tr>\n(<tr class="why">.*?<\/tr>)/s;
like($why47, qr/<li>arm 4 of the 5-way jump was never taken<\/li>/, 'and the row under it says so in words');
like($switch, qr/^<tr id="L47" class="miss">/, 'the line is marked as not fully covered');
my ($add) = $xs =~ /(<tr id="L20".*?<\/tr>)/s;
like($add, qr/<span class="sub c3" title="Spike::add: called 353062">Spike::add<\/span><span class="sub c3" title="Spike::plus: called 353062">Spike::plus<\/span>/, 'both names on the declaration line');
my ($guard) = $xs =~ /(<tr id="L95".*?<\/tr>)/s;
like($guard, qr/<b class="un">A 1<\/b><b class="c0">B 0<\/b>/, 'C arms are A and B with their counts, the uncoverable one in its own colour');
my ($why95) = $xs =~ /<tr id="L95".*?<\/tr>\n(<tr class="why">.*?<\/tr>)/s;
like($why95, qr/arm B of the branch if \(!p\) .* was never taken, arm A taken 1/, 'the words for a C branch');
like($xs, qr/<details class="legend"><summary>What the marks mean<\/summary>/, 'the legend');
like($xs, qr/A and B in the order the compiler laid them out/, 'which for a C file explains A and B');
my ($helper) = $xs =~ /(<tr id="L8".*?<\/tr>)/s;
like($helper, qr/<span class="sub c3" title="only_from_one: called 2">only_from_one<\/span>/, 'the C helper under its name');
like($xs, qr/<td class="st"><span class="c3" title="statements: 353062">353062<\/span><\/td>/, 'a statement count');
unlike($xs, qr/class="cd"/, 'no condition column for a C file');

my ($pm_page) = do { opendir my $dh, $db or die; grep { /Spike-pm\.html$/ } readdir $dh };
my $pm = page($pm_page);
like($pm, qr/<details class="cond"><summary class="c\d" title="\$a and \$b">\d+%<\/summary><table/, 'a condition opens into its truth table');
like($pm, qr/<span class="sub c0" title="unused: called 0">unused<\/span>/, 'the never-called sub is marked');
like($pm, qr/<tr id="L\d+" class="dim"><td class="n">\d+<\/td>.*?<pre>=head1 NAME<\/pre>/, 'pod is dimmed');
like($pm, qr/<b class="c3">T \d+<\/b><b class="c3">F \d+<\/b>/, 'a Perl branch as T and F with counts');
like($pm, qr/<li>Spike::unused was never called<\/li>|<li>unused was never called<\/li>/, 'the never-called sub in words');
like($pm, qr/<li>this line never ran<\/li>/, 'a never-run line in words');
like($pm, qr/the true branch never taken|the false branch never taken/, 'a Perl branch in words');
like($pm, qr/<th class="tm">time<\/th>/, 'the time column for Perl');

done_testing;
