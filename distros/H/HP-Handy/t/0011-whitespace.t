######################################################################
#
# 0011-whitespace.t -- Whitespace control tests
#
# Tests trim_blocks, lstrip_blocks, and {{- -}} / {%- -%} WSC
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if @INC && $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use HP::Handy;

my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my($c,$n)=@_; $T++; $c?($PASS++,print "ok $T - $n\n"):($FAIL++,print "not ok $T - $n\n") }
sub is { my($g,$e,$n)=@_; $T++;
    defined($g) && "$g" eq "$e"
        ? ($PASS++, print "ok $T - $n\n")
        : ($FAIL++, print "not ok $T - $n  (got=".encode_vis(defined $g?$g:'undef').", exp=".encode_vis($e).")\n") }

sub encode_vis {
    my $s = shift;
    $s =~ s/\n/\\n/g;
    $s =~ s/\t/\\t/g;
    return "'$s'";
}

sub r  { HP::Handy->new(auto_escape=>0)->render_string($_[0], $_[1]||{}) }
sub rt { HP::Handy->new(auto_escape=>0, trim_blocks=>1)->render_string($_[0], $_[1]||{}) }
sub rl { HP::Handy->new(auto_escape=>0, lstrip_blocks=>1)->render_string($_[0], $_[1]||{}) }
sub rb { HP::Handy->new(auto_escape=>0, trim_blocks=>1, lstrip_blocks=>1)->render_string($_[0], $_[1]||{}) }

my @tests = (

    # --- baseline (no options) ---
    sub { is(r("{% if 1 %}\nhello\n{% endif %}\n", {}),  "\nhello\n\n", 'baseline: newlines preserved') },
    sub { is(r("  {% if 1 %}hi{% endif %}"),              "  hi",       'baseline: leading spaces preserved') },

    # --- trim_blocks ---
    sub { is(rt("{% if 1 %}\nhello\n{% endif %}\n", {}),  "hello\n",   'trim_blocks: newline after if removed') },
    sub { is(rt("{% if 1 %}\nA\n{% else %}\nB\n{% endif %}\n", {}), "A\n", 'trim_blocks: if/else') },
    sub { is(rt("{% for x in items %}\n{{ x }}\n{% endfor %}\n", {items=>['a','b']}), "a\nb\n", 'trim_blocks: for loop') },
    sub { is(rt("A\n{% if 1 %}\nB\n{% endif %}\nC\n", {}), "A\nB\nC\n", 'trim_blocks: mixed content') },
    sub { is(rt("{% set x = 1 %}\n{{ x }}", {}), "1", 'trim_blocks: after set') },

    # --- lstrip_blocks ---
    sub { is(rl("  {% if 1 %}hello{% endif %}"),           "hello",     'lstrip_blocks: leading spaces stripped') },
    sub { is(rl("\t{% if 1 %}hi{% endif %}"),              "hi",        'lstrip_blocks: leading tab stripped') },
    sub { is(rl("  {% for x in items %}{{ x }}{% endfor %}", {items=>['a','b']}), "ab", 'lstrip_blocks: for') },
    sub { is(rl("text\n  {% if 1 %}ok{% endif %}"),        "text\nok",  'lstrip_blocks: mid-content') },
    sub { is(rl("{{ x }}  {% if 1 %}ok{% endif %}", {x=>'A'}), "A  ok", 'lstrip_blocks: not stripped when text precedes on same line') },

    # --- both together ---
    sub { is(rb("  {% if 1 %}\nhello\n  {% endif %}\n"),   "hello\n",  'both: if block') },
    sub { is(rb("  {% for x in items %}\n{{ x }}\n  {% endfor %}\n", {items=>['a','b']}), "a\nb\n", 'both: for loop') },
    sub { is(rb("A\n  {% if 1 %}\nB\n  {% endif %}\nC\n"), "A\nB\nC\n",'both: surrounding text') },

    # --- whitespace control: {{- and -}} ---
    sub { is(r("  {{- x }}", {x=>"hi"}),    "hi",    'WSC: {{- strips left') },
    sub { is(r("{{ x -}}  ", {x=>"hi"}),    "hi",    'WSC: -}} strips right') },
    sub { is(r("A {{- x -}} B", {x=>"hi"}), "AhiB",  'WSC: both sides') },
    sub { is(r("A\n{{- x }}", {x=>"hi"}),   "Ahi",   'WSC: strips newline left') },
    sub { is(r("{{ x -}}\nB", {x=>"hi"}),   "hiB",   'WSC: strips newline right') },

    # --- whitespace control: {%- and -%} ---
    sub { is(r("  {%- if 1 %}hi{% endif %}"),     "hi",    'WSC: {%- strips left of tag') },
    sub { is(r("{% if 1 -%}  hi{% endif %}"),      "hi",    'WSC: -%} strips right of tag') },
    sub { is(r("A\n{%- if 1 %}B{% endif %}"),      "AB",    'WSC: block tag strips left newline') },
    sub { is(r("{% if 1 -%}\nB{% endif %}"),        "B",     'WSC: block tag strips right newline') },

    # --- WSC with variables ---
    sub { is(r("prefix\n  {{- x -}}  \nsuffix", {x=>"MID"}), "prefixMIDsuffix", 'WSC: var strips both sides') },

    # --- no spurious stripping ---
    sub { is(r("{{ x }} {{ y }}", {x=>"a",y=>"b"}), "a b", 'no-WSC: space between vars preserved') },
    sub { is(r("{{ x }}\n{{ y }}", {x=>"a",y=>"b"}), "a\nb", 'no-WSC: newline between vars preserved') },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
print "# $PASS passed, $FAIL failed\n";
