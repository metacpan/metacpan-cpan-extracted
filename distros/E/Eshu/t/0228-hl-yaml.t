use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_yaml($_[0]) }

# mapping key highlighted as esh-a
{
    my $result = hl("key: value\n");
    like($result, qr/<span class="esh-a">key<\/span>/, 'mapping key gets esh-a');
}

# boolean true/false highlighted as esh-k
{
    my $result = hl("enabled: true\n");
    like($result, qr/<span class="esh-k">true<\/span>/, 'boolean true gets esh-k');
}

{
    my $result = hl("active: false\n");
    like($result, qr/<span class="esh-k">false<\/span>/, 'boolean false gets esh-k');
}

# null highlighted as esh-k
{
    my $result = hl("value: null\n");
    like($result, qr/<span class="esh-k">null<\/span>/, 'null gets esh-k');
}

# anchor &name gets esh-v
{
    my $result = hl("base: &anchor\n");
    like($result, qr/<span class="esh-v">&amp;anchor<\/span>/, 'anchor gets esh-v');
}

# alias *name gets esh-v
{
    my $result = hl("copy: *anchor\n");
    like($result, qr/<span class="esh-v">\*anchor<\/span>/, 'alias gets esh-v');
}

# tag !!str gets esh-p
{
    my $result = hl("key: !!str value\n");
    like($result, qr/<span class="esh-p">!!str<\/span>/, 'tag !!str gets esh-p');
}

# directive %YAML gets esh-p
{
    my $result = hl("%YAML 1.2\n");
    like($result, qr/<span class="esh-p">%YAML 1\.2<\/span>/, 'directive gets esh-p');
}

# document marker --- gets esh-k
{
    my $result = hl("---\n");
    like($result, qr/<span class="esh-k">---<\/span>/, 'document marker --- gets esh-k');
}

# comment # to EOL gets esh-c
{
    my $result = hl("# comment\n");
    like($result, qr/<span class="esh-c"># comment<\/span>/, 'comment gets esh-c');
}

# double-quoted string gets esh-s (quotes are HTML-escaped)
{
    my $result = hl("key: \"hello world\"\n");
    like($result, qr/<span class="esh-s">&quot;hello world&quot;<\/span>/, 'double-quoted string gets esh-s');
}

# single-quoted string gets esh-s
{
    my $result = hl("key: 'hello world'\n");
    like($result, qr/<span class="esh-s">'hello world'<\/span>/, 'single-quoted string gets esh-s');
}

# number gets esh-n
{
    my $result = hl("port: 8080\n");
    like($result, qr/<span class="esh-n">8080<\/span>/, 'integer number gets esh-n');
}

# block scalar body gets esh-h
{
    my $result = hl("key: |\n  body line\n");
    like($result, qr/<span class="esh-h">  body line<\/span>/, 'block scalar body gets esh-h');
}


# ── more boolean spellings ────────────────────────────────────────

{
    my $result = hl("flag: yes\n");
    like($result, qr/<span class="esh-k">yes<\/span>/, 'yes gets esh-k');
}

{
    my $result = hl("flag: no\n");
    like($result, qr/<span class="esh-k">no<\/span>/, 'no gets esh-k');
}

{
    my $result = hl("flag: on\n");
    like($result, qr/<span class="esh-k">on<\/span>/, 'on gets esh-k');
}

{
    my $result = hl("flag: off\n");
    like($result, qr/<span class="esh-k">off<\/span>/, 'off gets esh-k');
}

{
    my $result = hl("flag: True\n");
    like($result, qr/<span class="esh-k">True<\/span>/, 'True (cap) gets esh-k');
}

{
    my $result = hl("flag: False\n");
    like($result, qr/<span class="esh-k">False<\/span>/, 'False (cap) gets esh-k');
}

{
    my $result = hl("val: Null\n");
    like($result, qr/<span class="esh-k">Null<\/span>/, 'Null (cap) gets esh-k');
}

{
    my $result = hl("val: NULL\n");
    like($result, qr/<span class="esh-k">NULL<\/span>/, 'NULL (upper) gets esh-k');
}

{
    my $result = hl("val: YES\n");
    like($result, qr/<span class="esh-k">YES<\/span>/, 'YES (upper) gets esh-k');
}

{
    my $result = hl("val: NO\n");
    like($result, qr/<span class="esh-k">NO<\/span>/, 'NO (upper) gets esh-k');
}

{
    my $result = hl("val: ON\n");
    like($result, qr/<span class="esh-k">ON<\/span>/, 'ON (upper) gets esh-k');
}

{
    my $result = hl("val: OFF\n");
    like($result, qr/<span class="esh-k">OFF<\/span>/, 'OFF (upper) gets esh-k');
}

# ── document end marker ───────────────────────────────────────────

{
    my $result = hl("...\n");
    like($result, qr/<span class="esh-k">\.\.\.<\/span>/, 'document end marker ... gets esh-k');
}

# ── more mapping keys ─────────────────────────────────────────────

{
    my $result = hl("host: localhost\nport: 3306\n");
    like($result, qr/<span class="esh-a">host<\/span>/, 'host key gets esh-a');
    like($result, qr/<span class="esh-a">port<\/span>/, 'port key gets esh-a');
    like($result, qr/<span class="esh-n">3306<\/span>/, 'port value 3306 gets esh-n');
}

# ── more numbers ──────────────────────────────────────────────────

{
    my $result = hl("ratio: 3.14\n");
    like($result, qr/<span class="esh-n">3\.14<\/span>/, 'float gets esh-n');
}

{
    my $result = hl("neg: -42\n");
    like($result, qr/<span class="esh-n">-42<\/span>/, 'negative integer gets esh-n');
}

# ── list item key (indented key) ──────────────────────────────────

{
    my $result = hl("items:\n  - name: foo\n");
    like($result, qr/<span class="esh-a">name<\/span>/, 'indented key in list item gets esh-a');
}

# ── multi-key comment ─────────────────────────────────────────────

{
    my $result = hl("# top-level comment\nkey: val\n");
    like($result, qr/<span class="esh-c"># top-level comment<\/span>/, 'top comment gets esh-c');
    like($result, qr/<span class="esh-a">key<\/span>/, 'key after comment gets esh-a');
}

# ── block scalar folded (>) ───────────────────────────────────────

{
    my $result = hl("key: >\n  folded line\n");
    like($result, qr/<span class="esh-h">  folded line<\/span>/, 'folded block scalar body gets esh-h');
}

# ── tag variants ──────────────────────────────────────────────────

{
    my $result = hl("key: !!int 42\n");
    like($result, qr/<span class="esh-p">!!int<\/span>/, 'tag !!int gets esh-p');
}

{
    my $result = hl("key: !!bool true\n");
    like($result, qr/<span class="esh-p">!!bool<\/span>/, 'tag !!bool gets esh-p');
}

done_testing;
