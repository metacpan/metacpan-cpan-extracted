package Devel::Cover::Report::XSCover;

use 5.020;
use strict;
use warnings;

use File::Spec ();
use Getopt::Long ();
use POSIX ();

our $VERSION = '0.09';

our (%LABEL, %SHORT, %COLUMN, $THRESHOLD);

BEGIN {
    %LABEL = (
        statement  => 'statements',
        branch     => 'branches',
        condition  => 'conditions',
        subroutine => 'subroutines',
        pod        => 'pod',
        time       => 'time',
        total      => 'total',
    );
    %SHORT = (statement => 'stmt', branch => 'bran', condition => 'cond', subroutine => 'sub', pod => 'pod', time => 'time', total => 'total');
    %COLUMN = (statement => 'st', branch => 'br', condition => 'cd', subroutine => 'sb', pod => 'pd', time => 'tm');
    $THRESHOLD = { c0 => 75, c1 => 90, c2 => 100 };
}

sub get_options {
    my ($self, $opt) = @_;
    $opt->{option}{outputfile}   = 'coverage.html';
    $opt->{option}{summarytitle} = 'Coverage summary';
    $THRESHOLD->{$_} = $opt->{"report_$_"} for grep { defined $opt->{"report_$_"} } qw(c0 c1 c2);
    die "Invalid command line options" unless Getopt::Long::GetOptions($opt->{option}, qw(outputfile=s summarytitle=s report_c0=s report_c1=s report_c2=s));
}

sub report {
    my ($class, $db, $opt) = @_;
    my @files = grep { $db->{summary}{$_} } @{ $opt->{file} };
    my %page  = map { $_ => _page_name($_) } @files;
    my @show  = grep { $opt->{show}{$_} } $db->criteria;
    my %xs    = _xs_partners(\@files);
    for my $file (@files) {
        _write_file_page($db, $opt, $file, \@show, \%page, \%xs);
    }
    _write_summary_page($db, $opt, \@files, \@show, \%page, \%xs);
    print "done.\n" unless $opt->{silent};
}

sub _page_name {
    my ($file) = @_;
    (my $name = $file) =~ s/\W/-/g;
    return "$name.html";
}

sub _xs_partners {
    my ($files) = @_;
    my (%pm, %xs);
    for my $f (@$files) {
        my ($stem) = $f =~ m{([^/\\]+)\.(?:pm|xs)\z} or next;
        my $slot = $f =~ /\.pm\z/ ? \%pm : \%xs;
        push @{ $slot->{$stem} }, $f;
    }
    my %partner;
    for my $stem (keys %pm) {
        next unless $xs{$stem};
        for my $pm (@{ $pm{$stem} }) {
            $partner{$pm} = $xs{$stem};
        }
    }
    return %partner;
}

sub _pclass {
    my ($pc, $error) = @_;
    return 'c3' unless $error;
    return 'c0' if $pc < $THRESHOLD->{c0};
    return 'c1' if $pc < $THRESHOLD->{c1};
    return 'c2' if $pc < $THRESHOLD->{c2};
    return 'c3';
}

sub _bclass { $_[0] ? 'c3' : 'c0' }

sub _pc {
    my ($value) = @_;
    my $text = sprintf '%.2f', $value;
    chop $text;
    return $text;
}

sub _escape {
    my ($text) = @_;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;
    $text =~ s/'/&#39;/g;
    return $text;
}

sub _summary_cell {
    my ($db, $file, $criterion, $extra) = @_;
    my $s   = $db->{summary}{$file}{$criterion};
    my $col = $COLUMN{$criterion} // 'tt';
    return qq{<td class="pc na $col" data-v="-1">n/a</td>} unless $s;
    my $pc    = _pc($s->{percentage});
    my $class = _pclass($s->{percentage}, $s->{error});
    my $title = sprintf '%s: %d of %d', $LABEL{$criterion}, $s->{covered} || 0, $s->{total} || 0;
    $title = $LABEL{$criterion} if $criterion eq 'time';
    return qq{<td class="pc $class $col" data-v="$pc" title="} . _escape($title) . qq{"><meter min="0" max="100" value="$pc"></meter><span>$pc</span></td>};
}

sub _run_meta {
    my ($db) = @_;
    my @runs = eval { $db->runs };
    return '' unless @runs;
    my ($start) = sort { $a <=> $b } grep { $_ } map { $_->start } @runs;
    my ($finish) = sort { $b <=> $a } grep { $_ } map { $_->finish } @runs;
    my ($perl) = grep { defined && length } map { $_->perl } @runs;
    my ($os)   = grep { defined && length } map { $_->OS } @runs;
    my @parts;
    push @parts, "perl $perl" if $perl;
    push @parts, $os if $os;
    push @parts, POSIX::strftime('%Y-%m-%d %H:%M', localtime $start) . ($finish && $finish > $start ? POSIX::strftime(' to %H:%M', localtime $finish) : '') if $start;
    push @parts, scalar(@runs) . ' run' . (@runs == 1 ? '' : 's');
    return _escape(join ' · ', @parts);
}

sub _write_summary_page {
    my ($db, $opt, $files, $show, $page, $xs) = @_;
    my $title = $opt->{option}{summarytitle} // 'Coverage summary';
    my $out   = File::Spec->catfile($opt->{outputdir}, $opt->{option}{outputfile} // 'coverage.html');
    open my $fh, '>', $out or do { warn "Can't open file '$out' [$!]\n"; return };
    print $fh _head($title, 'summary');
    print $fh qq{<header><div><h1>} . _escape($title) . qq{</h1><p class="meta">} . _run_meta($db) . qq{ · } . scalar(@$files) . qq{ file} . (@$files == 1 ? '' : 's') . qq{</p></div>} . _theme_button() . qq{</header>\n<main>\n};
    my $total = $db->{summary}{Total} || {};
    print $fh qq{<section class="tiles">\n};
    for my $c (@$show, 'total') {
        my $s = $total->{$c};
        next unless $s;
        my $class = _pclass($s->{percentage}, $s->{error});
        my $ratio = $c eq 'time' ? '' : sprintf('%d of %d', $s->{covered} || 0, $s->{total});
        printf $fh qq{<div class="tile $class"><span class="name">%s</span><span class="value">%s%%</span><span class="ratio">%s</span></div>\n}, _escape($LABEL{$c}), _pc($s->{percentage}), _escape($ratio);
    }
    print $fh qq{</section>\n};
    print $fh qq{<p class="tools"><input id="filter" type="search" placeholder="Filter files" aria-label="Filter files"> <span class="hint">Click a column to sort.</span></p>\n};
    print $fh qq{<div class="scroll"><table id="files"><thead><tr><th data-sort="text">file</th>};
    print $fh qq{<th data-sort="num" class="$COLUMN{$_}">$SHORT{$_}</th>} for @$show;
    print $fh qq{<th data-sort="num">total</th></tr></thead>\n<tbody>\n};
    for my $file (@$files) {
        print $fh qq{<tr><td class="f"><a href="$page->{$file}">} . _escape($file) . qq{</a>};
        if ($xs->{$file}) {
            print $fh qq{ <a class="xs" href="$page->{$_}" title="the XS of this module: } . _escape($_) . qq{">xs</a>} for @{ $xs->{$file} };
        }
        print $fh qq{</td>};
        print $fh _summary_cell($db, $file, $_) for @$show;
        print $fh _summary_cell($db, $file, 'total');
        print $fh qq{</tr>\n};
    }
    print $fh qq{</tbody>\n<tfoot><tr><td class="f">Total</td>};
    print $fh _summary_cell($db, 'Total', $_) for @$show;
    print $fh _summary_cell($db, 'Total', 'total');
    print $fh qq{</tr></tfoot></table></div>\n};
    print $fh qq{</main>\n} . _script() . qq{</body></html>\n};
    close $fh;
}

sub _write_file_page {
    my ($db, $opt, $file, $show, $page, $xs) = @_;
    my $data = $db->cover->file($file);
    open my $in, '<', $file or do { warn "Can't read file '$file' [$!]\n"; return };
    my @lines = <$in>;
    close $in;
    chomp @lines;
    my $out = File::Spec->catfile($opt->{outputdir}, $page->{$file});
    open my $fh, '>', $out or do { warn "Can't open file '$out' [$!]\n"; return };
    my $summary = $db->{summary}{$file};
    my $tot     = $summary->{total} || {};
    my $c_file  = $file =~ /\.(?:xs|c|cc|cpp|cxx|h|hh|hpp)\z/ ? 1 : 0;
    my @shown   = grep { $data->$_() } @$show;
    print $fh _head($file, 'file');
    print $fh qq{<header><div><p class="crumb"><a href="} . ($opt->{option}{outputfile} // 'coverage.html') . qq{">summary</a>};
    print $fh qq{ · <a href="$page->{$_}">} . _escape($_) . qq{</a>} for @{ $xs->{$file} || [] };
    print $fh qq{</p><h1>} . _escape($file) . qq{</h1><p class="meta">};
    my @meta;
    push @meta, 'total ' . _pc($tot->{percentage}) . '%' if defined $tot->{percentage};
    for my $c (@shown) {
        my $s = $summary->{$c};
        push @meta, $c eq 'time' ? 'time' : sprintf('%s %s%% (%d of %d)', $SHORT{$c}, _pc($s->{percentage}), $s->{covered} || 0, $s->{total});
    }
    print $fh _escape(join ' · ', @meta) . qq{</p></div>} . _theme_button() . qq{</header>\n<main>\n};
    print $fh qq{<nav class="toggles">};
    print $fh qq{<label><input type="checkbox" data-crit="$COLUMN{$_}" checked> $LABEL{$_}</label> } for @shown;
    print $fh qq{<span class="hint">n and p move between uncovered lines. Click a marked line for what is missing.</span></nav>\n};
    print $fh _legend($c_file, \@shown);
    print $fh qq{<div class="scroll"><table class="src"><thead><tr><th class="n">line</th>};
    print $fh qq{<th class="$COLUMN{$_}">$SHORT{$_}</th>} for @shown;
    print $fh qq{<th class="code">code</th></tr></thead>\n<tbody>\n};
    my ($pod, $ended) = (0, 0);
    my $n = 0;
    for my $text (@lines) {
        $n++;
        my $dim = 0;
        if ($file =~ /\.p[ml]\z|\.t\z/ || $file !~ /\.(?:xs|c|cc|cpp|cxx|h|hh|hpp)\z/) {
            $ended = 1 if $text =~ /^__(?:END|DATA)__\s*$/;
            $pod   = 1 if !$ended && $text =~ /^=(?:pod|head\d|over|item|begin|for|encoding)\b/;
            $dim   = $pod || $ended;
            $pod   = 0 if $pod && $text =~ /^=cut\b/;
        }
        my (@cells, $miss, @why);
        for my $c (@shown) {
            my $items = $dim ? undef : $data->$c()->location($n);
            my ($cell, $err, @reasons) = _cell($c, $items, $c_file);
            $miss ||= $err;
            push @cells, $cell;
            push @why, @reasons;
        }
        my $class = join ' ', ($miss ? 'miss' : ()), ($dim ? 'dim' : ());
        print $fh qq{<tr id="L$n"} . ($class ? qq{ class="$class"} : '') . qq{><td class="n">$n</td>} . join('', @cells) . qq{<td class="code"><pre>} . _escape($text) . qq{</pre></td></tr>\n};
        if (@why) {
            print $fh qq{<tr class="why"><td class="n"></td><td colspan="} . (@shown + 1) . qq{"><ul>} . join('', map { qq{<li>} . _escape($_) . qq{</li>} } @why) . qq{</ul></td></tr>\n};
        }
    }
    print $fh qq{</tbody></table></div>\n</main>\n} . _script() . qq{</body></html>\n};
    close $fh;
}

sub _cell {
    my ($criterion, $items, $c_file) = @_;
    my $col = $COLUMN{$criterion};
    return (qq{<td class="$col"></td>}, 0) unless $items;
    my ($html, $err, @why) = ('', 0);
    if ($criterion eq 'statement' || $criterion eq 'pod') {
        for my $i (@$items) {
            my $e = $i->error;
            $err ||= $e;
            my $v = $i->covered;
            $html .= qq{<span class="} . ($e ? 'c0' : 'c3') . qq{" title="} . _escape("$LABEL{$criterion}: $v") . qq{">$v</span>};
            push @why, $criterion eq 'pod' ? 'no pod for this sub' : 'this line never ran' if $e;
        }
    }
    elsif ($criterion eq 'time') {
        $html .= qq{<span>} . _escape($_->covered) . qq{</span>} for @$items;
    }
    elsif ($criterion eq 'subroutine') {
        for my $i (@$items) {
            my $e = $i->error;
            $err ||= $e;
            $html .= qq{<span class="sub } . ($e ? 'c0' : 'c3') . qq{" title="} . _escape(sprintf '%s: called %d', $i->name, $i->covered) . qq{">} . _escape($i->name) . qq{</span>};
            push @why, sprintf('%s was never called', $i->name) if $e;
        }
    }
    elsif ($criterion eq 'branch') {
        for my $i (@$items) {
            my $e = $i->error;
            $err ||= $e;
            my @v    = $i->values;
            my $text = $i->text // '';
            if (my ($k, $n) = $text =~ /^arm (\d+) of (\d+)$/) {
                my $class = $i->uncoverable(0) ? 'un' : _bclass($v[0]);
                $html .= qq{<span class="branch arm" title="} . _escape(sprintf 'arm %d of %d: taken %d', $k, $n, $v[0] // 0) . qq{"><b class="$class">$k } . ($v[0] // 0) . qq{</b></span>};
                push @why, sprintf('arm %d of the %d-way jump was never taken', $k, $n) if $e && !$i->uncoverable(0);
                next;
            }
            my @label = $c_file ? ('A', 'B') : ('T', 'F');
            $html .= qq{<span class="branch" title="} . _escape(sprintf '%s: %s %s, %s %s', $text, $c_file ? 'arm A' : 'true', $v[0] // 0, $c_file ? 'arm B' : 'false', $v[1] // 0) . qq{">};
            for my $a (0 .. 1) {
                my $class = $i->uncoverable($a) ? 'un' : _bclass($v[$a]);
                $html .= qq{<b class="$class">$label[$a] } . ($v[$a] // 0) . qq{</b>};
            }
            $html .= qq{</span>};
            if ($e) {
                my @missing = grep { !$v[$_] && !$i->uncoverable($_) } 0 .. 1;
                my @taken   = grep { $v[$_] } 0 .. 1;
                my $name    = length $text ? _short($text) : 'on this line';
                my $rest    = @taken ? sprintf(', %s taken %s', join(' and ', map { "arm $label[$_]" } @taken), join(' and ', map { $v[$_] } @taken))
                            : @missing > 1 ? '' : ' and the other never run either';
                push @why, $c_file
                    ? sprintf('%s of the branch %s %s never taken%s', join(' and ', map { "arm $label[$_]" } @missing), $name, (@missing > 1 ? 'were' : 'was'), $rest)
                    : sprintf('%s: %s', $name, join(', ', map { $_ ? 'the true branch never taken' : 'the false branch never taken' } map { $_ == 0 ? 1 : 0 } @missing));
            }
        }
    }
    else {
        my @tables = eval { Devel::Cover::Report::XSCover::_truth_tables($items) };
        for my $t (@tables) {
            my ($tt, $expr) = @$t;
            my $e = $tt->percentage < 100 ? 1 : 0;
            $html .= qq{<details class="cond"><summary class="} . _pclass($tt->percentage, $e) . qq{" title="} . _escape($expr) . qq{">} . sprintf('%.0f%%', $tt->percentage) . qq{</summary>} . $tt->html('c0', 'c3') . qq{<p class="expr">} . _escape($expr) . qq{</p></details>};
        }
        for my $i (@$items) {
            next unless $i->error;
            $err = 1;
            my $info = $i->[1];
            if ($info->{op} eq 'of') {
                my @v = @{ $i->[0] };
                my @missing = grep { !$v[$_] } 0 .. 1;
                push @why, sprintf('%s of the condition %s never decided the result with its %s outcome', $info->{left}, _short($info->{right}), join(' or ', map { $_ ? 'false' : 'true' } @missing));
            }
            else {
                push @why, sprintf('the condition %s has combinations never seen%s', join(' ', grep { defined } @{$info}{qw(left op right)}), @tables ? ', open its table' : '');
            }
        }
    }
    return (qq{<td class="$col">$html</td>}, $err ? 1 : 0, @why);
}

sub _short {
    my ($text) = @_;
    $text =~ s/^\s+|\s+$//g;
    $text = substr($text, 0, 57) . '...' if length $text > 60;
    return $text;
}

sub _legend {
    my ($c_file, $shown) = @_;
    my %has = map { $_ => 1 } @$shown;
    my @items;
    push @items, 'a green count is a line that ran, a red one a line that never ran' if $has{statement};
    push @items, $c_file
        ? 'a branch shows its arms with the times each was taken, A and B, the arm into the body first, or one chip per arm of a switch, red when never'
        : 'a branch shows T and F with the times each was taken, red when never'
        if $has{branch};
    push @items, $c_file
        ? 'a condition (gcc 14 and later) shows, for each term of a decision, whether its true and its false outcome each decided the result, and opens into that table'
        : 'a condition shows how many of its combinations were seen and opens into its truth table'
        if $has{condition};
    push @items, 'a subroutine is named on its line, red when never called' if $has{subroutine};
    push @items, 'a purple chip is marked uncoverable in the source';
    return qq{<details class="legend"><summary>What the marks mean</summary><ul>} . join('', map { qq{<li>} . _escape($_) . qq{</li>} } @items) . qq{</ul></details>\n};
}

sub _truth_tables {
    my ($items) = @_;
    require Devel::Cover::Truth_Table;
    return if @$items > 16;
    my @lops;
    for my $c (@$items) {
        my $op  = $c->[1]{type};
        my @hit = map { $_ > 0 ? 1 : 0 } @{ $c->[0] };
        @hit = reverse @hit if $op =~ /^or_[23]$/;
        push @lops, {
            tt   => Devel::Cover::Truth_Table->new_primitive($op, @hit),
            cvg  => $c->[1],
            expr => join(' ', @{ $c->[1] }{qw(left op right)}),
        };
    }
    return map { [ $_->{tt}->sort, $_->{expr} ] } _merge_lineops(@lops);
}

sub _merge_lineops {
    my @ops = @_;
    my $rotations;
    while ($#ops > 0) {
        my $rm;
        for (1 .. $#ops) {
            if ($ops[0]{expr} eq $ops[$_]{cvg}{left}) {
                $ops[$_]{tt}->left_merge($ops[0]{tt});
                $ops[0] = $ops[$_];
                $rm = $_;
                last;
            }
            elsif ($ops[0]{expr} eq $ops[$_]{cvg}{right}) {
                $ops[$_]{tt}->right_merge($ops[0]{tt});
                $ops[0] = $ops[$_];
                $rm = $_;
                last;
            }
            elsif ($ops[$_]{expr} eq $ops[0]{cvg}{left}) {
                $ops[0]{tt}->left_merge($ops[$_]{tt});
                $rm = $_;
                last;
            }
            elsif ($ops[$_]{expr} eq $ops[0]{cvg}{right}) {
                $ops[0]{tt}->right_merge($ops[$_]{tt});
                $rm = $_;
                last;
            }
        }
        if ($rm) {
            splice @ops, $rm, 1;
            $rotations = 0;
        }
        else {
            unshift @ops, pop @ops;
            last if $rotations++ > $#ops;
        }
    }
    return @ops;
}

sub _theme_button { qq{<button id="theme" type="button" aria-label="Switch between light and dark">Theme</button>} }

sub _head {
    my ($title, $kind) = @_;
    return qq{<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n<title>} . _escape($title) . qq{</title>\n<style>\n} . _style() . qq{</style>\n</head>\n<body class="$kind">\n};
}

sub _style {
    return <<'CSS';
:root{--bg:#f7f7f5;--fg:#1b1b1b;--muted:#6b6b6b;--line:#dcdcd8;--card:#ffffff;--accent:#2d5be3;--c0:#d64545;--c1:#e08a1e;--c2:#c9b325;--c3:#2f9e5b;--c0bg:#fbe4e4;--c1bg:#fdebd3;--c2bg:#f9f3c9;--c3bg:#dff3e6;--unbg:#e9e4f7;--un:#6b4fbb;--here:#2d5be3}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--bg:#15171a;--fg:#e6e6e3;--muted:#9a9a96;--line:#2c3036;--card:#1d2024;--accent:#7aa2ff;--c0:#ff7b7b;--c1:#ffb45c;--c2:#e8d35a;--c3:#5fd38d;--c0bg:#3a1f22;--c1bg:#3a2c1a;--c2bg:#36331c;--c3bg:#1c3326;--unbg:#2a2440;--un:#b9a6ff;--here:#7aa2ff}}
:root[data-theme="dark"]{--bg:#15171a;--fg:#e6e6e3;--muted:#9a9a96;--line:#2c3036;--card:#1d2024;--accent:#7aa2ff;--c0:#ff7b7b;--c1:#ffb45c;--c2:#e8d35a;--c3:#5fd38d;--c0bg:#3a1f22;--c1bg:#3a2c1a;--c2bg:#36331c;--c3bg:#1c3326;--unbg:#2a2440;--un:#b9a6ff;--here:#7aa2ff}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.45 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
header{display:flex;justify-content:space-between;align-items:flex-start;gap:16px;padding:20px 16px 8px;max-width:1200px;margin:0 auto}
main{padding:0 16px 40px;max-width:1200px;margin:0 auto}
h1{font-size:1.5rem;margin:0 0 4px;word-break:break-all}
.meta,.crumb,.hint{color:var(--muted);font-size:.9rem;margin:0}
.crumb a,a{color:var(--accent)}
button#theme{background:var(--card);color:var(--fg);border:1px solid var(--line);border-radius:6px;padding:6px 10px;font:inherit;cursor:pointer}
.tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:10px;margin:12px 0 16px}
.tile{background:var(--card);border:1px solid var(--line);border-left:4px solid var(--c3);border-radius:8px;padding:10px 12px;display:flex;flex-direction:column}
.tile.c0{border-left-color:var(--c0)}.tile.c1{border-left-color:var(--c1)}.tile.c2{border-left-color:var(--c2)}
.tile .name{color:var(--muted);font-size:.85rem}.tile .value{font-size:1.4rem;font-weight:600}.tile .ratio{color:var(--muted);font-size:.8rem}
.tools{display:flex;gap:12px;align-items:center;margin:0 0 8px}
input#filter{font:inherit;padding:6px 10px;border:1px solid var(--line);border-radius:6px;background:var(--card);color:var(--fg);min-width:200px}
.scroll{overflow-x:auto;background:var(--card);border:1px solid var(--line);border-radius:8px}
table{border-collapse:collapse;width:100%}
th,td{padding:4px 8px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top;white-space:nowrap}
thead th{position:sticky;top:0;background:var(--card);font-weight:600;color:var(--muted);font-size:.85rem;z-index:1}
#files thead th{cursor:pointer;user-select:none}
#files thead th[data-sort="num"]{text-align:right}
#files td.pc,#files th[data-sort="num"]{width:9.5em}
#files td.pc span{display:inline-block;min-width:3.6em;text-align:right}
#files thead th[data-dir="asc"]::after{content:" \25B2"}#files thead th[data-dir="desc"]::after{content:" \25BC"}
#files td.f{white-space:normal;word-break:break-all}
#files tfoot td{font-weight:600}
td.pc{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}
td.pc meter{width:60px;height:10px;margin-right:6px;vertical-align:middle}
td.pc.c0 meter::-webkit-meter-optimum-value{background:var(--c0)}td.pc.c1 meter::-webkit-meter-optimum-value{background:var(--c1)}td.pc.c2 meter::-webkit-meter-optimum-value{background:var(--c2)}td.pc.c3 meter::-webkit-meter-optimum-value{background:var(--c3)}
td.pc.c0 meter::-moz-meter-bar{background:var(--c0)}td.pc.c1 meter::-moz-meter-bar{background:var(--c1)}td.pc.c2 meter::-moz-meter-bar{background:var(--c2)}td.pc.c3 meter::-moz-meter-bar{background:var(--c3)}
td.pc.c0 span{color:var(--c0)}td.pc.c1 span{color:var(--c1)}td.pc.c2 span{color:var(--c2)}td.pc.c3 span{color:var(--c3)}
td.na{color:var(--muted)}
a.xs{font-size:.75rem;border:1px solid var(--accent);border-radius:4px;padding:0 4px;text-decoration:none;margin-left:6px}
.toggles{display:flex;flex-wrap:wrap;gap:12px;align-items:center;margin:10px 0}
.toggles label{cursor:pointer}
table.src{font:13px/1.5 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}
table.src td{padding:0 8px;border-bottom:0}
table.src td.br,table.src td.sb,table.src td.cd{white-space:normal;max-width:18em;line-height:1.3}
table.src tr.why{display:none}table.src tr.why.open{display:table-row}
table.src tr.why td{background:var(--c0bg);font:14px/1.4 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;white-space:normal;padding:4px 12px}
table.src tr.why ul{margin:0;padding-left:18px}
table.src tr.miss td.n{cursor:pointer}
details.legend{margin:0 0 10px;color:var(--muted);font-size:.9rem}details.legend summary{cursor:pointer}details.legend ul{margin:4px 0 0;padding-left:18px}
table.src td.n{color:var(--muted);text-align:right;user-select:none;width:1%}
table.src td.code{width:100%;white-space:pre}
table.src td.code pre{margin:0;font:inherit;white-space:pre}
table.src tr.miss td.code{background:var(--c0bg)}
table.src tr.miss td.n{color:var(--c0);font-weight:600}
table.src tr.here td{outline:2px solid var(--here);outline-offset:-2px}
table.src tr.dim td.code{color:var(--muted)}
table.src td.st span,table.src td.pd span{display:inline-block;min-width:1.5em;text-align:right;padding:0 4px;border-radius:4px;font-size:.85em}
table.src td.st span.c3,table.src td.pd span.c3{background:var(--c3bg);color:var(--c3)}
table.src td.st span.c0,table.src td.pd span.c0{background:var(--c0bg);color:var(--c0)}
table.src td.tm span{color:var(--muted);font-size:.85em}
span.branch{display:inline-flex;margin-right:4px;border-radius:4px;overflow:hidden;border:1px solid var(--line);font-size:.75em;vertical-align:middle}
span.branch b{padding:0 5px;font-weight:600;white-space:nowrap}
span.branch{margin:1px 4px 1px 0}
span.branch b.c3{background:var(--c3bg);color:var(--c3)}span.branch b.c0{background:var(--c0bg);color:var(--c0)}span.branch b.un{background:var(--unbg);color:var(--un)}
span.sub{display:inline-block;padding:0 6px;border-radius:4px;font-size:.85em;margin-right:4px}
span.sub.c3{background:var(--c3bg);color:var(--c3)}span.sub.c0{background:var(--c0bg);color:var(--c0)}
details.cond{display:inline-block;margin-right:4px;font-size:.85em}
details.cond summary{cursor:pointer;padding:0 6px;border-radius:4px;list-style:none}
details.cond summary.c0{background:var(--c0bg);color:var(--c0)}details.cond summary.c1{background:var(--c1bg);color:var(--c1)}details.cond summary.c2{background:var(--c2bg);color:var(--c2)}details.cond summary.c3{background:var(--c3bg);color:var(--c3)}
details.cond[open]{position:relative}
details.cond table{position:absolute;z-index:2;background:var(--card);border:1px solid var(--line);border-radius:6px;padding:4px;width:auto;box-shadow:0 4px 16px rgba(0,0,0,.15)}
details.cond td,details.cond th{padding:1px 6px;border:0;text-align:center}
details.cond .c0{color:var(--c0)}details.cond .c3{color:var(--c3)}
details.cond p.expr{margin:0;color:var(--muted);display:none}
.hide-st .st,.hide-br .br,.hide-cd .cd,.hide-sb .sb,.hide-pd .pd,.hide-tm .tm{display:none}
@media (max-width:600px){header{flex-direction:column}td.pc meter{display:none}}
CSS
}

sub _script {
    return <<'JS';
<script>
(function(){
var root=document.documentElement;
try{var saved=localStorage.getItem('xs-cover-theme');if(saved)root.setAttribute('data-theme',saved)}catch(e){}
var theme=document.getElementById('theme');
if(theme)theme.onclick=function(){var cur=root.getAttribute('data-theme');var dark=cur?cur==='dark':window.matchMedia('(prefers-color-scheme: dark)').matches;var next=dark?'light':'dark';root.setAttribute('data-theme',next);try{localStorage.setItem('xs-cover-theme',next)}catch(e){}};
var files=document.getElementById('files');
if(files){
var ths=files.querySelectorAll('thead th');
Array.prototype.forEach.call(ths,function(th,i){th.onclick=function(){var num=th.getAttribute('data-sort')==='num';var body=files.tBodies[0];var rows=Array.prototype.slice.call(body.rows);var asc=th.getAttribute('data-dir')!=='asc';Array.prototype.forEach.call(ths,function(h){h.removeAttribute('data-dir')});th.setAttribute('data-dir',asc?'asc':'desc');
function key(r){var c=r.cells[i];var v=c.getAttribute('data-v');if(v===null)v=c.textContent.trim();return num?parseFloat(v):v.toLowerCase()}
rows.sort(function(a,b){var x=key(a),y=key(b);if(num){if(isNaN(x))x=-1;if(isNaN(y))y=-1;return asc?x-y:y-x}return asc?x.localeCompare(y):y.localeCompare(x)});
rows.forEach(function(r){body.appendChild(r)})}});
var filter=document.getElementById('filter');
if(filter)filter.oninput=function(){var q=filter.value.toLowerCase();Array.prototype.forEach.call(files.tBodies[0].rows,function(r){r.hidden=q!==''&&r.cells[0].textContent.toLowerCase().indexOf(q)<0})};
}
Array.prototype.forEach.call(document.querySelectorAll('input[data-crit]'),function(c){c.onchange=function(){root.classList.toggle('hide-'+c.getAttribute('data-crit'),!c.checked)}});
var miss=Array.prototype.slice.call(document.querySelectorAll('tr.miss')),at=-1;
Array.prototype.forEach.call(document.querySelectorAll('tr.miss'),function(r){r.onclick=function(e){if(e.target.closest('details'))return;var w=r.nextElementSibling;if(w&&w.classList.contains('why'))w.classList.toggle('open')}});
document.addEventListener('keydown',function(e){if(e.target&&(e.target.tagName==='INPUT'||e.target.tagName==='TEXTAREA'))return;if(e.key!=='n'&&e.key!=='p')return;if(!miss.length)return;at=e.key==='n'?(at+1)%miss.length:(at-1+miss.length)%miss.length;miss.forEach(function(r){r.classList.remove('here')});miss[at].classList.add('here');var w=miss[at].nextElementSibling;if(w&&w.classList.contains('why'))w.classList.add('open');miss[at].scrollIntoView({block:'center'})});
})();
</script>
JS
}

1;

__END__

=head1 NAME

Devel::Cover::Report::XSCover - a self-contained HTML report for Devel::Cover

=head1 SYNOPSIS

    cover -report XSCover
    xs_cover

The name is typed as C<XSCover>: C<cover> upper-cases only the first letter of a
report name to find its module, so C<xscover> would look for C<Xscover>.

=head1 DESCRIPTION

An HTML report for any Devel::Cover database, Perl only or with the C side that
L<xs_cover> adds. It writes F<coverage.html> and one page per file into the
database directory, and nothing else. Every page stands on its own: the styles
are inline, there is a dark theme that follows the system and a button to
override it, a few lines of script sort and filter the summary and move between
uncovered lines, and no library or external resource is loaded.

The summary page shows the totals as tiles, then a table of every file with a bar
and a percentage for each criterion, sortable by any column and filtered by a
search box. A module whose XS file is in the report has a link to it on its row.

A file page shows the source with the coverage drawn beside each line: the
statement count, each branch as chips with the times each arm was taken (T and
F for a Perl branch, A and B for a C branch, the arm into the body first, one chip per arm of a
C<switch>), each condition as a percentage that
opens into its truth table (for C under gcc 14 and later, one per term of a
decision, with its true and false outcomes), each subroutine as a chip with its name, and the pod
and time columns where they exist. Lines with an uncovered item are marked, and
clicking one opens a row that says in words what is missing. C<n> and C<p> move
between them and open that row. Checkboxes hide and show each kind of mark, a
legend explains them, and pod and anything after C<__END__> is dimmed.

=head1 OPTIONS

The same as the other HTML reports: C<-outputfile> for the summary page's name,
C<-summarytitle> for its title, and C<-report_c0>, C<-report_c1> and
C<-report_c2> for the thresholds below which a percentage is red, orange and
yellow (75, 90 and 100).

=head1 METHODS

=head2 get_options

Reads the options above from the command line.

=head2 report

    Devel::Cover::Report::XSCover->report($db, $options);

Writes the pages for the files in C<$options-E<gt>{file}> into
C<$options-E<gt>{outputdir}>.

=head1 SEE ALSO

L<Devel::Cover>, L<Devel::XSCover>

=cut
