use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_string($_[0], lang => 'perl') }

# ── keywords ──────────────────────────────────────────────────────

{
    my $got = hl("my \$x = 1;");
    like($got, qr{<span class="esh-k">my</span>}, 'Perl keyword: my');
}

{
    my $got = hl("if (\$x) { }");
    like($got, qr{<span class="esh-k">if</span>}, 'Perl keyword: if');
}

{
    my $got = hl("sub foo { return 1; }");
    like($got, qr{<span class="esh-k">sub</span>},    'Perl keyword: sub');
    like($got, qr{<span class="esh-k">return</span>}, 'Perl keyword: return');
}

{
    my $got = hl("use strict;\nuse warnings;");
    like($got, qr{<span class="esh-k">use</span>}, 'Perl keyword: use');
}

{
    my $got = hl("foreach my \$x (\@arr) { }");
    like($got, qr{<span class="esh-k">foreach</span>}, 'Perl keyword: foreach');
}

{
    my $got = hl("unless (\$ok) { die 'oops'; }");
    like($got, qr{<span class="esh-k">unless</span>}, 'Perl keyword: unless');
    like($got, qr{<span class="esh-k">die</span>},    'Perl keyword: die');
}

{
    my $got = hl("push \@arr, 1;");
    like($got, qr{<span class="esh-k">push</span>}, 'Perl keyword: push');
}

# non-keywords should not get esh-k
{
    my $got = hl("foo(\$bar);");
    unlike($got, qr{<span class="esh-k">foo</span>}, 'user sub not a keyword');
}

# ── comments ──────────────────────────────────────────────────────

{
    my $got = hl("# full line comment\n");
    like($got, qr{<span class="esh-c"># full line comment</span>}, 'Perl line comment');
}

{
    my $got = hl("\$x = 1; # inline comment\n");
    like($got, qr{<span class="esh-c"># inline comment</span>}, 'inline comment');
}

{
    my $got = hl("#!/usr/bin/perl\n");
    like($got, qr{<span class="esh-c">#!/usr/bin/perl</span>}, 'shebang as comment');
}

# ── strings ───────────────────────────────────────────────────────

{
    my $got = hl('"hello"');
    like($got, qr{<span class="esh-s">&quot;hello&quot;</span>}, 'double-quoted string');
}

{
    my $got = hl("'world'");
    like($got, qr{<span class="esh-s">'world'</span>}, 'single-quoted string');
}

{
    my $got = hl('`ls -la`');
    like($got, qr{<span class="esh-s">`ls -la`</span>}, 'backtick string');
}

{
    my $got = hl('"it\'s fine"');
    like($got, qr{<span class="esh-s">}, 'string with escaped single quote inside dq');
}

{
    my $got = hl('"<b>bold</b>"');
    like($got, qr{<span class="esh-s">&quot;&lt;b&gt;bold&lt;/b&gt;&quot;</span>},
        'HTML inside string is escaped');
}

# ── variables ─────────────────────────────────────────────────────

{
    my $got = hl('$foo');
    like($got, qr{<span class="esh-v">\$foo</span>}, 'scalar variable');
}

{
    my $got = hl('@array');
    like($got, qr{<span class="esh-v">\@array</span>}, 'array variable');
}

{
    my $got = hl('%hash');
    like($got, qr{<span class="esh-v">%hash</span>}, 'hash variable');
}

{
    my $got = hl('$_');
    like($got, qr{<span class="esh-v">\$_</span>}, 'special var $_');
}

{
    my $got = hl('$!');
    like($got, qr{<span class="esh-v">\$!</span>}, 'special var $!');
}

{
    my $got = hl('$$');
    like($got, qr{<span class="esh-v">\$\$</span>}, 'special var $$');
}

{
    my $got = hl('@_');
    like($got, qr{<span class="esh-v">\@_</span>}, 'special var @_');
}

{
    my $got = hl('$#array');
    like($got, qr{<span class="esh-v">\$#array</span>}, 'last-index $#array');
}

# ── numbers ───────────────────────────────────────────────────────

{
    my $got = hl('42');
    like($got, qr{<span class="esh-n">42</span>}, 'integer');
}

{
    my $got = hl('3.14');
    like($got, qr{<span class="esh-n">3\.14</span>}, 'float');
}

{
    my $got = hl('0xFF');
    like($got, qr{<span class="esh-n">0xFF</span>}, 'hex');
}

{
    my $got = hl('0b1101');
    like($got, qr{<span class="esh-n">0b1101</span>}, 'binary');
}

{
    my $got = hl('1_000_000');
    like($got, qr{<span class="esh-n">1_000_000</span>}, 'number with underscores');
}

# ── regex ─────────────────────────────────────────────────────────

{
    my $got = hl('my $x = /foo/i;');
    like($got, qr{<span class="esh-r">/foo/i</span>}, 'bare regex with flag');
}

{
    my $got = hl('if ($x =~ /bar/) { }');
    like($got, qr{<span class="esh-r">/bar/</span>}, 'regex after =~');
}

{
    my $got = hl('m|pipe|');
    like($got, qr{<span class="esh-r">m\|pipe\|</span>}, 'regex with pipe delimiter');
}

{
    my $got = hl('s/old/new/g');
    like($got, qr{<span class="esh-r">s/old/new/g</span>}, 's operator');
}

{
    my $got = hl('my @w = qw(foo bar baz);');
    like($got, qr{<span class="esh-r">qw\(foo bar baz\)</span>}, 'qw()');
}

{
    my $got = hl('my $s = qq{hello $name};');
    like($got, qr{<span class="esh-r">qq\{hello}, 'qq{} construct');
}

{
    my $got = hl('tr/a-z/A-Z/');
    like($got, qr{<span class="esh-r">tr/a-z/A-Z/</span>}, 'tr operator');
}

{
    my $got = hl('y/a/b/');
    like($got, qr{<span class="esh-r">y/a/b/</span>}, 'y operator');
}

# division should NOT be a regex
{
    my $got = hl('my $x = 10 / 2;');
    unlike($got, qr{<span class="esh-r">}, 'division is not a regex');
}

# ── heredocs ─────────────────────────────────────────────────────

{
    my $src = "my \$x = <<END;\nhello\nEND\n";
    my $got = hl($src);
    like($got, qr{<span class="esh-h">&lt;&lt;END}, 'heredoc open marker (< is escaped)');
    like($got, qr{<span class="esh-h">hello},       'heredoc body line');
    like($got, qr{<span class="esh-h">END},         'heredoc terminator');
}

# ── POD ──────────────────────────────────────────────────────────

{
    my $src = "=pod\n\nSome text.\n\n=cut\n";
    my $got = hl($src);
    like($got, qr{<span class="esh-d">=pod},  'POD =pod command');
    like($got, qr{<span class="esh-d">Some text\.}, 'POD body text');
    like($got, qr{<span class="esh-d">=cut},  'POD =cut command');
}

{
    my $src = "=head1 NAME\n\nMy module.\n\n=cut\n";
    my $got = hl($src);
    like($got, qr{<span class="esh-d">=head1 NAME}, 'POD =head1 command line');
}

# ── __END__ / __DATA__ ────────────────────────────────────────────

{
    my $src = "my \$x = 1;\n__END__\nThis is data.\n";
    my $got = hl($src);
    like($got, qr{<span class="esh-k">__END__}, '__END__ gets keyword span');
    like($got, qr{<span class="esh-c">This is data\.}, 'content after __END__ is comment');
}

# ── HTML safety ──────────────────────────────────────────────────

{
    my $got = hl('print "<br>";');
    like($got, qr{&lt;br&gt;}, 'angle brackets in string are HTML-escaped');
}

{
    my $got = hl('if ($x < $y) { }');
    like($got, qr{&lt;}, 'less-than in code is HTML-escaped');
}

# ── combined example ─────────────────────────────────────────────

{
    my $src = <<'END';
#!/usr/bin/perl
use strict;
use warnings;

my $name = shift || 'world';
print "Hello, $name!\n";
END
    my $got = hl($src);
    like($got, qr{<span class="esh-c">#!/usr/bin/perl</span>}, 'shebang in full example');
    like($got, qr{<span class="esh-k">use</span>},              'use in full example');
    like($got, qr{<span class="esh-k">my</span>},               'my in full example');
    like($got, qr{<span class="esh-k">print</span>},            'print in full example');
    like($got, qr{<span class="esh-v">\$name</span>},           '$name variable in full example');
    like($got, qr{<span class="esh-s">&quot;Hello},               'string in full example');
}


# ── more keywords ─────────────────────────────────────────────────

{
    my $got = hl("local \$x = 1;");
    like($got, qr{<span class="esh-k">local</span>}, 'Perl keyword: local');
}

{
    my $got = hl("our \$pkg = 1;");
    like($got, qr{<span class="esh-k">our</span>}, 'Perl keyword: our');
}

{
    my $got = hl("package Foo::Bar;");
    like($got, qr{<span class="esh-k">package</span>}, 'Perl keyword: package');
}

{
    my $got = hl("my \$r = ref(\$x);");
    like($got, qr{<span class="esh-k">ref</span>}, 'Perl keyword: ref');
}

{
    my $got = hl("my \@s = sort { \$a cmp \$b } \@arr;");
    like($got, qr{<span class="esh-k">sort</span>}, 'Perl keyword: sort');
}

{
    my $got = hl("my \@m = map { \$_ * 2 } \@arr;");
    like($got, qr{<span class="esh-k">map</span>}, 'Perl keyword: map');
}

{
    my $got = hl("my \@g = grep { \$_ > 0 } \@arr;");
    like($got, qr{<span class="esh-k">grep</span>}, 'Perl keyword: grep');
}

{
    my $got = hl("my \@p = split /,/, \$s;");
    like($got, qr{<span class="esh-k">split</span>}, 'Perl keyword: split');
}

{
    my $got = hl("my \$j = join ',', \@arr;");
    like($got, qr{<span class="esh-k">join</span>}, 'Perl keyword: join');
}

{
    my $got = hl("exists \$h{key} and defined \$h{key}");
    like($got, qr{<span class="esh-k">exists</span>},  'Perl keyword: exists');
    like($got, qr{<span class="esh-k">defined</span>}, 'Perl keyword: defined');
    like($got, qr{<span class="esh-k">and</span>},     'Perl keyword: and');
}

{
    my $got = hl("delete \$h{k}; undef \$x;");
    like($got, qr{<span class="esh-k">delete</span>}, 'Perl keyword: delete');
    like($got, qr{<span class="esh-k">undef</span>},  'Perl keyword: undef');
}

{
    my $got = hl("while (\$x) { last; next; redo; }");
    like($got, qr{<span class="esh-k">while</span>}, 'Perl keyword: while');
    like($got, qr{<span class="esh-k">last</span>},  'Perl keyword: last');
    like($got, qr{<span class="esh-k">next</span>},  'Perl keyword: next');
    like($got, qr{<span class="esh-k">redo</span>},  'Perl keyword: redo');
}

{
    my $got = hl("for (my \$i = 0; \$i < 10; \$i++) { }");
    like($got, qr{<span class="esh-k">for</span>}, 'Perl keyword: for');
}

# ── more variables ────────────────────────────────────────────────

{
    my $got = hl('$0');
    like($got, qr{<span class="esh-v">\$0</span>}, 'special var $0');
}

{
    my $got = hl('$@');
    like($got, qr{<span class="esh-v">\$\@</span>}, 'special var $@');
}

{
    my $got = hl('$^W');
    like($got, qr{<span class="esh-v">\$\^</span>}, 'special var $^W (punctuation var $^ highlighted)');
}

{
    my $got = hl('$,');
    like($got, qr{<span class="esh-v">\$,</span>}, 'special var $,');
}

{
    my $got = hl('${foo_bar}');
    like($got, qr{<span class="esh-v">\$\{</span>}, 'block scalar var ${foo_bar} highlights ${ prefix');
}

# ── more regex / q-like ───────────────────────────────────────────

{
    my $got = hl('my $r = qr/pattern/;');
    like($got, qr{<span class="esh-r">qr/pattern/</span>}, 'qr// compile regex');
}

{
    my $got = hl("s{old}{new}g");
    like($got, qr{<span class="esh-r">s\{old\}\{new\}g</span>}, 's{}{} substitution with braces');
}

{
    my $got = hl("my \$x = q(no interpolation);");
    like($got, qr{<span class="esh-r">q\(no interpolation\)</span>}, 'q() single-quote-like');
}

# ── number with underscore ────────────────────────────────────────

{
    my $got = hl('1_000_000');
    like($got, qr{<span class="esh-n">1_000_000</span>}, 'number with _ separators');
}

# ── keyword not matched inside longer identifier ───────────────────

{
    my $got = hl("myif pushmore unless_true");
    unlike($got, qr{<span class="esh-k">if</span>},     'if not matched inside myif');
    unlike($got, qr{<span class="esh-k">push</span>},   'push not matched inside pushmore');
    unlike($got, qr{<span class="esh-k">unless</span>}, 'unless not matched inside unless_true');
}

done_testing;
