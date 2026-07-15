use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_bash($_[0]) }
sub has_span { index($_[0], $_[1]) >= 0 }

# keywords get esh-k
{
	my $out = hl("if true; then\necho foo\nfi\n");
	ok(has_span($out, 'class="esh-k"'), 'keyword spans present');
	ok(has_span($out, '>if<'), 'if keyword highlighted');
	ok(has_span($out, '>then<'), 'then keyword highlighted');
	ok(has_span($out, '>fi<'), 'fi keyword highlighted');
}

# comments get esh-c
{
	my $out = hl("# this is a comment\n");
	ok(has_span($out, 'class="esh-c"'), 'comment span present');
	like($out, qr/esh-c[^>]*>.*?#.*?this is a comment/s, 'comment content highlighted');
}

# variables get esh-v
{
	my $out = hl('echo $VAR $1 ${HOME}');
	ok(has_span($out, 'class="esh-v"'), 'variable span present');
	like($out, qr/esh-v[^>]*>\$VAR/, '$VAR highlighted');
}

# strings get esh-s
{
	my $out = hl(q(echo "hello world" 'single'));
	ok(has_span($out, 'class="esh-s"'), 'string span present');
	like($out, qr/esh-s[^>]*>&quot;hello world&quot;/, 'double-quoted string highlighted');
	like($out, qr/esh-s[^>]*>'single'/, 'single-quoted string highlighted');
}

# builtins get esh-b
{
	my $out = hl("echo hello\nread -r line\n");
	ok(has_span($out, 'class="esh-b"'), 'builtin span present');
	like($out, qr/esh-b[^>]*>echo/, 'echo highlighted as builtin');
}

# numbers get esh-n
{
	my $out = hl("count=42\n");
	ok(has_span($out, 'class="esh-n"'), 'number span present');
}

# heredoc operator gets esh-h
{
	my $out = hl("cat <<EOF\nhello\nEOF\n");
	ok(has_span($out, 'class="esh-h"'), 'heredoc operator span present');
}

# HTML entities for special chars
{
	my $out = hl('cat < input.txt');
	like($out, qr/&lt;/, 'angle bracket HTML-escaped');
}

# via highlight_string dispatch
{
	my $out = Eshu->highlight_string("echo hello", lang => 'bash');
	ok(has_span($out, 'class="esh-b"'), 'highlight_string(lang=>bash) works');
}
{
	my $out = Eshu->highlight_string("echo hello", lang => 'sh');
	ok(has_span($out, 'class="esh-b"'), 'highlight_string(lang=>sh) works');
}


# ── more keywords ─────────────────────────────────────────────────

{
    my $out = hl("while true; do echo x; done\n");
    like($out, qr{>while<}, 'while keyword');
    like($out, qr{>do<},    'do keyword');
    like($out, qr{>done<},  'done keyword');
}

{
    my $out = hl("for f in *.sh; do echo \$f; done\n");
    like($out, qr{>for<},  'for keyword');
    like($out, qr{>in<},   'in keyword');
}

{
    my $out = hl("case \$x in foo) ;; *) ;; esac\n");
    like($out, qr{>case<}, 'case keyword');
    like($out, qr{>esac<}, 'esac keyword');
}

{
    my $out = hl("function greet() { echo hello; }\n");
    like($out, qr{>function<}, 'function keyword');
}

{
    my $out = hl("return 0\n");
    like($out, qr{>return<}, 'return keyword');
}

{
    my $out = hl("break\ncontinue\n");
    like($out, qr{>break<},    'break keyword');
    like($out, qr{>continue<}, 'continue keyword');
}

{
    my $out = hl("until false; do sleep 1; done\n");
    like($out, qr{>until<}, 'until keyword');
}

{
    my $out = hl("if false; then x; elif true; then y; else z; fi\n");
    like($out, qr{>elif<}, 'elif keyword');
    like($out, qr{>else<}, 'else keyword');
}

{
    my $out = hl("local x=1\n");
    like($out, qr{>local<}, 'local keyword');
}

{
    my $out = hl("export PATH=/usr/bin\n");
    like($out, qr{>export<}, 'export keyword');
}

{
    my $out = hl("readonly PI=3\n");
    like($out, qr{>readonly<}, 'readonly keyword');
}

{
    my $out = hl("shift 2\n");
    like($out, qr{>shift<}, 'shift keyword');
}

{
    my $out = hl("unset VAR\n");
    like($out, qr{>unset<}, 'unset keyword');
}

{
    my $out = hl("source ~/.bashrc\n");
    like($out, qr{>source<}, 'source keyword');
}

{
    my $out = hl("true && false\n");
    like($out, qr{>true<},  'true keyword');
    like($out, qr{>false<}, 'false keyword');
}

# ── more builtins ─────────────────────────────────────────────────

{
    my $out = hl("cd /tmp && pwd\n");
    like($out, qr{>cd<},  'cd builtin');
    like($out, qr{>pwd<}, 'pwd builtin');
}

{
    my $out = hl("read -r line\n");
    like($out, qr{>read<}, 'read builtin');
}

{
    my $out = hl("printf '%s\n' hello\n");
    like($out, qr{>printf<}, 'printf builtin');
}

{
    my $out = hl("test -f file\n");
    like($out, qr{>test<}, 'test builtin');
}

{
    my $out = hl("grep -r foo .\n");
    like($out, qr{>grep<}, 'grep builtin');
}

{
    my $out = hl("ls -la\n");
    like($out, qr{>ls<}, 'ls builtin');
}

{
    my $out = hl("alias ll='ls -la'\n");
    like($out, qr{>alias<}, 'alias builtin');
}

# ── more variables ────────────────────────────────────────────────

{
    my $out = hl('echo $? $$ $! $0 $@ $# $*');
    like($out, qr{<span class="esh-v">\$\?</span>}, '$? special var');
    like($out, qr{<span class="esh-v">\$\$</span>}, '$$ special var');
    like($out, qr{<span class="esh-v">\$!</span>},  '$! special var');
    like($out, qr{<span class="esh-v">\$0</span>},  '$0 positional');
    like($out, qr{<span class="esh-v">\$\@</span>}, '$@ all args');
    like($out, qr{<span class="esh-v">\$#</span>},  '$# arg count');
    like($out, qr{<span class="esh-v">\$\*</span>}, '$* all args as string');
}

{
    my $out = hl('${VAR:-default}');
    like($out, qr{<span class="esh-v">\$\{VAR:-default\}</span>},
         '${VAR:-default} parameter expansion');
}

# ── lang aliases ──────────────────────────────────────────────────

{
    my $out = Eshu->highlight_string("echo hi\n", lang => 'zsh');
    like($out, qr{>echo<}, 'lang=zsh dispatches to bash highlighter');
}

{
    my $out = Eshu->highlight_string("echo hi\n", lang => 'shell');
    like($out, qr{>echo<}, 'lang=shell dispatches to bash highlighter');
}

done_testing;
