use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_ruby($_[0]) }

# ── keywords ─────────────────────────────────────────────────────

{
    my $out = hl('def foo; end');
    like($out, qr/<span class="esh-k">def<\/span>/, 'def keyword');
    like($out, qr/<span class="esh-k">end<\/span>/, 'end keyword');
}

{
    my $out = hl('class Foo < Bar; end');
    like($out, qr/<span class="esh-k">class<\/span>/, 'class keyword');
    like($out, qr/<span class="esh-k">end<\/span>/,   'end keyword');
}

{
    my $out = hl('if x then y elsif z else w end');
    like($out, qr/<span class="esh-k">if<\/span>/,     'if keyword');
    like($out, qr/<span class="esh-k">then<\/span>/,   'then keyword');
    like($out, qr/<span class="esh-k">elsif<\/span>/,  'elsif keyword');
    like($out, qr/<span class="esh-k">else<\/span>/,   'else keyword');
}

{
    my $out = hl('begin; rescue => e; ensure; end');
    like($out, qr/<span class="esh-k">begin<\/span>/,   'begin keyword');
    like($out, qr/<span class="esh-k">rescue<\/span>/,  'rescue keyword');
    like($out, qr/<span class="esh-k">ensure<\/span>/,  'ensure keyword');
}

{
    my $out = hl('return nil unless true');
    like($out, qr/<span class="esh-k">return<\/span>/,  'return keyword');
    like($out, qr/<span class="esh-k">nil<\/span>/,     'nil keyword');
    like($out, qr/<span class="esh-k">unless<\/span>/,  'unless keyword');
    like($out, qr/<span class="esh-k">true<\/span>/,    'true keyword');
}

# ── builtins ─────────────────────────────────────────────────────

{
    my $out = hl('puts "hello"');
    like($out, qr/<span class="esh-b">puts<\/span>/, 'puts builtin');
}

{
    my $out = hl('require "json"');
    like($out, qr/<span class="esh-b">require<\/span>/, 'require builtin');
}

{
    my $out = hl('raise ArgumentError, "bad"');
    like($out, qr/<span class="esh-b">raise<\/span>/, 'raise builtin');
}

{
    my $out = hl('attr_accessor :name');
    like($out, qr/<span class="esh-b">attr_accessor<\/span>/, 'attr_accessor builtin');
}

# ── strings ──────────────────────────────────────────────────────

{
    my $out = hl('"hello world"');
    like($out, qr/<span class="esh-s">&quot;hello world&quot;<\/span>/, 'double-quoted string');
}

{
    my $out = hl("'single'");
    like($out, qr/<span class="esh-s">'single'<\/span>/, 'single-quoted string');
}

# ── symbols ──────────────────────────────────────────────────────

{
    my $out = hl(':foo');
    like($out, qr/<span class="esh-r">:foo<\/span>/, 'simple symbol');
}

{
    my $out = hl(':"quoted sym"');
    like($out, qr/<span class="esh-r">:&quot;quoted sym&quot;<\/span>/, 'quoted symbol');
}

# ── variables ────────────────────────────────────────────────────

{
    my $out = hl('$global = 1');
    like($out, qr/<span class="esh-v">\$global<\/span>/, '$global');
}

{
    my $out = hl('@ivar = 2');
    like($out, qr/<span class="esh-v">\@ivar<\/span>/, '@ivar');
}

{
    my $out = hl('@@cvar = 3');
    like($out, qr/<span class="esh-v">\@\@cvar<\/span>/, '@@cvar');
}

# ── numbers ──────────────────────────────────────────────────────

{
    my $out = hl('42');
    like($out, qr/<span class="esh-n">42<\/span>/, 'integer');
}

{
    my $out = hl('3.14');
    like($out, qr/<span class="esh-n">3\.14<\/span>/, 'float');
}

{
    my $out = hl('0xFF');
    like($out, qr/<span class="esh-n">0xFF<\/span>/, 'hex');
}

{
    my $out = hl('0b1010');
    like($out, qr/<span class="esh-n">0b1010<\/span>/, 'binary');
}

# ── comments ─────────────────────────────────────────────────────

{
    my $out = hl('# a comment');
    like($out, qr/<span class="esh-c"># a comment<\/span>/, '# comment');
}

# ── HTML safety ──────────────────────────────────────────────────

{
    my $out = hl('x < y');
    like($out, qr/&lt;/, 'less-than HTML-escaped');
}

{
    my $out = hl('puts "<b>bold</b>"');
    like($out, qr/&lt;b&gt;bold&lt;\/b&gt;/, 'HTML tags in string escaped');
}

# ── partial keyword non-match ─────────────────────────────────────

{
    my $out = hl('endpoint = 1');
    unlike($out, qr/<span class="esh-k">end<\/span>/, 'end inside identifier not highlighted');
}

{
    my $out = hl('defined?(foo)');
    like($out, qr/<span class="esh-k">defined\?<\/span>/, 'defined? with ? suffix');
}


# ── more keywords ─────────────────────────────────────────────────

{
    my $out = hl('module Foo; end');
    like($out, qr/<span class="esh-k">module<\/span>/, 'module keyword');
}

{
    my $out = hl('while x do y end');
    like($out, qr/<span class="esh-k">while<\/span>/, 'while keyword');
    like($out, qr/<span class="esh-k">do<\/span>/,    'do keyword');
}

{
    my $out = hl('until x; end');
    like($out, qr/<span class="esh-k">until<\/span>/, 'until keyword');
}

{
    my $out = hl('for i in 1..10; end');
    like($out, qr/<span class="esh-k">for<\/span>/, 'for keyword');
    like($out, qr/<span class="esh-k">in<\/span>/,  'in keyword');
}

{
    my $out = hl('case x when 1 then :a when 2 then :b end');
    like($out, qr/<span class="esh-k">case<\/span>/,  'case keyword');
    like($out, qr/<span class="esh-k">when<\/span>/,  'when keyword');
}

{
    my $out = hl('def gen; yield; end');
    like($out, qr/<span class="esh-k">yield<\/span>/, 'yield keyword');
}

{
    my $out = hl('x = true and false or not nil');
    like($out, qr/<span class="esh-k">and<\/span>/,   'and keyword');
    like($out, qr/<span class="esh-k">or<\/span>/,    'or keyword');
    like($out, qr/<span class="esh-k">not<\/span>/,   'not keyword');
    like($out, qr/<span class="esh-k">false<\/span>/, 'false keyword');
}

{
    my $out = hl('while x; next; break; redo; end');
    like($out, qr/<span class="esh-k">next<\/span>/,  'next keyword');
    like($out, qr/<span class="esh-k">break<\/span>/, 'break keyword');
    like($out, qr/<span class="esh-k">redo<\/span>/,  'redo keyword');
}

{
    my $out = hl('self.foo; super');
    like($out, qr/<span class="esh-k">self<\/span>/,  'self keyword');
    like($out, qr/<span class="esh-k">super<\/span>/, 'super keyword');
}

{
    my $out = hl('__FILE__ __LINE__ __method__');
    like($out, qr/<span class="esh-k">__FILE__<\/span>/,   '__FILE__ keyword');
    like($out, qr/<span class="esh-k">__LINE__<\/span>/,   '__LINE__ keyword');
    like($out, qr/<span class="esh-k">__method__<\/span>/, '__method__ keyword');
}

# ── more builtins ─────────────────────────────────────────────────

{
    my $out = hl('p x; pp y; warn "msg"');
    like($out, qr/<span class="esh-b">p<\/span>/,    'p builtin');
    like($out, qr/<span class="esh-b">pp<\/span>/,   'pp builtin');
    like($out, qr/<span class="esh-b">warn<\/span>/, 'warn builtin');
}

{
    my $out = hl('include Comparable; extend ClassMethods; prepend M');
    like($out, qr/<span class="esh-b">include<\/span>/,  'include builtin');
    like($out, qr/<span class="esh-b">extend<\/span>/,   'extend builtin');
    like($out, qr/<span class="esh-b">prepend<\/span>/,  'prepend builtin');
}

{
    my $out = hl('private :foo; protected :bar; public :baz');
    like($out, qr/<span class="esh-b">private<\/span>/,   'private builtin');
    like($out, qr/<span class="esh-b">protected<\/span>/, 'protected builtin');
    like($out, qr/<span class="esh-b">public<\/span>/,    'public builtin');
}

{
    my $out = hl('attr_reader :name; attr_writer :age');
    like($out, qr/<span class="esh-b">attr_reader<\/span>/, 'attr_reader builtin');
    like($out, qr/<span class="esh-b">attr_writer<\/span>/, 'attr_writer builtin');
}

{
    my $out = hl('lambda { |x| x }; proc { |x| x }');
    like($out, qr/<span class="esh-b">lambda<\/span>/, 'lambda builtin');
    like($out, qr/<span class="esh-b">proc<\/span>/,   'proc builtin');
}

{
    my $out = hl('require_relative "foo"');
    like($out, qr/<span class="esh-b">require_relative<\/span>/, 'require_relative builtin');
}

# ── more variables ────────────────────────────────────────────────

{
    my $out = hl('$0');
    like($out, qr/<span class="esh-v">\$0<\/span>/, '$0 global');
}

{
    my $out = hl('$PROGRAM_NAME');
    like($out, qr/<span class="esh-v">\$PROGRAM_NAME<\/span>/, '$PROGRAM_NAME global');
}

# ── undef keyword ─────────────────────────────────────────────────

{
    my $out = hl('undef foo');
    like($out, qr/<span class="esh-k">undef<\/span>/, 'undef keyword');
}

# ── retry keyword ─────────────────────────────────────────────────

{
    my $out = hl('rescue => e; retry; end');
    like($out, qr/<span class="esh-k">retry<\/span>/, 'retry keyword');
}

# ── partial keyword non-match ─────────────────────────────────────

{
    my $out = hl('module_function');
    unlike($out, qr/<span class="esh-k">module<\/span>/, 'module not matched inside module_function');
}

{
    my $out = hl('include_all');
    unlike($out, qr/<span class="esh-b">include<\/span>/, 'include not matched inside include_all');
}

done_testing;
