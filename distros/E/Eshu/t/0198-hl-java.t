use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_string($_[0], lang => 'java') }

# ── keywords ─────────────────────────────────────────────────────

{
    my $out = hl('public class Foo {}');
    like($out, qr{<span class="esh-k">public</span>}, 'public is a keyword');
    like($out, qr{<span class="esh-k">class</span>},  'class is a keyword');
}

{
    my $out = hl('private static final int MAX = 10;');
    like($out, qr{<span class="esh-k">private</span>}, 'private is a keyword');
    like($out, qr{<span class="esh-k">static</span>},  'static is a keyword');
    like($out, qr{<span class="esh-k">final</span>},   'final is a keyword');
    like($out, qr{<span class="esh-k">int</span>},     'int is a keyword');
}

{
    my $out = hl('if (x) return; else break;');
    like($out, qr{<span class="esh-k">if</span>},     'if is a keyword');
    like($out, qr{<span class="esh-k">return</span>}, 'return is a keyword');
    like($out, qr{<span class="esh-k">else</span>},   'else is a keyword');
    like($out, qr{<span class="esh-k">break</span>},  'break is a keyword');
}

{
    my $out = hl('for (int i = 0; i < n; i++) {}');
    like($out, qr{<span class="esh-k">for</span>},  'for is a keyword');
    like($out, qr{<span class="esh-k">int</span>},  'int in for loop');
}

{
    my $out = hl('try { } catch (Exception e) { } finally { }');
    like($out, qr{<span class="esh-k">try</span>},     'try is a keyword');
    like($out, qr{<span class="esh-k">catch</span>},   'catch is a keyword');
    like($out, qr{<span class="esh-k">finally</span>}, 'finally is a keyword');
}

{
    my $out = hl('switch (x) { case 1: break; default: return; }');
    like($out, qr{<span class="esh-k">switch</span>},  'switch is a keyword');
    like($out, qr{<span class="esh-k">case</span>},    'case is a keyword');
    like($out, qr{<span class="esh-k">default</span>}, 'default is a keyword');
}

# ── builtins ─────────────────────────────────────────────────────

{
    my $out = hl('String s = new String("hi");');
    like($out, qr{<span class="esh-b">String</span>}, 'String is a builtin');
}

{
    my $out = hl('Integer i = Integer.valueOf(42);');
    like($out, qr{<span class="esh-b">Integer</span>}, 'Integer is a builtin (field)');
}

{
    my $out = hl('System.out.println("hello");');
    like($out, qr{<span class="esh-b">System</span>}, 'System is a builtin');
}

{
    my $out = hl('throw new RuntimeException("oops");');
    like($out, qr{<span class="esh-b">RuntimeException</span>}, 'RuntimeException is a builtin');
}

# ── annotations → esh-p ──────────────────────────────────────────

{
    my $out = hl('@Override public void run() {}');
    like($out, qr{<span class="esh-p">\@Override</span>}, '@Override tagged esh-p');
}

{
    my $out = hl('@SuppressWarnings("all")');
    like($out, qr{<span class="esh-p">\@SuppressWarnings</span>},
         '@SuppressWarnings tagged esh-p');
}

{
    my $out = hl('@FunctionalInterface');
    like($out, qr{<span class="esh-p">\@FunctionalInterface</span>},
         '@FunctionalInterface tagged esh-p');
}

# ── strings → esh-s ──────────────────────────────────────────────

{
    my $out = hl('"hello world"');
    like($out, qr{<span class="esh-s">&quot;hello world&quot;</span>},
         'string literal tagged esh-s');
}

{
    my $out = hl("'A'");
    like($out, qr{<span class="esh-s">'A'</span>}, 'char literal tagged esh-s');
}

{
    my $out = hl('"escaped \\"quote\\""');
    like($out, qr{esh-s}, 'string with escaped quote tagged esh-s');
}

# ── comments → esh-c ─────────────────────────────────────────────

{
    my $out = hl('// this is a comment');
    like($out, qr{<span class="esh-c">// this is a comment</span>},
         'line comment tagged esh-c');
}

{
    my $out = hl('/* block comment */');
    like($out, qr{<span class="esh-c">/\* block comment \*/</span>},
         'block comment tagged esh-c');
}

{
    my $out = hl('/** javadoc */');
    like($out, qr{esh-c}, 'javadoc comment tagged esh-c');
}

# ── numbers → esh-n ──────────────────────────────────────────────

{
    my $out = hl('int n = 42;');
    like($out, qr{<span class="esh-n">42</span>}, 'integer literal tagged esh-n');
}

{
    my $out = hl('long l = 1_000_000L;');
    like($out, qr{<span class="esh-n">1_000_000L</span>}, 'long with underscores and suffix');
}

{
    my $out = hl('double d = 3.14;');
    like($out, qr{<span class="esh-n">3\.14</span>}, 'float literal tagged esh-n');
}

{
    my $out = hl('int h = 0xFF;');
    like($out, qr{<span class="esh-n">0xFF</span>}, 'hex literal tagged esh-n');
}

{
    my $out = hl('int b = 0b1010;');
    like($out, qr{<span class="esh-n">0b1010</span>}, 'binary literal tagged esh-n');
}

# ── non-keyword identifiers are not wrapped ───────────────────────

{
    my $out = hl('myVar fooBar');
    unlike($out, qr{esh-k.*myVar}, 'myVar is not a keyword');
}

# ── partial keyword not matched ───────────────────────────────────

{
    my $out = hl('returning foreach');
    unlike($out, qr{<span class="esh-k">return</span>}, 'return not matched in returning');
    unlike($out, qr{<span class="esh-k">for</span>},    'for not matched in foreach');
}

# ── HTML safety ───────────────────────────────────────────────────

{
    my $out = hl('a < b && c > d');
    like($out, qr{&lt;}, 'less-than HTML-escaped');
    like($out, qr{&gt;}, 'greater-than HTML-escaped');
}

{
    my $out = hl('"a & b"');
    like($out, qr{&amp;}, 'ampersand in string HTML-escaped');
}


# ── more keywords ─────────────────────────────────────────────────

{
    my $out = hl('abstract class Base {}');
    like($out, qr{<span class="esh-k">abstract</span>}, 'abstract keyword');
}

{
    my $out = hl('interface Runnable { void run(); }');
    like($out, qr{<span class="esh-k">interface</span>}, 'interface keyword');
    like($out, qr{<span class="esh-k">void</span>},      'void keyword');
}

{
    my $out = hl('enum Day { MON, TUE }');
    like($out, qr{<span class="esh-k">enum</span>}, 'enum keyword');
}

{
    my $out = hl('if (x instanceof String) {}');
    like($out, qr{<span class="esh-k">instanceof</span>}, 'instanceof keyword');
}

{
    my $out = hl('synchronized (lock) {}');
    like($out, qr{<span class="esh-k">synchronized</span>}, 'synchronized keyword');
}

{
    my $out = hl('class A extends B implements C {}');
    like($out, qr{<span class="esh-k">extends</span>},    'extends keyword');
    like($out, qr{<span class="esh-k">implements</span>}, 'implements keyword');
}

{
    my $out = hl('void foo() throws IOException {}');
    like($out, qr{<span class="esh-k">throws</span>}, 'throws keyword');
}

{
    my $out = hl('volatile int counter = 0;');
    like($out, qr{<span class="esh-k">volatile</span>}, 'volatile keyword');
}

{
    my $out = hl('while (x > 0) { x--; }');
    like($out, qr{<span class="esh-k">while</span>}, 'while keyword');
}

{
    my $out = hl('do { x++; } while (x < 10);');
    like($out, qr{<span class="esh-k">do</span>}, 'do keyword');
}

{
    my $out = hl('for (int i = 0; i < 10; i++) { continue; }');
    like($out, qr{<span class="esh-k">continue</span>}, 'continue keyword');
}

{
    my $out = hl('super.init(); this.x = 1; new Foo();');
    like($out, qr{<span class="esh-k">super</span>}, 'super keyword');
    like($out, qr{<span class="esh-k">this</span>},  'this keyword');
    like($out, qr{<span class="esh-k">new</span>},   'new keyword');
}

{
    my $out = hl('boolean b = true; char c = \'A\';');
    like($out, qr{<span class="esh-k">boolean</span>}, 'boolean keyword');
    like($out, qr{<span class="esh-k">char</span>},    'char keyword');
}

{
    my $out = hl('long l = 0L; double d = 0.0; float f = 0.0f;');
    like($out, qr{<span class="esh-k">long</span>},   'long keyword');
    like($out, qr{<span class="esh-k">double</span>}, 'double keyword');
    like($out, qr{<span class="esh-k">float</span>},  'float keyword');
}

{
    my $out = hl('import java.util.List; package com.example;');
    like($out, qr{<span class="esh-k">import</span>},  'import keyword');
    like($out, qr{<span class="esh-k">package</span>}, 'package keyword');
}

{
    my $out = hl('record Point(int x, int y) {}');
    like($out, qr{<span class="esh-k">record</span>}, 'record keyword');
}

{
    my $out = hl('sealed class Shape permits Circle, Rect {}');
    like($out, qr{<span class="esh-k">sealed</span>},  'sealed keyword');
    like($out, qr{<span class="esh-k">permits</span>}, 'permits keyword');
}

{
    my $out = hl('var list = new ArrayList<>();');
    like($out, qr{<span class="esh-k">var</span>}, 'var keyword');
}

# ── more builtins ─────────────────────────────────────────────────

{
    my $out = hl('Object obj = new Object();');
    like($out, qr{<span class="esh-b">Object</span>}, 'Object builtin');
}

{
    my $out = hl('StringBuilder sb = new StringBuilder();');
    like($out, qr{<span class="esh-b">StringBuilder</span>}, 'StringBuilder builtin (duplicate removed in favor of constructor context)');
}

{
    my $out = hl('double pi = Math.PI;');
    like($out, qr{<span class="esh-b">Math</span>}, 'Math builtin');
}

{
    my $out = hl('Long.parseLong("123"); Double.parseDouble("3.14");');
    like($out, qr{<span class="esh-b">Long</span>},   'Long builtin');
    like($out, qr{<span class="esh-b">Double</span>}, 'Double builtin');
}

{
    my $out = hl('StringBuilder sb = new StringBuilder();');
    like($out, qr{<span class="esh-b">StringBuilder</span>}, 'StringBuilder builtin');
}

# ── annotations ───────────────────────────────────────────────────

{
    my $out = hl('@Deprecated void old() {}');
    like($out, qr{<span class="esh-p">\@Deprecated</span>}, '@Deprecated annotation');
}

done_testing;
