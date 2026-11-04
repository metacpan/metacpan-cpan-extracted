use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Cwd ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use XSCoverTest ();

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
plan skip_all => 'no cover script found' unless XSCoverTest::cover_script();

my $tmp = File::Temp->newdir;
my $dir = Cwd::abs_path("$tmp");
my $db  = File::Spec->catdir($dir, 'db');
File::Path::make_path(File::Spec->catdir($dir, 'lib'));
my $module = File::Spec->catfile($dir, 'lib', 'Plain.pm');

sub write_file { my ($path, $text) = @_; open my $fh, '>', $path or die "$path: $!"; print $fh $text; close $fh }
sub page { my $f = File::Spec->catfile($db, shift); open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }
sub row { my ($html, $n) = @_; my ($row) = $html =~ /(<tr id="L$n".*?<\/tr>\n(?:<tr class="why">.*?<\/tr>\n)?)/s; return $row // '' }

write_file($module, <<'PM');
package Plain;

use strict;
use warnings;

=head1 NAME

Plain - a module with no XS half

=cut

our $VERSION = '0.01';

sub twins {
    my ($a, $b, $c) = @_;
    my $m = $a && $b; my $n = $a && $b || $c;
    my $o = $a && $b; my $p = $c || $a && $b;
    my $q = $a && $b || $c; my $r = $a && $b;
    my $s = $c || $a && $b; my $t = $a && $b;
    return [$m, $n, $o, $p, $q, $r, $s, $t];
}

sub far {
    my ($first_operand_with_a_long_name, $second_operand_with_a_long_name) = @_;
    if ($first_operand_with_a_long_name > 10 && $second_operand_with_a_long_name > 10) {
        return 'both';
    }
    return 'neither';
}

sub pair { my ($p, $q) = @_; my $m = $p && $q; my $n = $p || $q; return [$m, $n] }

sub idle { my $i = 1; my $j = 2; return $i + $j }

sub never_a { 1 } sub never_b { 2 }

1;

__END__

=head1 DESCRIPTION

Branches, conditions and pod for the report to draw.

=cut
PM
write_file(File::Spec->catfile($dir, 'drive'), <<'PL');
use strict;
use warnings;
use Plain;

Plain::twins(1, 0, 1);
Plain::twins(1, 1, 0);
Plain::far(20, 20);
Plain::pair($_->[0], $_->[1]) for [0, 0], [0, 1], [1, 0], [1, 1];
PL
{
    delete local @ENV{qw(HARNESS_PERL_SWITCHES PERL5OPT)};
    my $here = Cwd::getcwd();
    chdir $dir or die "$dir: $!";
    system($^X, "-MDevel::Cover=-db,$db,-silent,1", '-Ilib', 'drive') == 0 or die "the Perl fixture failed: $?";
    chdir $here;
}

my $out = XSCoverTest::run_report($db, $dir);
unlike($out, qr/Can't|Use of uninitialized/, 'the report runs without complaint') or diag $out;
my $summary = page('coverage.html');
like($summary, qr/<td class="f"><a href="lib-Plain-pm\.html">lib\/Plain\.pm<\/a><\/td>/, 'a module without an XS file has no xs link on its row');
like($summary, qr/<td class="f"><a href="drive\.html">drive<\/a><\/td>/, 'the script has a row');

my $drive = page('drive.html');
like(row($drive, 3), qr/^<tr id="L3"><td class="n">3<\/td><td class="st"><span class="c3" title="statements: 1">1<\/span>/, 'a script without an extension is read as Perl, with its statement counts');
like($drive, qr/<li>a green count is a line that ran, a red one a line that never ran<\/li><li>a subroutine is named on its line/, 'and a legend for the marks it has');

my $pm = page('lib-Plain-pm.html');
like(row($pm, 6), qr/^<tr id="L6" class="dim"><td class="n">6<\/td>.*<pre>=head1 NAME<\/pre>/, 'pod ahead of the code is dimmed');
like(row($pm, 10), qr/^<tr id="L10" class="dim"><td class="n">10<\/td>.*<pre>=cut<\/pre>/, 'up to its =cut');
like(row($pm, 12), qr/^<tr id="L12"><td class="n">12<\/td>.*<pre>our \$VERSION = &#39;0\.01&#39;;<\/pre>/, 'and the code after it is not');
like(row($pm, 41), qr/^<tr id="L41" class="dim">.*<pre>=head1 DESCRIPTION<\/pre>/, 'pod after __END__ is dimmed too');

for my $n (16 .. 19) {
    my $line = row($pm, $n);
    is(scalar(() = $line =~ /<details class="cond">/g), 1, "line $n: a condition that is the operand of the other on its line is merged into one table");
}
like(row($pm, 16), qr/<summary class="c\d" title="\$a &amp;&amp; \$b \|\| \$c">/, 'the merged table is named for the outer expression when the inner comes first');
like(row($pm, 17), qr/<summary class="c\d" title="\$c \|\| \$a &amp;&amp; \$b">/, 'on either side of it');
like(row($pm, 18), qr/<summary class="c\d" title="\$a &amp;&amp; \$b \|\| \$c">/, 'and when the outer comes first');
like(row($pm, 19), qr/<summary class="c\d" title="\$c \|\| \$a &amp;&amp; \$b">/, 'on either side');
like(row($pm, 16), qr/<table><tr><th>A<\/th><th>B<\/th><th>C<\/th><th>dec<\/th><\/tr>/, 'with a column per operand');

my $far = row($pm, 25);
like($far, qr/<li>if \(\$first_operand_with_a_long_name &gt; 10 and \$second_oper\.\.\.: the false branch never taken<\/li>/, 'a long branch is cut to 60 characters in the words');

my $pair = row($pm, 31);
if (eval { require Pod::Coverage; 1 }) {
    like($pair, qr/^<tr id="L31" class="miss">/, 'the pair line is marked for its pod');
    like($pair, qr/<li>no pod for this sub<\/li>/, 'and says so');
}
else {
    like($pair, qr/^<tr id="L31"><td class="n">31<\/td>/, 'without Pod::Coverage there is no pod to miss, so the pair line is not marked');
    unlike($pm, qr/<th class="pd">/, 'and no pod column');
}
is(scalar(() = $pair =~ /<details class="cond"><summary class="c3" title="\$p (?:&amp;&amp;|\|\|) \$q">100%<\/summary>/g), 2, 'two conditions seen in full on one line are two green tables');

my $idle = row($pm, 33);
like($idle, qr/<td class="st">(?:<span class="c0" title="statements: 0">0<\/span>){3}<\/td>/, 'three statements never run on one line are three red counts');
is(scalar(() = $idle =~ /<li>this line never ran<\/li>/g), 3, 'and said three times');
like($idle, qr/<li>idle was never called<\/li>/, 'beside the sub never called');

my $never = row($pm, 35);
like($never, qr/<td class="sb"><span class="sub c0" title="never_a: called 0">never_a<\/span><span class="sub c0" title="never_b: called 0">never_b<\/span><\/td>/, 'two subs never called on one line are two red chips');

my $pm_text = do { open my $fh, '<', $module or die; local $/; <$fh> };
write_file($module, $pm_text . "\n");
$out = XSCoverTest::run_report($db, $dir);
like($out, qr/can't locate structure for statement in lib\/Plain\.pm/, 'a source changed since the run is reported by Devel::Cover');
$summary = page('coverage.html');
like($summary, qr/<a href="lib-Plain-pm\.html">lib\/Plain\.pm<\/a><\/td><td class="pc na st" data-v="-1">n\/a<\/td>/, 'its row is n/a');
like($summary, qr/<a href="drive\.html">drive<\/a><\/td><td class="pc c3 st" data-v="100\.0" title="statements: (\d+) of \1">/, 'while the unchanged script keeps its numbers');
$pm = page('lib-Plain-pm.html');
like($pm, qr/<p class="meta"><\/p>/, 'its page has nothing to say in the heading');
like($pm, qr/<thead><tr><th class="n">line<\/th><th class="code">code<\/th><\/tr><\/thead>/, 'and only the line and code columns');
like(row($pm, 12), qr/^<tr id="L12"><td class="n">12<\/td><td class="code"><pre>our \$VERSION = &#39;0\.01&#39;;<\/pre><\/td><\/tr>/, 'the source is still shown');

unlink $module or die "$module: $!";
unlink File::Spec->catfile($db, 'lib-Plain-pm.html') or die;
$out = XSCoverTest::run_report($db, $dir);
like($out, qr/^Can't read file 'lib\/Plain\.pm' \[/m, 'a source that is gone is named');
ok(!-e File::Spec->catfile($db, 'lib-Plain-pm.html'), 'and gets no page');
$summary = page('coverage.html');
like($summary, qr/<a href="lib-Plain-pm\.html">lib\/Plain\.pm<\/a><\/td><td class="pc na st" data-v="-1">n\/a<\/td>/, 'while the summary still lists it');
like($summary, qr/<a href="drive\.html">drive<\/a><\/td><td class="pc c3 st" data-v="100\.0"/, 'beside the script');

done_testing;
