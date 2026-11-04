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

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; require Devel::Cover::DB::Structure; 1 };
plan skip_all => 'no cover script found' unless XSCoverTest::cover_script();

sub write_source { my ($path, @lines) = @_; open my $fh, '>', $path or die "$path: $!"; print $fh map { "$_\n" } @lines; close $fh }
sub page { my $f = File::Spec->catfile(@_); open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }
sub row { my ($html, $n) = @_; my ($row) = $html =~ /(<tr id="L$n".*?<\/tr>\n(?:<tr class="why">.*?<\/tr>\n)?)/s; return $row // '' }

sub write_db {
    my ($dir, $db, $run, $files) = @_;
    my $here = Cwd::getcwd();
    chdir $dir or die "$dir: $!";
    my $structure = Devel::Cover::DB::Structure->new;
    $structure->add_criteria(@{ $run->{collected} });
    for my $file (sort keys %$files) {
        my $f = $files->{$file};
        $run->{digests}{$file} = $structure->set_file($file);
        for my $s (@{ $f->{statement} || [] }) {
            $structure->add_statement($file, $s->[0]);
            push @{ $run->{count}{$file}{statement} }, $s->[1];
            push @{ $run->{count}{$file}{time} }, $s->[2] if @$s > 2;
        }
        for my $b (@{ $f->{branch} || [] }) {
            $structure->add_branch($file, [ $b->[0], defined $b->[1] ? { text => $b->[1] } : {} ]);
            push @{ $run->{count}{$file}{branch} }, $b->[2];
        }
        for my $c (@{ $f->{condition} || [] }) {
            $structure->add_condition($file, [ $c->[0], $c->[1] ]);
            push @{ $run->{count}{$file}{condition} }, $c->[2];
        }
        for my $s (@{ $f->{subroutine} || [] }) {
            $structure->add_subroutine($file, [ $s->[0], $s->[1] ]);
            push @{ $run->{count}{$file}{subroutine} }, $s->[2];
        }
    }
    my $name = ($run->{start} // 1) . ".$$." . sprintf '%05d', rand 2**16;
    my $cover = Devel::Cover::DB->new(base => $db, runs => { $name => $run }, structure => $structure);
    File::Path::make_path(File::Spec->catdir($db, 'runs'));
    $cover->{db} = File::Spec->catdir($db, 'runs', $name);
    $cover->write;
    chdir $here;
}

my $tmp = File::Temp->newdir;
my $dir = Cwd::abs_path("$tmp");
my $db  = File::Spec->catdir($dir, 'db');
File::Path::make_path(File::Spec->catdir($dir, 'src'), File::Spec->catdir($dir, 'lib'));
write_source(File::Spec->catfile($dir, 'src', 'hand.c'),
    'int hand(int x, int y) {',
    '    if (x)',
    '        return 1;',
    '    if (y) /* # uncoverable branch true */',
    '        return 2;',
    '    if (x && y)',
    '        return 3;',
    '    switch (x) { /* # uncoverable branch true count:2 */',
    '    case 0: return 4;',
    '    case 1: return 5;',
    '    default: return 6;',
    '    }',
    '    return 0;',
    '}',
);
my $many = join ' ', ('push @r, $p || $q;') x 17;
write_source(File::Spec->catfile($dir, 'lib', 'Hand.pm'),
    'package Hand;',
    "sub many { my (\$p, \$q) = \@_; my \@r; $many return \@r }",
    'sub quick { 1 }',
    '1;',
);
write_db($dir, $db, { collected => [qw(statement branch condition subroutine time)], start => 1700000000, run => 'hand' }, {
    'src/hand.c' => {
        statement  => [ [2, 3], [3, 0], [4, 3], [6, 3], [8, 3], [9, 1], [10, 2], [11, 0] ],
        branch     => [ [2, 'if (x)', [0, 0]], [4, 'if (y)', [0, 0]], [6, 'if (x && y)', [3]], [8, 'arm 1 of 3', [1, 2]], [8, 'arm 2 of 3', [2, 1]], [8, 'arm 3 of 3', [undef]], [13, undef, [undef, 1]] ],
        subroutine => [ [1, 'hand', 3] ],
    },
    'lib/Hand.pm' => {
        statement  => [ [2, 1, 0], [3, 0, 0] ],
        condition  => [ map { [2, { left => '$p', op => '||', right => '$q', type => 'or_3' }, [1, 0, 0]] } 1 .. 17 ],
        subroutine => [ [2, 'many', 1], [3, 'quick', 0] ],
    },
});

my $out = XSCoverTest::run_report($db, $dir);
unlike($out, qr/Can't|Use of uninitialized|Warning/, 'the report runs without complaint') or diag $out;
my $summary = page($db, 'coverage.html');
like($summary, qr/<p class="meta">\d{4}-\d\d-\d\d \d\d:\d\d · 1 run · 2 files<\/p>/, 'a run that recorded no perl, OS or finish shows its start alone');
like($summary, qr/<td class="pc c3 tm" data-v="100\.0" title="time"><meter min="0" max="100" value="100\.0"><\/meter><span>100\.0<\/span><\/td>/, 'a file whose statements took no time at all is still 100% of it');
like($summary, qr/title="conditions: 17 of 51"/, 'the conditions of the long line are counted');

my $c = page($db, 'src-hand-c.html');
my $l2 = row($c, 2);
like($l2, qr/<b class="c0">A 0<\/b><b class="c0">B 0<\/b>/, 'a C branch never reached shows both arms at 0');
like($l2, qr/<li>arm A and arm B of the branch if \(x\) were never taken/, 'and names both arms in the words');
my $l4 = row($c, 4);
like($l4, qr/<b class="un">A 0<\/b><b class="c0">B 0<\/b>/, 'an arm marked uncoverable is purple, the other red');
like($l4, qr/<li>arm B of the branch if \(y\) was never taken and the other never run either<\/li>/, 'and only the unmarked arm is missing in the words');
my $l6 = row($c, 6);
like($l6, qr/^<tr id="L6"><td class="n">6<\/td>.*<b class="c3">A 3<\/b><b class="c0">B 0<\/b>/, 'a branch whose run recorded one arm only draws the other as 0 and is not marked');
my $l8 = row($c, 8);
like($l8, qr/<span class="branch arm" title="arm 1 of 3: taken 1"><b class="c3">1 1<\/b><\/span>/, 'the first arm of a switch, taken');
like($l8, qr/<span class="branch arm" title="arm 2 of 3: taken 2"><b class="un">2 2<\/b><\/span>/, 'the second, marked uncoverable by count:2 yet taken, is purple');
like($l8, qr/<span class="branch arm" title="arm 3 of 3: taken 0"><b class="c0">3 0<\/b><\/span>/, 'the third, with no count recorded, is red at 0');
like($l8, qr/<ul><li>arm 3 of the 3-way jump was never taken<\/li><\/ul>/, 'and the words name the third arm alone');
my $l13 = row($c, 13);
like($l13, qr/<span class="branch" title=": arm A 0, arm B 1"><b class="c0">A 0<\/b><b class="c3">B 1<\/b><\/span>/, 'a branch without text, and with no count for its first arm, still draws its chips');
like($l13, qr/<li>arm A of the branch on this line was never taken, arm B taken 1<\/li>/, 'and its words');

my $pm = page($db, 'lib-Hand-pm.html');
my $l2pm = row($pm, 2);
like($l2pm, qr/<td class="cd"><\/td>/, 'a line with more than sixteen conditions gets no truth table');
is(scalar(() = $l2pm =~ /<li>the condition \$p \|\| \$q has combinations never seen<\/li>/g), 17, 'while each of them is still listed in the words, with no table to open');
like($l2pm, qr/<td class="tm"><span>0<\/span><\/td>/, 'a time of 0 is shown as 0');

for my $html (qw(coverage.html src-hand-c.html lib-Hand-pm.html)) {
    unlink File::Spec->catfile($db, $html) or die "$html: $!";
}
mkdir File::Spec->catfile($db, $_) or die "$_: $!" for qw(coverage.html src-hand-c.html);
$out = XSCoverTest::run_report($db, $dir);
like($out, qr/^Can't open file '[^']*coverage\.html' \[/m, 'a summary page that cannot be written is named');
like($out, qr/^Can't open file '[^']*src-hand-c\.html' \[/m, 'and so is a file page');
ok(-f File::Spec->catfile($db, 'lib-Hand-pm.html'), 'the other pages are still written');

my $tmp2 = File::Temp->newdir;
my $dir2 = Cwd::abs_path("$tmp2");
my $db2  = File::Spec->catdir($dir2, 'db');
write_source(File::Spec->catfile($dir2, 'one.pl'), 'print 1;');
write_db($dir2, $db2, { collected => [qw(statement)], run => 'one' }, { 'one.pl' => { statement => [ [1, 1] ] } });
XSCoverTest::run_report($db2, $dir2);
like(page($db2, 'coverage.html'), qr/<p class="meta">1 run · 1 file<\/p>/, 'a run without a start time is counted and nothing more');

my $tmp3 = File::Temp->newdir;
my $db3  = Cwd::abs_path("$tmp3");
Devel::Cover::DB->new(base => $db3, runs => {})->write($db3);
XSCoverTest::run_report($db3, $db3);
my $empty = page($db3, 'coverage.html');
like($empty, qr/<p class="meta"> · 0 files<\/p>/, 'an empty database gives a summary with no runs and no files');
like($empty, qr/<section class="tiles">\n<\/section>/, 'no tiles');
like($empty, qr/<tbody>\n<\/tbody>\n<tfoot><tr><td class="f">Total<\/td><td class="pc na /, 'and a total of n\/a');
opendir my $dh, $db3 or die;
is_deeply([sort grep { /\.html\z/ } readdir $dh], ['coverage.html'], 'and no other page');

done_testing;
