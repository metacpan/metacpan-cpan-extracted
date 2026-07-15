use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_string($_[0], lang => 'lua') }

# keywords are wrapped in esh-k spans
like(hl('if x then'), qr/<span class="esh-k">if<\/span>/, 'if is keyword');
like(hl('if x then'), qr/<span class="esh-k">then<\/span>/, 'then is keyword');
like(hl('end'), qr/<span class="esh-k">end<\/span>/, 'end is keyword');
like(hl('while true do'), qr/<span class="esh-k">while<\/span>/, 'while is keyword');
like(hl('function f()'), qr/<span class="esh-k">function<\/span>/, 'function is keyword');
like(hl('local x = 1'), qr/<span class="esh-k">local<\/span>/, 'local is keyword');
like(hl('return nil'), qr/<span class="esh-k">return<\/span>/, 'return is keyword');
like(hl('return nil'), qr/<span class="esh-k">nil<\/span>/, 'nil is keyword');

# builtins
like(hl('print("hi")'), qr/<span class="esh-b">print<\/span>/, 'print is builtin');
like(hl('require("mod")'), qr/<span class="esh-b">require<\/span>/, 'require is builtin');
like(hl('type(x)'), qr/<span class="esh-b">type<\/span>/, 'type is builtin');
like(hl('pairs(t)'), qr/<span class="esh-b">pairs<\/span>/, 'pairs is builtin');

# strings
like(hl('"hello"'), qr/<span class="esh-s">&quot;hello&quot;<\/span>/, 'double-quoted string');
like(hl("'world'"), qr/<span class="esh-s">'world'<\/span>/, 'single-quoted string');

# comments
like(hl('-- a comment'), qr/<span class="esh-c">-- a comment<\/span>/, 'line comment');
like(hl('--[[ long ]]'), qr/<span class="esh-c">--\[\[ long \]\]<\/span>/, 'long comment');

# numbers
like(hl('42'), qr/<span class="esh-n">42<\/span>/, 'integer literal');
like(hl('3.14'), qr/<span class="esh-n">3\.14<\/span>/, 'float literal');
like(hl('0xff'), qr/<span class="esh-n">0xff<\/span>/, 'hex literal');


# ── more keywords ─────────────────────────────────────────────────

{
    my $out = hl('if x then y elseif z then w else v end');
    like($out, qr/<span class="esh-k">elseif<\/span>/, 'elseif keyword');
    like($out, qr/<span class="esh-k">else<\/span>/,   'else keyword');
}

{
    my $out = hl('goto label');
    like($out, qr/<span class="esh-k">goto<\/span>/, 'goto keyword');
}

{
    my $out = hl('repeat x until y');
    like($out, qr/<span class="esh-k">repeat<\/span>/, 'repeat keyword');
    like($out, qr/<span class="esh-k">until<\/span>/,  'until keyword');
}

{
    my $out = hl('x = true and false or not nil');
    like($out, qr/<span class="esh-k">and<\/span>/,   'and keyword');
    like($out, qr/<span class="esh-k">or<\/span>/,    'or keyword');
    like($out, qr/<span class="esh-k">not<\/span>/,   'not keyword');
    like($out, qr/<span class="esh-k">false<\/span>/, 'false keyword');
    like($out, qr/<span class="esh-k">true<\/span>/,  'true keyword');
}

{
    my $out = hl('for i = 1, 10 do end');
    like($out, qr/<span class="esh-k">for<\/span>/, 'for keyword');
    like($out, qr/<span class="esh-k">do<\/span>/,  'do keyword');
}

{
    my $out = hl('for k, v in pairs(t) do end');
    like($out, qr/<span class="esh-k">in<\/span>/, 'in keyword');
}

{
    my $out = hl('break');
    like($out, qr/<span class="esh-k">break<\/span>/, 'break keyword');
}

# ── more builtins ─────────────────────────────────────────────────

{
    my $out = hl('assert(x, "msg")');
    like($out, qr/<span class="esh-b">assert<\/span>/, 'assert builtin');
}

{
    my $out = hl('error("oops")');
    like($out, qr/<span class="esh-b">error<\/span>/, 'error builtin');
}

{
    my $out = hl('local ok, err = pcall(f)');
    like($out, qr/<span class="esh-b">pcall<\/span>/, 'pcall builtin');
}

{
    my $out = hl('xpcall(f, handler)');
    like($out, qr/<span class="esh-b">xpcall<\/span>/, 'xpcall builtin');
}

{
    my $out = hl('rawget(t, k); rawset(t, k, v)');
    like($out, qr/<span class="esh-b">rawget<\/span>/, 'rawget builtin');
    like($out, qr/<span class="esh-b">rawset<\/span>/, 'rawset builtin');
}

{
    my $out = hl('setmetatable(t, mt); getmetatable(t)');
    like($out, qr/<span class="esh-b">setmetatable<\/span>/, 'setmetatable builtin');
    like($out, qr/<span class="esh-b">getmetatable<\/span>/, 'getmetatable builtin');
}

{
    my $out = hl('tonumber("42"); tostring(42)');
    like($out, qr/<span class="esh-b">tonumber<\/span>/, 'tonumber builtin');
    like($out, qr/<span class="esh-b">tostring<\/span>/, 'tostring builtin');
}

{
    my $out = hl('coroutine.create(f)');
    like($out, qr/<span class="esh-b">coroutine<\/span>/, 'coroutine builtin');
}

{
    my $out = hl('math.floor(3.7)');
    like($out, qr/<span class="esh-b">math<\/span>/, 'math builtin');
}

{
    my $out = hl('table.insert(t, v); table.sort(t)');
    like($out, qr/<span class="esh-b">table<\/span>/, 'table builtin');
}

{
    my $out = hl('io.write("hello")');
    like($out, qr/<span class="esh-b">io<\/span>/, 'io builtin');
}

{
    my $out = hl('os.time(); os.exit(0)');
    like($out, qr/<span class="esh-b">os<\/span>/, 'os builtin');
}

{
    my $out = hl('utf8.len(s)');
    like($out, qr/<span class="esh-b">utf8<\/span>/, 'utf8 builtin');
}

# ── partial keyword non-match ─────────────────────────────────────

{
    my $out = hl('endpoint');
    unlike($out, qr/<span class="esh-k">end<\/span>/, 'end not matched inside endpoint');
}

{
    my $out = hl('dofile');
    unlike($out, qr/<span class="esh-k">do<\/span>/, 'do not matched inside dofile');
}

done_testing;
