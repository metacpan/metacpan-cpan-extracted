use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_rust($_[0]) }

# ── keywords ─────────────────────────────────────────────────────

{
    my $out = hl('fn main() {}');
    like($out, qr/<span class="esh-k">fn<\/span>/, 'fn keyword');
}

{
    my $out = hl('let x = 1;');
    like($out, qr/<span class="esh-k">let<\/span>/, 'let keyword');
}

{
    my $out = hl('if true { } else { }');
    like($out, qr/<span class="esh-k">if<\/span>/,   'if keyword');
    like($out, qr/<span class="esh-k">else<\/span>/, 'else keyword');
    like($out, qr/<span class="esh-k">true<\/span>/, 'true keyword');
}

{
    my $out = hl('match x { _ => {} }');
    like($out, qr/<span class="esh-k">match<\/span>/, 'match keyword');
}

{
    my $out = hl('struct Foo { x: i32 }');
    like($out, qr/<span class="esh-k">struct<\/span>/, 'struct keyword');
}

{
    my $out = hl('impl Foo { fn new() -> Self { } }');
    like($out, qr/<span class="esh-k">impl<\/span>/, 'impl keyword');
    like($out, qr/<span class="esh-k">Self<\/span>/, 'Self keyword');
}

{
    my $out = hl('pub use std::collections::HashMap;');
    like($out, qr/<span class="esh-k">pub<\/span>/,  'pub keyword');
    like($out, qr/<span class="esh-k">use<\/span>/,  'use keyword');
}

# ── builtin types ─────────────────────────────────────────────────

{
    my $out = hl('let x: i32 = 0;');
    like($out, qr/<span class="esh-b">i32<\/span>/, 'i32 builtin type');
}

{
    my $out = hl('let s: String = String::new();');
    like($out, qr/<span class="esh-b">String<\/span>/, 'String builtin type');
}

{
    my $out = hl('let v: Vec<i32> = Vec::new();');
    like($out, qr/<span class="esh-b">Vec<\/span>/, 'Vec builtin type');
}

{
    my $out = hl('fn foo() -> Option<i32> { None }');
    like($out, qr/<span class="esh-b">Option<\/span>/, 'Option builtin');
    like($out, qr/<span class="esh-b">None<\/span>/,   'None builtin');
}

# ── strings ──────────────────────────────────────────────────────

{
    my $out = hl('"hello world"');
    like($out, qr/<span class="esh-s">&quot;hello world&quot;<\/span>/, 'double-quoted string');
}

{
    my $out = hl('r"raw string"');
    like($out, qr/<span class="esh-s">r&quot;raw string&quot;<\/span>/, 'raw string r"..."');
}

{
    my $out = hl("'a'");
    like($out, qr/<span class="esh-s">'a'<\/span>/, 'char literal');
}

# ── comments ─────────────────────────────────────────────────────

{
    my $out = hl('// line comment');
    like($out, qr/<span class="esh-c">\/\/ line comment<\/span>/, '// comment');
}

{
    my $out = hl('/* block */');
    like($out, qr/<span class="esh-c">\/\* block \*\/<\/span>/, '/* block comment */');
}

{
    my $out = hl('/// doc comment');
    like($out, qr/<span class="esh-c">\/\/\/ doc comment<\/span>/, '/// doc comment');
}

# ── numbers ──────────────────────────────────────────────────────

{
    my $out = hl('42');
    like($out, qr/<span class="esh-n">42<\/span>/, 'integer');
}

{
    my $out = hl('0xFF');
    like($out, qr/<span class="esh-n">0xFF<\/span>/, 'hex literal');
}

{
    my $out = hl('0b1010');
    like($out, qr/<span class="esh-n">0b1010<\/span>/, 'binary literal');
}

{
    my $out = hl('3.14');
    like($out, qr/<span class="esh-n">3\.14<\/span>/, 'float literal');
}

{
    my $out = hl('1_000_000');
    like($out, qr/<span class="esh-n">1_000_000<\/span>/, 'integer with underscores');
}

# ── attributes ───────────────────────────────────────────────────

{
    my $out = hl('#[derive(Debug)]');
    like($out, qr/<span class="esh-p">#\[derive\(Debug\)\]<\/span>/, 'attribute');
}

{
    my $out = hl('#[cfg(test)]');
    like($out, qr/<span class="esh-p">#\[cfg\(test\)\]<\/span>/, 'cfg attribute');
}

# ── HTML safety ──────────────────────────────────────────────────

{
    my $out = hl('let x = a < b;');
    like($out, qr/&lt;/, 'less-than escaped');
}

# ── macros highlighted as builtins ───────────────────────────────

{
    my $out = hl('println!("hi");');
    like($out, qr/<span class="esh-b">println<\/span>/, 'println macro highlighted');
}

{
    my $out = hl('vec![1, 2, 3]');
    like($out, qr/<span class="esh-b">vec<\/span>/, 'vec macro highlighted');
}

# ── partial keyword non-match ─────────────────────────────────────

{
    my $out = hl('let fns = 1;');
    unlike($out, qr/<span class="esh-k">fn<\/span>/, 'fn not matched inside fns');
}


# ── more keywords ─────────────────────────────────────────────────

{
    my $out = hl("enum Color { Red, Green }");
    like($out, qr/<span class="esh-k">enum<\/span>/, 'enum keyword');
}

{
    my $out = hl("trait Foo { fn bar(&self); }");
    like($out, qr/<span class="esh-k">trait<\/span>/, 'trait keyword');
}

{
    my $out = hl("mod utils { }");
    like($out, qr/<span class="esh-k">mod<\/span>/, 'mod keyword');
}

{
    my $out = hl("type Alias = String;");
    like($out, qr/<span class="esh-k">type<\/span>/, 'type keyword');
}

{
    my $out = hl("extern crate serde;");
    like($out, qr/<span class="esh-k">extern<\/span>/, 'extern keyword');
    like($out, qr/<span class="esh-k">crate<\/span>/, 'crate keyword');
}

{
    my $out = hl("unsafe { *ptr = 1; }");
    like($out, qr/<span class="esh-k">unsafe<\/span>/, 'unsafe keyword');
}

{
    my $out = hl("let f = move || x + 1;");
    like($out, qr/<span class="esh-k">move<\/span>/, 'move keyword');
}

{
    my $out = hl("const X: u32 = 42;");
    like($out, qr/<span class="esh-k">const<\/span>/, 'const keyword');
}

{
    my $out = hl("static Y: &str = \"hi\";");
    like($out, qr/<span class="esh-k">static<\/span>/, 'static keyword');
}

{
    my $out = hl("let mut x = 1;");
    like($out, qr/<span class="esh-k">mut<\/span>/, 'mut keyword');
}

{
    my $out = hl("fn f() -> i32 { loop { break 1; } }");
    like($out, qr/<span class="esh-k">loop<\/span>/,  'loop keyword');
    like($out, qr/<span class="esh-k">break<\/span>/, 'break keyword inside loop');
}

{
    my $out = hl("while let Some(x) = iter.next() { }");
    like($out, qr/<span class="esh-k">while<\/span>/, 'while keyword');
}

{
    my $out = hl("for x in 0..10 { continue; }");
    like($out, qr/<span class="esh-k">for<\/span>/,      'for keyword');
    like($out, qr/<span class="esh-k">continue<\/span>/, 'continue keyword');
}

{
    my $out = hl("async fn fetch() -> Result<(), E> { }");
    like($out, qr/<span class="esh-k">async<\/span>/, 'async keyword');
}

{
    my $out = hl("let x = async { await_value }.await;");
    like($out, qr/<span class="esh-k">await<\/span>/, 'await keyword (as method)');
}

{
    my $out = hl("dyn Trait + Send");
    like($out, qr/<span class="esh-k">dyn<\/span>/, 'dyn keyword');
}

{
    my $out = hl("where T: Clone + Send");
    like($out, qr/<span class="esh-k">where<\/span>/, 'where keyword');
}

{
    my $out = hl("super::module::func()");
    like($out, qr/<span class="esh-k">super<\/span>/, 'super keyword');
}

{
    my $out = hl("self.name");
    like($out, qr/<span class="esh-k">self<\/span>/, 'self keyword');
}

# ── more builtins ─────────────────────────────────────────────────

{
    my $out = hl("let r: Result<i32, String> = Ok(1);");
    like($out, qr/<span class="esh-b">Result<\/span>/, 'Result builtin');
}

{
    my $out = hl("let s: Option<i32> = Some(1);");
    like($out, qr/<span class="esh-b">Option<\/span>/, 'Option builtin');
    like($out, qr/<span class="esh-b">Some<\/span>/,   'Some builtin');
}

{
    my $out = hl("let b: Box<dyn Fn()> = Box::new(|| {});");
    like($out, qr/<span class="esh-b">Box<\/span>/, 'Box builtin');
}

{
    my $out = hl("assert!(x > 0);");
    like($out, qr/<span class="esh-b">assert<\/span>/, 'assert! macro highlighted as builtin');
}

{
    my $out = hl('let s = format!("val={}", x);');
    like($out, qr/<span class="esh-b">format<\/span>/, 'format! macro highlighted as builtin');
}

{
    my $out = hl("todo!()");
    like($out, qr/<span class="esh-b">todo<\/span>/, 'todo! macro highlighted as builtin');
}

done_testing;
