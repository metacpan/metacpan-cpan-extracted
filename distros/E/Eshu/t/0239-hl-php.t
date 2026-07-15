use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_php($_[0]) }

# ── keywords ─────────────────────────────────────────────────────

{
    my $out = hl('function foo() {}');
    like($out, qr/<span class="esh-k">function<\/span>/, 'function keyword');
}

{
    my $out = hl('if ($x) { return false; }');
    like($out, qr/<span class="esh-k">if<\/span>/,     'if keyword');
    like($out, qr/<span class="esh-k">return<\/span>/, 'return keyword');
    like($out, qr/<span class="esh-k">false<\/span>/,  'false keyword');
}

{
    my $out = hl('foreach ($arr as $k => $v) {}');
    like($out, qr/<span class="esh-k">foreach<\/span>/, 'foreach keyword');
    like($out, qr/<span class="esh-k">as<\/span>/,      'as keyword');
}

{
    my $out = hl('class Foo extends Bar implements Baz {}');
    like($out, qr/<span class="esh-k">class<\/span>/,      'class keyword');
    like($out, qr/<span class="esh-k">extends<\/span>/,    'extends keyword');
    like($out, qr/<span class="esh-k">implements<\/span>/, 'implements keyword');
}

{
    my $out = hl('match ($x) { default => null }');
    like($out, qr/<span class="esh-k">match<\/span>/,   'match keyword');
    like($out, qr/<span class="esh-k">default<\/span>/, 'default keyword');
    like($out, qr/<span class="esh-k">null<\/span>/,    'null keyword');
}

# ── builtins ─────────────────────────────────────────────────────

{
    my $out = hl('$n = count($arr);');
    like($out, qr/<span class="esh-b">count<\/span>/, 'count builtin');
}

{
    my $out = hl('$s = str_replace("a", "b", $str);');
    like($out, qr/<span class="esh-b">str_replace<\/span>/, 'str_replace builtin');
}

{
    my $out = hl('throw new RuntimeException("oops");');
    like($out, qr/<span class="esh-k">throw<\/span>/,            'throw keyword');
    like($out, qr/<span class="esh-k">new<\/span>/,              'new keyword');
    like($out, qr/<span class="esh-b">RuntimeException<\/span>/, 'RuntimeException builtin');
}

# ── variables → purple ───────────────────────────────────────────

{
    my $out = hl('$foo = $bar;');
    like($out, qr/<span class="esh-p">\$foo<\/span>/, '$foo purple');
    like($out, qr/<span class="esh-p">\$bar<\/span>/, '$bar purple');
}

# ── strings ──────────────────────────────────────────────────────

{
    my $out = hl('"hello world"');
    like($out, qr/<span class="esh-s">&quot;hello world&quot;<\/span>/, 'double-quoted string');
}

{
    my $out = hl("'single quoted'");
    like($out, qr/<span class="esh-s">'single quoted'<\/span>/, 'single-quoted string');
}

# ── numbers ──────────────────────────────────────────────────────

{
    my $out = hl('42');
    like($out, qr/<span class="esh-n">42<\/span>/, 'integer number');
}

{
    my $out = hl('3.14');
    like($out, qr/<span class="esh-n">3\.14<\/span>/, 'float number');
}

{
    my $out = hl('0xFF');
    like($out, qr/<span class="esh-n">0xFF<\/span>/, 'hex number');
}

{
    my $out = hl('0b1010');
    like($out, qr/<span class="esh-n">0b1010<\/span>/, 'binary number');
}

# ── comments ─────────────────────────────────────────────────────

{
    my $out = hl('// line comment');
    like($out, qr/<span class="esh-c">\/\/ line comment<\/span>/, '// comment');
}

{
    my $out = hl('# hash comment');
    like($out, qr/<span class="esh-c"># hash comment<\/span>/, '# comment');
}

{
    my $out = hl('/* block */');
    like($out, qr/<span class="esh-c">\/\* block \*\/<\/span>/, 'block comment');
}

# ── HTML safety ──────────────────────────────────────────────────

{
    my $out = hl('$x = 1 < 2;');
    like($out, qr/&lt;/, 'less-than HTML-escaped');
}

{
    my $out = hl('echo "<b>bold</b>";');
    like($out, qr/&lt;b&gt;bold&lt;\/b&gt;/, 'HTML tags inside string escaped');
}

# ── attribute #[...] → purple ────────────────────────────────────

{
    my $out = hl('#[Route("/")]');
    like($out, qr/<span class="esh-p">#\[Route\(&quot;\/&quot;\)\]<\/span>/, 'PHP 8 attribute');
}

# ── partial keyword non-match ─────────────────────────────────────

{
    my $out = hl('$foreach = 1;');
    unlike($out, qr/<span class="esh-k">foreach<\/span>/, 'foreach inside identifier not highlighted');
}


# ── more keywords ─────────────────────────────────────────────────

{
    my $out = hl('abstract class Base {}');
    like($out, qr/<span class="esh-k">abstract<\/span>/, 'abstract keyword');
}

{
    my $out = hl('interface Countable {}');
    like($out, qr/<span class="esh-k">interface<\/span>/, 'interface keyword');
}

{
    my $out = hl('trait Serializable {}');
    like($out, qr/<span class="esh-k">trait<\/span>/, 'trait keyword');
}

{
    my $out = hl('enum Status { Active, Inactive }');
    like($out, qr/<span class="esh-k">enum<\/span>/, 'enum keyword');
}

{
    my $out = hl('while ($x > 0) { $x--; }');
    like($out, qr/<span class="esh-k">while<\/span>/, 'while keyword');
}

{
    my $out = hl('do { $x++; } while ($x < 10);');
    like($out, qr/<span class="esh-k">do<\/span>/, 'do keyword');
}

{
    my $out = hl('for ($i = 0; $i < 10; $i++) { continue; }');
    like($out, qr/<span class="esh-k">for<\/span>/,      'for keyword');
    like($out, qr/<span class="esh-k">continue<\/span>/, 'continue keyword');
}

{
    my $out = hl('switch ($x) { case 1: break; default: return; }');
    like($out, qr/<span class="esh-k">switch<\/span>/, 'switch keyword');
    like($out, qr/<span class="esh-k">case<\/span>/,   'case keyword');
    like($out, qr/<span class="esh-k">break<\/span>/,  'break keyword');
}

{
    my $out = hl('try { foo(); } catch (Exception $e) { } finally { }');
    like($out, qr/<span class="esh-k">try<\/span>/,     'try keyword');
    like($out, qr/<span class="esh-k">catch<\/span>/,   'catch keyword');
    like($out, qr/<span class="esh-k">finally<\/span>/, 'finally keyword');
}

{
    my $out = hl('use Namespace\\Class; namespace App;');
    like($out, qr/<span class="esh-k">use<\/span>/,       'use keyword');
    like($out, qr/<span class="esh-k">namespace<\/span>/, 'namespace keyword');
}

{
    my $out = hl('echo "hello"; print "world";');
    like($out, qr/<span class="esh-k">echo<\/span>/,  'echo keyword');
    like($out, qr/<span class="esh-k">print<\/span>/, 'print keyword');
}

{
    my $out = hl('public static final $x = 1;');
    like($out, qr/<span class="esh-k">public<\/span>/,  'public keyword');
    like($out, qr/<span class="esh-k">static<\/span>/, 'static keyword');
    like($out, qr/<span class="esh-k">final<\/span>/,  'final keyword');
}

{
    my $out = hl('$x instanceof Foo');
    like($out, qr/<span class="esh-k">instanceof<\/span>/, 'instanceof keyword');
}

{
    my $out = hl('isset($x); empty($y); unset($z);');
    like($out, qr/<span class="esh-k">isset<\/span>/,  'isset keyword');
    like($out, qr/<span class="esh-k">empty<\/span>/,  'empty keyword');
    like($out, qr/<span class="esh-k">unset<\/span>/,  'unset keyword');
}

{
    my $out = hl('readonly public string $name;');
    like($out, qr/<span class="esh-k">readonly<\/span>/, 'readonly keyword');
}

{
    my $out = hl('$f = fn($x) => $x * 2;');
    like($out, qr/<span class="esh-k">fn<\/span>/, 'fn (arrow fn) keyword');
}

# ── more builtins ─────────────────────────────────────────────────

{
    my $out = hl('$parts = explode(",", $str); $str2 = implode("-", $arr);');
    like($out, qr/<span class="esh-b">explode<\/span>/, 'explode builtin');
    like($out, qr/<span class="esh-b">implode<\/span>/, 'implode builtin');
}

{
    my $out = hl('$len = strlen($s); $up = strtoupper($s);');
    like($out, qr/<span class="esh-b">strlen<\/span>/,     'strlen builtin');
    like($out, qr/<span class="esh-b">strtoupper<\/span>/, 'strtoupper builtin');
}

{
    my $out = hl('$json = json_encode($data); $data = json_decode($json);');
    like($out, qr/<span class="esh-b">json_encode<\/span>/, 'json_encode builtin');
    like($out, qr/<span class="esh-b">json_decode<\/span>/, 'json_decode builtin');
}

{
    my $out = hl('$safe = htmlspecialchars($html);');
    like($out, qr/<span class="esh-b">htmlspecialchars<\/span>/, 'htmlspecialchars builtin');
}

{
    my $out = hl('$merged = array_merge($a, $b); $keys = array_keys($arr);');
    like($out, qr/<span class="esh-b">array_merge<\/span>/, 'array_merge builtin');
    like($out, qr/<span class="esh-b">array_keys<\/span>/,  'array_keys builtin');
}

{
    my $out = hl('$mapped = array_map(fn($x) => $x * 2, $arr);');
    like($out, qr/<span class="esh-b">array_map<\/span>/, 'array_map builtin');
}

{
    my $out = hl('var_dump($x); print_r($arr);');
    like($out, qr/<span class="esh-b">var_dump<\/span>/,  'var_dump builtin');
    like($out, qr/<span class="esh-b">print_r<\/span>/,   'print_r builtin');
}

# ── partial keyword non-match ─────────────────────────────────────

{
    my $out = hl('$namespace_prefix = "foo";');
    unlike($out, qr/<span class="esh-k">namespace<\/span>/, 'namespace not matched inside $namespace_prefix');
}

done_testing;
