use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_go($_[0]) }
sub has_span { index($_[0], $_[1]) >= 0 }

# keywords get esh-k
{
	my $out = hl("func main() {\nreturn\n}");
	ok(has_span($out, 'class="esh-k"'), 'keyword spans present');
	like($out, qr/esh-k[^>]*>func</, 'func keyword highlighted');
	like($out, qr/esh-k[^>]*>return</, 'return keyword highlighted');
}

# builtins get esh-b
{
	my $out = hl("len(s)\nmake([]int, 10)\npanic(err)");
	ok(has_span($out, 'class="esh-b"'), 'builtin spans present');
	like($out, qr/esh-b[^>]*>len</, 'len highlighted as builtin');
	like($out, qr/esh-b[^>]*>make</, 'make highlighted as builtin');
	like($out, qr/esh-b[^>]*>panic</, 'panic highlighted as builtin');
}

# predeclared types are builtins
{
	my $out = hl("var x int\nvar s string\nvar b bool");
	like($out, qr/esh-b[^>]*>int</, 'int highlighted as builtin');
	like($out, qr/esh-b[^>]*>string</, 'string highlighted as builtin');
	like($out, qr/esh-b[^>]*>bool</, 'bool highlighted as builtin');
}

# strings get esh-s
{
	my $out = hl(q(s := "hello world"));
	ok(has_span($out, 'class="esh-s"'), 'string span present');
	like($out, qr/esh-s[^>]*>&quot;hello world&quot;/, 'DQ string highlighted');
}

# raw string gets esh-s
{
	my $out = hl('s := `raw string`');
	like($out, qr/esh-s[^>]*>`raw string`/, 'raw string highlighted');
}

# rune literal gets esh-s
{
	my $out = hl("r := 'x'");
	like($out, qr/esh-s[^>]*>'x'/, 'rune literal highlighted');
}

# line comment gets esh-c
{
	my $out = hl("// this is a comment\nx := 1");
	ok(has_span($out, 'class="esh-c"'), 'comment span present');
	like($out, qr/esh-c[^>]*>\/\/ this is a comment/, 'line comment highlighted');
}

# block comment gets esh-c
{
	my $out = hl("/* block */\nx := 1");
	like($out, qr/esh-c[^>]*>\/\* block \*\//, 'block comment highlighted');
}

# numbers get esh-n
{
	my $out = hl("x := 42\ny := 3.14\nz := 0xFF");
	ok(has_span($out, 'class="esh-n"'), 'number spans present');
	like($out, qr/esh-n[^>]*>42</, 'integer highlighted');
	like($out, qr/esh-n[^>]*>0xFF</, 'hex number highlighted');
}

# Go-specific numbers: binary, octal, underscore separators
{
	my $out = hl("a := 0b1010\nb := 0o755\nc := 1_000_000");
	like($out, qr/esh-n[^>]*>0b1010</, 'binary literal highlighted');
	like($out, qr/esh-n[^>]*>0o755</, 'octal literal highlighted');
	like($out, qr/esh-n[^>]*>1_000_000</, 'underscore-separated number highlighted');
}

# HTML entities for angle brackets
{
	my $out = hl("if x < 10 {");
	like($out, qr/&lt;/, 'angle bracket HTML-escaped');
}

# via highlight_string dispatch
{
	my $out = Eshu->highlight_string("func main() {}", lang => 'go');
	like($out, qr/esh-k[^>]*>func</, 'highlight_string(lang=>go) dispatches correctly');
}


# ── more keywords ─────────────────────────────────────────────────

{
    my $out = hl("package main");
    like($out, qr/esh-k[^>]*>package</, 'package keyword');
}

{
    my $out = hl('import "fmt"');
    like($out, qr/esh-k[^>]*>import</, 'import keyword');
}

{
    my $out = hl("type Foo struct { x int }");
    like($out, qr/esh-k[^>]*>type</,   'type keyword');
    like($out, qr/esh-k[^>]*>struct</, 'struct keyword');
}

{
    my $out = hl("type I interface { Foo() }");
    like($out, qr/esh-k[^>]*>interface</, 'interface keyword');
}

{
    my $out = hl("var x map[string]int");
    like($out, qr/esh-k[^>]*>var</,   'var keyword');
    like($out, qr/esh-k[^>]*>map</,   'map keyword');
}

{
    my $out = hl("const x = iota");
    like($out, qr/esh-k[^>]*>const</, 'const keyword');
}

{
    my $out = hl("ch := make(chan int)");
    like($out, qr/esh-k[^>]*>chan</, 'chan keyword');
}

{
    my $out = hl("for i, v := range items { }");
    like($out, qr/esh-k[^>]*>range</, 'range keyword');
}

{
    my $out = hl("go func() { }()");
    like($out, qr/esh-k[^>]*>go</, 'go keyword');
}

{
    my $out = hl("defer f.Close()");
    like($out, qr/esh-k[^>]*>defer</, 'defer keyword');
}

{
    my $out = hl("select { case x := <-ch: }");
    like($out, qr/esh-k[^>]*>select</, 'select keyword');
}

{
    my $out = hl("switch x { case 1: fallthrough }");
    like($out, qr/esh-k[^>]*>switch</,      'switch keyword');
    like($out, qr/esh-k[^>]*>fallthrough</, 'fallthrough keyword');
}

{
    my $out = hl("goto label");
    like($out, qr/esh-k[^>]*>goto</, 'goto keyword');
}

# ── more builtins ─────────────────────────────────────────────────

{
    my $out = hl("s = append(s, x)");
    like($out, qr/esh-b[^>]*>append</, 'append builtin');
}

{
    my $out = hl("n := cap(ch)");
    like($out, qr/esh-b[^>]*>cap</, 'cap builtin');
}

{
    my $out = hl("close(ch)");
    like($out, qr/esh-b[^>]*>close</, 'close builtin');
}

{
    my $out = hl("copy(dst, src)");
    like($out, qr/esh-b[^>]*>copy</, 'copy builtin');
}

{
    my $out = hl("delete(m, k)");
    like($out, qr/esh-b[^>]*>delete</, 'delete builtin');
}

{
    my $out = hl("recover()");
    like($out, qr/esh-b[^>]*>recover</, 'recover builtin');
}

{
    my $out = hl("var x uint64; var y uintptr");
    like($out, qr/esh-b[^>]*>uint64</,  'uint64 builtin type');
    like($out, qr/esh-b[^>]*>uintptr</, 'uintptr builtin type');
}

{
    my $out = hl("var f float64; var g float32");
    like($out, qr/esh-b[^>]*>float64</, 'float64 builtin type');
    like($out, qr/esh-b[^>]*>float32</, 'float32 builtin type');
}

{
    my $out = hl("var r rune; var b byte");
    like($out, qr/esh-b[^>]*>rune</, 'rune builtin type');
    like($out, qr/esh-b[^>]*>byte</, 'byte builtin type');
}

{
    my $out = hl("if err != nil { return }");
    like($out, qr/esh-b[^>]*>nil</, 'nil is a builtin constant');
}

{
    my $out = hl("iota");
    like($out, qr/esh-b[^>]*>iota</, 'iota is a builtin constant');
}

{
    my $out = hl("var e error = fmt.Errorf(\"err\")");
    like($out, qr/esh-b[^>]*>error</, 'error interface is a builtin');
}

# ── partial keyword non-match ──────────────────────────────────────

{
    my $out = hl("mapData forLoop goroutine");
    unlike($out, qr/esh-k[^>]*>map</,  'map not matched inside mapData');
    unlike($out, qr/esh-k[^>]*>for</,  'for not matched inside forLoop');
    unlike($out, qr/esh-k[^>]*>go</,   'go not matched inside goroutine');
}

done_testing;
