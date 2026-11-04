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

sub pages { opendir my $dh, $db or die "$db: $!"; return sort grep { /\.html\z/ } readdir $dh }
sub page { my $f = File::Spec->catfile($db, shift); open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }

my $out = XSCoverTest::run_cover($db, $dir, '-nogcov', '-silent', '-report', 'XSCover', '-nosuchoption');
like($out, qr/Unknown option: nosuchoption/, 'an option the report does not know is named');
like($out, qr/Invalid command line options/, 'and the run stops');
is_deeply([pages()], [], 'with no page written');

$out = XSCoverTest::run_cover($db, $dir, '-nogcov', '-silent', '-report', 'XSCover', '-outputfile', 'index.html', '-summarytitle', 'Spike', '-report_c0', '50', '-report_c1', '80');
unlike($out, qr/^done\.$/m, 'a silent run does not say done');
is_deeply([grep { /^(?:index|coverage)\.html$/ } pages()], ['index.html'], 'the summary page takes its name from -outputfile');
my $summary = page('index.html');
like($summary, qr/<title>Spike<\/title>/, 'and its title from -summarytitle');
like($summary, qr/<h1>Spike<\/h1>/, 'as its heading');
like($summary, qr/<td class="pc c2 st" data-v="88\.0" title="statements: 22 of 25">/, 'with -report_c1 80 the 88.0% cell is the colour between c1 and c2');
like($summary, qr/<div class="tile c2"><span class="name">statements<\/span><span class="value">85\.7%<\/span><span class="ratio">48 of 56<\/span>/, 'and so is the statements tile at 86.2%');
like($summary, qr/<td class="pc c3 st" data-v="100\.0" title="statements: 6 of 6">/, 'a full cell is still green');
like(page('Spike-xs.html'), qr/<p class="crumb"><a href="index\.html">summary<\/a>/, 'the file pages link back to the renamed summary');

XSCoverTest::run_cover($db, $dir, '-nogcov', '-silent', '-report', 'XSCover', '-report_c0', '50', '-report_c1', '70', '-report_c2', '80');
$summary = page('coverage.html');
like($summary, qr/<td class="pc c3 st" data-v="88\.0" title="statements: 22 of 25">/, 'with -report_c2 80 the 88.0% cell is green although something is missing');
like($summary, qr/<div class="tile c3"><span class="name">statements<\/span><span class="value">85\.7%<\/span>/, 'and so is the statements tile');

$out = XSCoverTest::run_cover($db, $dir, '-nogcov', '-report', 'XSCover');
like($out, qr/^File\s+stmt\s+bran\s+cond\s+sub/m, 'a run that is not silent prints the summary table of cover');
like($out, qr/\ndone\.\n\z/, 'and ends with done');

$out = XSCoverTest::run_cover($db, $dir, '-nogcov', '-silent', '-report', 'XSCover', '-coverage', 'branch');
like($out, qr/^File\s+bran\s+total$/m, 'a run restricted to branches shows that in the table of cover too');
$summary = page('coverage.html');
like($summary, qr/<thead><tr><th data-sort="text">file<\/th><th data-sort="num" class="br">bran<\/th><th data-sort="num">total<\/th><\/tr><\/thead>/, 'the summary has the branch column and the total only');
like($summary, qr/<section class="tiles">\n<div class="tile c\d"><span class="name">branches<\/span>.*?<\/div>\n<div class="tile c\d"><span class="name">total<\/span>/s, 'and two tiles');
my $xs = page('Spike-xs.html');
like($xs, qr/<nav class="toggles"><label><input type="checkbox" data-crit="br" checked> branches<\/label> <span class="hint">/, 'a file page has the branch toggle alone');
like($xs, qr/<thead><tr><th class="n">line<\/th><th class="br">bran<\/th><th class="code">code<\/th><\/tr><\/thead>/, 'and the branch column alone');
unlike($xs, qr/a green count is a line that ran/, 'the legend says nothing about statement counts');
like($xs, qr/<li>a branch shows its arms with the times each was taken/, 'and still explains the branch chips');

done_testing;
