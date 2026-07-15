use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_sql($_[0]) }

# ── keywords (uppercase) ──────────────────────────────────────────

{
    my $out = hl('SELECT col FROM t');
    like($out, qr/<span class="esh-k">SELECT<\/span>/, 'SELECT keyword');
    like($out, qr/<span class="esh-k">FROM<\/span>/,   'FROM keyword');
}

{
    my $out = hl('WHERE x = 1 AND y = 2');
    like($out, qr/<span class="esh-k">WHERE<\/span>/, 'WHERE keyword');
    like($out, qr/<span class="esh-k">AND<\/span>/,   'AND keyword');
}

{
    my $out = hl('INSERT INTO foo VALUES (1)');
    like($out, qr/<span class="esh-k">INSERT<\/span>/, 'INSERT keyword');
    like($out, qr/<span class="esh-k">INTO<\/span>/,   'INTO keyword');
    like($out, qr/<span class="esh-k">VALUES<\/span>/, 'VALUES keyword');
}

{
    my $out = hl('CREATE TABLE foo (id INT PRIMARY KEY)');
    like($out, qr/<span class="esh-k">CREATE<\/span>/,  'CREATE keyword');
    like($out, qr/<span class="esh-k">TABLE<\/span>/,   'TABLE keyword');
    like($out, qr/<span class="esh-k">PRIMARY<\/span>/, 'PRIMARY keyword');
    like($out, qr/<span class="esh-k">KEY<\/span>/,     'KEY keyword');
}

{
    my $out = hl('BEGIN END');
    like($out, qr/<span class="esh-k">BEGIN<\/span>/, 'BEGIN keyword');
    like($out, qr/<span class="esh-k">END<\/span>/,   'END keyword');
}

# ── keywords (lowercase) — case-insensitive ───────────────────────

{
    my $out = hl('select col from t where x = 1');
    like($out, qr/<span class="esh-k">select<\/span>/, 'select lower keyword');
    like($out, qr/<span class="esh-k">from<\/span>/,   'from lower keyword');
    like($out, qr/<span class="esh-k">where<\/span>/,  'where lower keyword');
}

{
    my $out = hl('Select Col From T');
    like($out, qr/<span class="esh-k">Select<\/span>/, 'Select mixed-case keyword');
}

# ── builtin functions ─────────────────────────────────────────────

{
    my $out = hl('SELECT COUNT(*), SUM(val) FROM t');
    like($out, qr/<span class="esh-b">COUNT<\/span>/, 'COUNT builtin');
    like($out, qr/<span class="esh-b">SUM<\/span>/,   'SUM builtin');
}

{
    my $out = hl('SELECT UPPER(name), LOWER(code) FROM t');
    like($out, qr/<span class="esh-b">UPPER<\/span>/, 'UPPER builtin');
    like($out, qr/<span class="esh-b">LOWER<\/span>/, 'LOWER builtin');
}

{
    my $out = hl('SELECT NOW(), CURRENT_DATE FROM t');
    like($out, qr/<span class="esh-b">NOW<\/span>/,          'NOW builtin');
    like($out, qr/<span class="esh-b">CURRENT_DATE<\/span>/, 'CURRENT_DATE builtin');
}

# ── strings ──────────────────────────────────────────────────────

{
    my $out = hl("WHERE name = 'hello'");
    like($out, qr/<span class="esh-s">'hello'<\/span>/, 'single-quoted string');
}

{
    my $out = hl("WHERE s = 'it''s'");
    like($out, qr/<span class="esh-s">'it''s'<\/span>/, "'' escaped quote in string");
}

# ── quoted identifiers ────────────────────────────────────────────

{
    my $out = hl('SELECT "my col" FROM t');
    like($out, qr/<span class="esh-a">&quot;my col&quot;<\/span>/, 'double-quoted identifier');
}

{
    my $out = hl('SELECT `my col` FROM t');
    like($out, qr/<span class="esh-a">`my col`<\/span>/, 'backtick identifier');
}

{
    my $out = hl('SELECT [my col] FROM t');
    like($out, qr/<span class="esh-a">\[my col\]<\/span>/, 'bracket identifier');
}

# ── comments ─────────────────────────────────────────────────────

{
    my $out = hl('-- line comment');
    like($out, qr/<span class="esh-c">-- line comment<\/span>/, '-- comment');
}

{
    my $out = hl('/* block comment */');
    like($out, qr/<span class="esh-c">\/\* block comment \*\/<\/span>/, '/* */ comment');
}

# ── numbers ──────────────────────────────────────────────────────

{
    my $out = hl('WHERE id = 42');
    like($out, qr/<span class="esh-n">42<\/span>/, 'integer number');
}

{
    my $out = hl('WHERE val > 3.14');
    like($out, qr/<span class="esh-n">3\.14<\/span>/, 'float number');
}

# ── HTML safety ──────────────────────────────────────────────────

{
    my $out = hl('WHERE a < b');
    like($out, qr/&lt;/, 'less-than HTML-escaped');
}

# ── partial keyword non-match ─────────────────────────────────────

{
    my $out = hl('selected');
    unlike($out, qr/<span class="esh-k">select<\/span>/i, 'SELECT not matched inside selected');
}


# ── UPDATE / SET / DELETE ─────────────────────────────────────────

{
    my $out = hl('UPDATE foo SET x = 1 WHERE id = 2');
    like($out, qr/<span class="esh-k">UPDATE<\/span>/, 'UPDATE keyword');
    like($out, qr/<span class="esh-k">SET<\/span>/,    'SET keyword');
}

{
    my $out = hl('DELETE FROM foo WHERE id = 1');
    like($out, qr/<span class="esh-k">DELETE<\/span>/, 'DELETE keyword');
}

# ── JOINs ────────────────────────────────────────────────────────

{
    my $out = hl('SELECT * FROM a JOIN b ON a.id = b.id');
    like($out, qr/<span class="esh-k">JOIN<\/span>/, 'JOIN keyword');
}

{
    my $out = hl('SELECT * FROM a LEFT JOIN b ON a.id = b.id');
    like($out, qr/<span class="esh-k">LEFT<\/span>/, 'LEFT keyword');
}

{
    my $out = hl('SELECT * FROM a INNER JOIN b ON a.x = b.x');
    like($out, qr/<span class="esh-k">INNER<\/span>/, 'INNER keyword');
}

# ── GROUP BY / ORDER BY / HAVING ──────────────────────────────────

{
    my $out = hl('SELECT dept, COUNT(*) FROM emp GROUP BY dept');
    like($out, qr/<span class="esh-k">GROUP<\/span>/, 'GROUP keyword');
    like($out, qr/<span class="esh-k">BY<\/span>/,    'BY keyword');
}

{
    my $out = hl('SELECT * FROM t ORDER BY name DESC');
    like($out, qr/<span class="esh-k">ORDER<\/span>/, 'ORDER keyword');
}

{
    my $out = hl('SELECT dept FROM emp GROUP BY dept HAVING COUNT(*) > 1');
    like($out, qr/<span class="esh-k">HAVING<\/span>/, 'HAVING keyword');
}

# ── UNION ─────────────────────────────────────────────────────────

{
    my $out = hl('SELECT a FROM t1 UNION ALL SELECT b FROM t2');
    like($out, qr/<span class="esh-k">UNION<\/span>/, 'UNION keyword');
    like($out, qr/<span class="esh-k">ALL<\/span>/,   'ALL keyword');
}

# ── CASE / WHEN / THEN / ELSE ─────────────────────────────────────

{
    my $out = hl('SELECT CASE WHEN x = 1 THEN \'a\' ELSE \'b\' END FROM t');
    like($out, qr/<span class="esh-k">CASE<\/span>/, 'CASE keyword');
    like($out, qr/<span class="esh-k">WHEN<\/span>/, 'WHEN keyword');
    like($out, qr/<span class="esh-k">THEN<\/span>/, 'THEN keyword');
    like($out, qr/<span class="esh-k">ELSE<\/span>/, 'ELSE keyword');
}

# ── window functions / OVER / PARTITION ───────────────────────────

{
    my $out = hl('SELECT ROW_NUMBER() OVER (PARTITION BY dept ORDER BY sal) FROM emp');
    like($out, qr/<span class="esh-b">ROW_NUMBER<\/span>/, 'ROW_NUMBER builtin');
    like($out, qr/<span class="esh-b">OVER<\/span>/,      'OVER builtin');
    like($out, qr/<span class="esh-b">PARTITION<\/span>/, 'PARTITION builtin');
}

{
    my $out = hl('SELECT RANK() OVER (ORDER BY sal DESC) FROM emp');
    like($out, qr/<span class="esh-b">RANK<\/span>/, 'RANK builtin');
}

{
    my $out = hl('SELECT DENSE_RANK() OVER () FROM t');
    like($out, qr/<span class="esh-b">DENSE_RANK<\/span>/, 'DENSE_RANK builtin');
}

# ── more aggregate builtins ───────────────────────────────────────

{
    my $out = hl('SELECT AVG(sal), MAX(sal), MIN(sal) FROM emp');
    like($out, qr/<span class="esh-b">AVG<\/span>/, 'AVG builtin');
    like($out, qr/<span class="esh-b">MAX<\/span>/, 'MAX builtin');
    like($out, qr/<span class="esh-b">MIN<\/span>/, 'MIN builtin');
}

# ── COALESCE / CAST / NULLIF ──────────────────────────────────────

{
    my $out = hl('SELECT COALESCE(x, 0) FROM t');
    like($out, qr/<span class="esh-k">COALESCE<\/span>/, 'COALESCE keyword');
}

{
    my $out = hl('SELECT CAST(x AS INTEGER) FROM t');
    like($out, qr/<span class="esh-k">CAST<\/span>/, 'CAST keyword');
}

{
    my $out = hl('SELECT NULLIF(x, 0) FROM t');
    like($out, qr/<span class="esh-k">NULLIF<\/span>/, 'NULLIF keyword');
}

# ── WITH (CTE) ────────────────────────────────────────────────────

{
    my $out = hl('WITH cte AS (SELECT 1) SELECT * FROM cte');
    like($out, qr/<span class="esh-k">WITH<\/span>/, 'WITH keyword');
}

# ── lowercase SQL is case-insensitive ─────────────────────────────

{
    my $out = hl('update foo set x = 1 where id = 2');
    like($out, qr/<span class="esh-k">update<\/span>/, 'update lower keyword');
    like($out, qr/<span class="esh-k">set<\/span>/,    'set lower keyword');
}

{
    my $out = hl('delete from foo where id = 1');
    like($out, qr/<span class="esh-k">delete<\/span>/, 'delete lower keyword');
}

{
    my $out = hl('select avg(x) from t group by dept having avg(x) > 100');
    like($out, qr/<span class="esh-b">avg<\/span>/, 'avg lower builtin');
}

done_testing;
