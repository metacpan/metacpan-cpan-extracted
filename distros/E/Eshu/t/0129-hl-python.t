use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_string($_[0], lang => 'python') }

# ── keywords ─────────────────────────────────────────────────────

{
    my $out = hl('def foo(): pass');
    like($out, qr{<span class="esh-k">def</span>},  'def is a keyword');
    like($out, qr{<span class="esh-k">pass</span>}, 'pass is a keyword');
}

{
    my $out = hl('for x in range(10): continue');
    like($out, qr{<span class="esh-k">for</span>},      'for is a keyword');
    like($out, qr{<span class="esh-k">in</span>},       'in is a keyword');
    like($out, qr{<span class="esh-k">continue</span>}, 'continue is a keyword');
}

{
    my $out = hl('if x: return True else: return False');
    like($out, qr{<span class="esh-k">if</span>},    'if is a keyword');
    like($out, qr{<span class="esh-k">return</span>},'return is a keyword');
    like($out, qr{<span class="esh-k">True</span>},  'True is a keyword');
    like($out, qr{<span class="esh-k">else</span>},  'else is a keyword');
    like($out, qr{<span class="esh-k">False</span>}, 'False is a keyword');
}

{
    my $out = hl('import os from sys import path');
    like($out, qr{<span class="esh-k">import</span>}, 'import is a keyword');
    like($out, qr{<span class="esh-k">from</span>},   'from is a keyword');
}

{
    my $out = hl('try: pass except ValueError: pass finally: pass');
    like($out, qr{<span class="esh-k">try</span>},     'try is a keyword');
    like($out, qr{<span class="esh-k">except</span>},  'except is a keyword');
    like($out, qr{<span class="esh-k">finally</span>}, 'finally is a keyword');
}

{
    my $out = hl('while True: break');
    like($out, qr{<span class="esh-k">while</span>}, 'while is a keyword');
    like($out, qr{<span class="esh-k">break</span>}, 'break is a keyword');
}

{
    my $out = hl('async def f(): await g()');
    like($out, qr{<span class="esh-k">async</span>}, 'async is a keyword');
    like($out, qr{<span class="esh-k">await</span>}, 'await is a keyword');
}

{
    my $out = hl('lambda x: x * 2');
    like($out, qr{<span class="esh-k">lambda</span>}, 'lambda is a keyword');
}

# ── builtins ─────────────────────────────────────────────────────

{
    my $out = hl('print(len(items))');
    like($out, qr{<span class="esh-b">print</span>}, 'print is a builtin');
    like($out, qr{<span class="esh-b">len</span>},   'len is a builtin');
}

{
    my $out = hl('x = int(s)');
    like($out, qr{<span class="esh-b">int</span>}, 'int is a builtin');
}

{
    my $out = hl('r = range(10)');
    like($out, qr{<span class="esh-b">range</span>}, 'range is a builtin');
}

{
    my $out = hl('t = type(x)');
    like($out, qr{<span class="esh-b">type</span>}, 'type is a builtin');
}

{
    my $out = hl('isinstance(x, int) and issubclass(C, B)');
    like($out, qr{<span class="esh-b">isinstance</span>},  'isinstance is a builtin');
    like($out, qr{<span class="esh-b">issubclass</span>},  'issubclass is a builtin');
}

# ── non-keyword identifiers are not wrapped ───────────────────────

{
    my $out = hl('foo bar_baz MyClass');
    unlike($out, qr{esh-k.*foo},    'foo is not a keyword');
    unlike($out, qr{esh-b.*MyClass},'MyClass is not a builtin');
}

# ── partial keyword in identifier not matched ─────────────────────

{
    my $out = hl('define format_value returns');
    unlike($out, qr{<span class="esh-k">def</span>},    'def not matched in define');
    unlike($out, qr{<span class="esh-k">return</span>}, 'return not matched in returns');
    # format_value: format *is* a builtin — check it's NOT matched inside format_value
    unlike($out, qr{<span class="esh-b">format</span>}, 'format not matched in format_value');
}

# ── strings ───────────────────────────────────────────────────────

{
    my $out = hl(q("hello world"));
    like($out, qr{<span class="esh-s">&quot;hello world&quot;</span>},
         'double-quoted string wrapped as esh-s');
}

{
    my $out = hl(q('hello'));
    like($out, qr{<span class="esh-s">'hello'</span>},
         'single-quoted string wrapped as esh-s');
}

{
    my $out = hl('x = "don\'t stop"');
    like($out, qr{esh-s}, 'string with escaped quote still tagged esh-s');
}

# ── triple-quoted strings ────────────────────────────────────────

{
    my $out = hl('x = """hello\nworld"""');
    like($out, qr{<span class="esh-s">&quot;&quot;&quot;hello\\nworld&quot;&quot;&quot;</span>},
         'triple-double-quoted string wrapped as esh-s');
}

{
    my $out = hl("x = '''line1\nline2'''");
    like($out, qr{esh-s}, 'triple-single-quoted string wrapped as esh-s');
}

# ── f-strings as esh-r ────────────────────────────────────────────

{
    my $out = hl('f"hello {name}"');
    like($out, qr{<span class="esh-r">f&quot;hello \{name\}&quot;</span>}
             || qr{esh-r.*f&quot;},
         'f-string tagged as esh-r');
}

{
    my $out = hl("f'value: {x}'");
    like($out, qr{esh-r}, "f-string single-quote tagged as esh-r");
}

# ── b-strings and r-strings as esh-s ─────────────────────────────

{
    my $out = hl('b"bytes"');
    like($out, qr{esh-s}, 'b-string tagged as esh-s');
}

{
    my $out = hl('r"\d+"');
    like($out, qr{esh-s}, 'r-string tagged as esh-s');
}

# ── comments ─────────────────────────────────────────────────────

{
    my $out = hl('x = 1  # inline comment');
    like($out, qr{<span class="esh-c"># inline comment</span>},
         'inline comment wrapped as esh-c');
}

{
    my $out = hl('# full line comment');
    like($out, qr{<span class="esh-c"># full line comment</span>},
         'full-line comment wrapped as esh-c');
}

# ── numbers ───────────────────────────────────────────────────────

{
    my $out = hl('x = 42');
    like($out, qr{<span class="esh-n">42</span>}, 'integer literal as esh-n');
}

{
    my $out = hl('x = 3.14');
    like($out, qr{<span class="esh-n">3\.14</span>}, 'float literal as esh-n');
}

{
    my $out = hl('x = 0xFF');
    like($out, qr{<span class="esh-n">0xFF</span>}, 'hex literal as esh-n');
}

{
    my $out = hl('x = 0b1010');
    like($out, qr{<span class="esh-n">0b1010</span>}, 'binary literal as esh-n');
}

{
    my $out = hl('x = 0o17');
    like($out, qr{<span class="esh-n">0o17</span>}, 'octal literal as esh-n');
}

{
    my $out = hl('x = 1.5e10');
    like($out, qr{<span class="esh-n">1\.5e10</span>}, 'scientific notation as esh-n');
}

{
    my $out = hl('z = 3j');
    like($out, qr{<span class="esh-n">3j</span>}, 'complex literal as esh-n');
}

# ── decorator ─────────────────────────────────────────────────────

{
    my $out = hl("\@staticmethod\ndef f(): pass");
    like($out, qr{<span class="esh-p">\@staticmethod</span>},
         'decorator wrapped as esh-p');
}

{
    my $out = hl("\@app.route('/home')\ndef view(): pass");
    like($out, qr{<span class="esh-p">\@app\.route</span>},
         'dotted decorator wrapped as esh-p');
}

# ── HTML safety ───────────────────────────────────────────────────

{
    my $out = hl('x = a < b and b > c');
    like($out, qr{&lt;}, 'less-than is HTML-escaped');
    like($out, qr{&gt;}, 'greater-than is HTML-escaped');
}

{
    my $out = hl('x = "a & b"');
    like($out, qr{&amp;}, 'ampersand in string is HTML-escaped');
}

# ── lang aliases ─────────────────────────────────────────────────

{
    my $out1 = hl('def f(): pass');
    my $out2 = Eshu->highlight_string('def f(): pass', lang => 'py');
    is($out1, $out2, '"py" alias gives same output as "python"');
}


# ── more keywords ─────────────────────────────────────────────────

{
    my $out = hl('class Foo(Bar): pass');
    like($out, qr{<span class="esh-k">class</span>}, 'class is a keyword');
}

{
    my $out = hl('with open(f) as fh: pass');
    like($out, qr{<span class="esh-k">with</span>}, 'with is a keyword');
    like($out, qr{<span class="esh-k">as</span>},   'as is a keyword');
}

{
    my $out = hl('raise ValueError("bad")');
    like($out, qr{<span class="esh-k">raise</span>}, 'raise is a keyword');
}

{
    my $out = hl('del items[0]');
    like($out, qr{<span class="esh-k">del</span>}, 'del is a keyword');
}

{
    my $out = hl('global x; nonlocal y');
    like($out, qr{<span class="esh-k">global</span>},   'global is a keyword');
    like($out, qr{<span class="esh-k">nonlocal</span>}, 'nonlocal is a keyword');
}

{
    my $out = hl('def gen(): yield 1');
    like($out, qr{<span class="esh-k">yield</span>}, 'yield is a keyword');
}

{
    my $out = hl('assert x > 0, "must be positive"');
    like($out, qr{<span class="esh-k">assert</span>}, 'assert is a keyword');
}

{
    my $out = hl('x = not True and False or None');
    like($out, qr{<span class="esh-k">not</span>},  'not is a keyword');
    like($out, qr{<span class="esh-k">and</span>},  'and is a keyword');
    like($out, qr{<span class="esh-k">or</span>},   'or is a keyword');
    like($out, qr{<span class="esh-k">None</span>}, 'None is a keyword');
}

{
    my $out = hl('if x is None: pass');
    like($out, qr{<span class="esh-k">is</span>}, 'is is a keyword');
}

{
    my $out = hl('if x is not None: pass');
    like($out, qr{<span class="esh-k">not</span>}, 'not in is-not expression is keyword');
}

{
    my $out = hl('if x not in items: pass');
    like($out, qr{<span class="esh-k">not</span>}, 'not in not-in expression is keyword');
    like($out, qr{<span class="esh-k">in</span>},  'in in not-in expression is keyword');
}

# ── more builtins ─────────────────────────────────────────────────

{
    my $out = hl('x = list(t)');
    like($out, qr{<span class="esh-b">list</span>}, 'list is a builtin');
}

{
    my $out = hl('x = dict(a=1)');
    like($out, qr{<span class="esh-b">dict</span>}, 'dict is a builtin');
}

{
    my $out = hl('x = tuple(items)');
    like($out, qr{<span class="esh-b">tuple</span>}, 'tuple is a builtin');
}

{
    my $out = hl('x = set(items)');
    like($out, qr{<span class="esh-b">set</span>}, 'set is a builtin');
}

{
    my $out = hl('for i, v in enumerate(items): pass');
    like($out, qr{<span class="esh-b">enumerate</span>}, 'enumerate is a builtin');
}

{
    my $out = hl('r = sorted(items, reverse=True)');
    like($out, qr{<span class="esh-b">sorted</span>}, 'sorted is a builtin');
}

{
    my $out = hl('x = sum(items)');
    like($out, qr{<span class="esh-b">sum</span>}, 'sum is a builtin');
}

{
    my $out = hl('hi = max(a, b)');
    like($out, qr{<span class="esh-b">max</span>}, 'max is a builtin');
}

{
    my $out = hl('lo = min(a, b)');
    like($out, qr{<span class="esh-b">min</span>}, 'min is a builtin');
}

{
    my $out = hl('n = abs(-5)');
    like($out, qr{<span class="esh-b">abs</span>}, 'abs is a builtin');
}

{
    my $out = hl('ok = any(items) or all(items)');
    like($out, qr{<span class="esh-b">any</span>}, 'any is a builtin');
    like($out, qr{<span class="esh-b">all</span>}, 'all is a builtin');
}

{
    my $out = hl('s = str(x)');
    like($out, qr{<span class="esh-b">str</span>}, 'str is a builtin');
}

{
    my $out = hl('fh = open("f.txt", "r")');
    like($out, qr{<span class="esh-b">open</span>}, 'open is a builtin');
}

done_testing;
